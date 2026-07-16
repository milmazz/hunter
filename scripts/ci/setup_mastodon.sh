#!/usr/bin/env bash
# Boots a disposable Mastodon (docker-compose.ci.yml), provisions two users
# with OAuth tokens, and writes scripts/ci/.env.hunter with the env vars the
# integration suite needs. Idempotent: safe to re-run.
set -euo pipefail

cd "$(dirname "$0")/../.."
COMPOSE="docker compose -f docker-compose.ci.yml"
CI_DIR=scripts/ci
MASTODON_ENV="$CI_DIR/.env.mastodon"
HUNTER_ENV="$CI_DIR/.env.hunter"

# 1. Secrets (generated once; arbitrary values are fine for a throwaway box,
#    but VAPID keys must be a real EC pair, so those come from the rake task).
if [ ! -f "$MASTODON_ENV" ]; then
  cat > "$MASTODON_ENV" <<EOF
RAILS_ENV=production
NODE_ENV=production
LOCAL_DOMAIN=localhost
DB_HOST=db
DB_PORT=5432
DB_USER=postgres
DB_PASS=postgres
DB_NAME=mastodon_production
REDIS_HOST=redis
REDIS_PORT=6379
ES_ENABLED=false
S3_ENABLED=false
RAILS_LOG_LEVEL=warn
# The provisioned users live at @example.com, whose null MX record makes
# Mastodon's production EmailMxValidator reject them as "unreachable".
# Allowlisting the domain bypasses that DNS check for our throwaway box.
EMAIL_DOMAIN_ALLOWLIST=example.com
SECRET_KEY_BASE=$(openssl rand -hex 64)
OTP_SECRET=$(openssl rand -hex 64)
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=$(openssl rand -hex 32)
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=$(openssl rand -hex 32)
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=$(openssl rand -hex 32)
EOF
  $COMPOSE run --rm web bundle exec rake mastodon:webpush:generate_vapid_key >> "$MASTODON_ENV"
fi

