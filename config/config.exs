# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :notimesh,
  generators: [timestamp_type: :utc_datetime]

# Configure the database
config :notimesh, Notimesh.Repo,
  database: "notimesh_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10

# Configure Oban
config :notimesh, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10, notifications: 20],
  repo: Notimesh.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 3600}
  ]

# Configure Erlang distribution
config :notimesh,
  node_name: System.get_env("NODE_NAME") || "notimesh@127.0.0.1",
  cookie: System.get_env("COOKIE") || "notimesh_cookie"

# Configures the endpoint
config :notimesh, NotimeshWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: NotimeshWeb.ErrorHTML, json: NotimeshWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Notimesh.PubSub,
  live_view: [signing_salt: "zQgvLCfN"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  notimesh: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  notimesh: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
