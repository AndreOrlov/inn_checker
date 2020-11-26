defmodule InnChecker.Repo.Migrations.CreateHistories do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:histories, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :ip, :string, default: "unknown", size: 20
      add :inn, :string, null: false, size: 12
      add :status, :string, null: false

      timestamps()
    end

    create index(:histories, ~w[ip]a)
  end
end
