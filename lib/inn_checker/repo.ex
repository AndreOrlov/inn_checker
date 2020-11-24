defmodule InnChecker.Repo do
  use Ecto.Repo,
    otp_app: :inn_checker,
    adapter: Ecto.Adapters.Postgres
end
