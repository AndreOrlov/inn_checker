import Config

config :inn_checker,
  site_title: System.get_env("SITE_TITLE", "inn.checker")

config :inn_checker, InnChecker.Repo,
  username: System.fetch_env!("DB_USERNAME"),
  password: System.fetch_env!("DB_PASSWORD"),
  database: System.fetch_env!("DB_NAME"),
  hostname: System.fetch_env!("DB_HOST"),
  port: String.to_integer(System.get_env("DB_PORT", "5432"))

config :inn_checker, InnCheckerWeb.Endpoint,
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  live_view: [signing_salt: System.fetch_env!("SERVER_LIVE_SALT")],
  code_reloader: false,
  url: [host: System.fetch_env!("SERVER_HOST"), port: String.to_integer(System.get_env("SERVER_PORT", "80"))],
  http: [port: String.to_integer(System.get_env("APP_PORT", "4000"))],
  check_origin: String.split(System.get_env("CORS_ORIGIN", "//#{System.fetch_env!("SERVER_HOST")}"), ~r/\s+/),
  server: true

config :inn_checker, InnChecker.Guardian,
  issuer: "inn_checker",
  # mix guardian.gen.secret
  secret_key: System.fetch_env!("GUARDIAN_KEY")
