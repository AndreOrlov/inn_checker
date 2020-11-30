defmodule InnChecker.Repo.Migrations.CreateUsers do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :login, :string, null: false, size: 20
      add :password_hash, :string, null: false
      add :role, :string
      add :status, :string, size: 30, default: "inactive"

      timestamps()
    end

    create unique_index(:users, ~w[login]a)
    create index(:users, ~w[password_hash]a)
  end
end
