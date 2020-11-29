use Mix.Config

config :inn_checker,
  ecto_repos: [InnChecker.Repo]

# Configures the endpoint
config :inn_checker, InnCheckerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "CoMmiiqlHR5FoFISk9DsAl2hNzfLh1tyhPYJqWyIWrcKGaj105pvu83qICsjMYXl",
  render_errors: [view: InnCheckerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: InnChecker.PubSub,
  live_view: [signing_salt: "metoOrMB"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
