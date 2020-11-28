defmodule InnChecker.Schema.History do
  @moduledoc false

  use Ecto.Schema

  alias InnChecker.Repo

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "histories" do
    field :ip, :string, default: "unknown"
    field :inn, :string
    field :status, :string

    timestamps()
  end

  # NOTE: this using must be placed below schema definition as it uses %__MODULE__{} inside
  use InnChecker.Schema

  @required_fields ~w[inn status]a
  @optional_fields ~w[ip]a
  @statuses ~w[correct incorrect]

  def changeset(history, attrs) do
    history
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields, message: "обязательное поле")
    |> validate_inclusion(:status, @statuses)
  end

  @impl InnChecker.Schema
  def get(:all) do
    query =
      from u in __MODULE__,
        order_by: [desc: u.inserted_at],
        select: u
    Repo.all(query)
  end
  def get(%{ip: ip}) when is_binary(ip) do
    query =
      from u in __MODULE__,
        where: u.ip == ^ip,
        order_by: [desc: u.inserted_at],
        select: u
    Repo.all(query)
  end
  def get(id) when is_binary(id) do
    super(id)
  end
end
