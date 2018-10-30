use Mix.Config

config :hunter, hunter_api: Hunter.Api.HTTPClient
config :hunter, http_options: [follow_redirect: true, hackney: [{:force_redirect, true}]]
