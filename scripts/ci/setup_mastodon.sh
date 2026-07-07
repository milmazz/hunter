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
$COMPOSE up -d web sidekiq nginx

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

mint_token() {
  $COMPOSE exec -T web bin/rails runner "
    app = Doorkeeper::Application.find_or_create_by!(name: 'hunter-ci') do |a|
      a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
      a.scopes = 'read write follow'
    end
    user = User.find_by!(email: '$1@example.com')
    token = Doorkeeper::AccessToken.find_or_create_by!(
      application_id: app.id, resource_owner_id: user.id, revoked_at: nil
    ) { |t| t.scopes = app.scopes.to_s }
    puts token.token
  " | tr -d '[:space:]'
}

TOKEN1=$(mint_token hunter)
TOKEN2=$(mint_token kadaba)

PASSWORD2=$($COMPOSE exec -T web bin/tootctl accounts modify kadaba --reset-password \
  | awk '/New password:/ {print $3}')

cat > "$HUNTER_ENV" <<EOF
export HUNTER_BASE_URL=https://localhost:3000
export HUNTER_TOKEN=$TOKEN1
export HUNTER_TOKEN2=$TOKEN2
export HUNTER_PASSWORD2=$PASSWORD2
EOF

if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "HUNTER_BASE_URL=https://localhost:3000"
    echo "HUNTER_TOKEN=$TOKEN1"
    echo "HUNTER_TOKEN2=$TOKEN2"
    echo "HUNTER_PASSWORD2=$PASSWORD2"
  } >> "$GITHUB_ENV"
fi

echo "Mastodon ready at https://localhost:3000 (users: hunter, kadaba)"
echo "Run: source $HUNTER_ENV && mix test --only integration"
