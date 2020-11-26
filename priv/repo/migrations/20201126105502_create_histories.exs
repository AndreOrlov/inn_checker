defmodule InnChecker.Repo.Migrations.CreateHistories do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:histories, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :ip, :string, default: "unknown", size: 20
      add :inn, :string, size: 12
      add :result, :string

      timestamps()
    end

    create index(:histories, ~w[ip]a)
  end
end
