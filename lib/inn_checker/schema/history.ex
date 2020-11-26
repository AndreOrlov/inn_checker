defmodule InnChecker.Schema.History do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

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
end