# 2. Self-signed cert for the nginx TLS front.
mkdir -p "$CI_DIR/certs"
if [ ! -f "$CI_DIR/certs/localhost.crt" ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
    -keyout "$CI_DIR/certs/localhost.key" \
    -out "$CI_DIR/certs/localhost.crt" \
    -subj "/CN=localhost"
fi

# 3. Database + app boot.
$COMPOSE up -d db redis
$COMPOSE run --rm web bundle exec rails db:prepare
$COMPOSE up -d web sidekiq streaming nginx

echo "Waiting for Mastodon to answer..."
for _ in $(seq 1 60); do
  if curl -fsSk https://localhost:3000/health > /dev/null 2>&1; then
    break
  fi
  sleep 2
done
curl -fsSk https://localhost:3000/health > /dev/null

# 4. Users + OAuth tokens.
create_user() {
  # tootctl exits non-zero if the user exists; tolerate for idempotency.
  $COMPOSE exec -T web bin/tootctl accounts create "$1" \
    --email "$1@example.com" --confirmed --approve > /dev/null 2>&1 || true
}
create_user hunter
create_user kadaba

# The email travels via env var (ENV.fetch), never interpolated into Ruby.
mint_token() {
  $COMPOSE exec -T -e MINT_EMAIL="$1@example.com" web bin/rails runner "
    app = Doorkeeper::Application.find_or_create_by!(name: 'hunter-ci') do |a|
      a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
      a.scopes = 'read write follow push profile'
    end
    # profile scope added later; refresh pre-existing app/token rows in place
    app.update!(scopes: 'read write follow push profile') unless app.scopes.to_s.include?('profile')
    user = User.find_by!(email: ENV.fetch('MINT_EMAIL'))
    token = Doorkeeper::AccessToken.find_or_create_by!(
      application_id: app.id, resource_owner_id: user.id, revoked_at: nil
    ) { |t| t.scopes = app.scopes.to_s }
    token.update!(scopes: app.scopes.to_s) if token.scopes.to_s != app.scopes.to_s
    puts token.token
  " | tr -d '[:space:]'
}

TOKEN1=$(mint_token hunter)
TOKEN2=$(mint_token kadaba)

# A fresh authorization grant per provisioning run: authorization codes are
# single-use, so the oauth integration test consumes this one code per run.
OAUTH_PROVISION=$($COMPOSE exec -T web bin/rails runner "
  app = Doorkeeper::Application.find_or_create_by!(name: 'hunter-ci-oauth') do |a|
    a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
    a.scopes = 'read write'
  end
  user = User.find_by!(email: 'kadaba@example.com')
  grant = Doorkeeper::AccessGrant.create!(
    application_id: app.id, resource_owner_id: user.id,
    redirect_uri: app.redirect_uri, expires_in: 86_400, scopes: app.scopes.to_s
  )
  code = (grant.respond_to?(:plaintext_token) && grant.plaintext_token) || grant.token
  puts [app.uid, app.secret, code].join(' ')
" | tr -d '\r')
read -r OAUTH_CLIENT_ID OAUTH_CLIENT_SECRET OAUTH_CODE <<EOF2
$OAUTH_PROVISION
EOF2

# A PKCE-bound grant: the verifier is generated here, its S256 challenge
# stored on the grant, and both travel to the test suite via env vars.
PKCE_VERIFIER=$(openssl rand -base64 32 | tr '+/' '-_' | tr -d '=')
PKCE_CHALLENGE=$(printf %s "$PKCE_VERIFIER" | openssl dgst -sha256 -binary | base64 | tr '+/' '-_' | tr -d '=')

PKCE_CODE=$($COMPOSE exec -T -e PKCE_CHALLENGE="$PKCE_CHALLENGE" web bin/rails runner "
  app = Doorkeeper::Application.find_by!(name: 'hunter-ci-oauth')
  user = User.find_by!(email: 'kadaba@example.com')
  grant = Doorkeeper::AccessGrant.create!(
    application_id: app.id, resource_owner_id: user.id,
    redirect_uri: app.redirect_uri, expires_in: 86_400, scopes: app.scopes.to_s,
    code_challenge: ENV.fetch('PKCE_CHALLENGE'), code_challenge_method: 'S256'
  )
  puts (grant.respond_to?(:plaintext_token) && grant.plaintext_token) || grant.token
" | tr -d '[:space:]')

cat > "$HUNTER_ENV" <<EOF
export HUNTER_BASE_URL=https://localhost:3000
export HUNTER_TOKEN=$TOKEN1
export HUNTER_TOKEN2=$TOKEN2
export HUNTER_OAUTH_CLIENT_ID=$OAUTH_CLIENT_ID
export HUNTER_OAUTH_CLIENT_SECRET=$OAUTH_CLIENT_SECRET
export HUNTER_OAUTH_CODE=$OAUTH_CODE
export HUNTER_OAUTH_PKCE_CODE=$PKCE_CODE
export HUNTER_OAUTH_PKCE_VERIFIER=$PKCE_VERIFIER
EOF

if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "HUNTER_BASE_URL=https://localhost:3000"
    echo "HUNTER_TOKEN=$TOKEN1"
    echo "HUNTER_TOKEN2=$TOKEN2"
    echo "HUNTER_OAUTH_CLIENT_ID=$OAUTH_CLIENT_ID"
    echo "HUNTER_OAUTH_CLIENT_SECRET=$OAUTH_CLIENT_SECRET"
    echo "HUNTER_OAUTH_CODE=$OAUTH_CODE"
    echo "HUNTER_OAUTH_PKCE_CODE=$PKCE_CODE"
    echo "HUNTER_OAUTH_PKCE_VERIFIER=$PKCE_VERIFIER"
  } >> "$GITHUB_ENV"
fi

echo "Mastodon ready at https://localhost:3000 (users: hunter, kadaba)"
echo "Run: source $HUNTER_ENV && mix test --only integration"
