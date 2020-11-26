defmodule InnChecker.Schema.User do
  @moduledoc false

  use Ecto.Schema

  alias Argon2
  alias InnChecker.Repo

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :login, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string
    field :status, :string, default: "inactive"
    field :role, :string

    timestamps()
  end

  # NOTE: this using must be placed below schema definition as it uses %__MODULE__{} inside
  use InnChecker.Schema

  @required_fields ~w[login]a
  @optional_fields ~w[password password_confirmation status role]a
  @roles ~w[operator admin]
  @statuses ~w[active inactive deleted]

  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_length(:password, min: 5)
    |> validate_format(:password, ~r/[0-9]+/, message: "пароль должен содержать цифры")
    |> validate_format(:password, ~r/\p{Lu}/u, message: "пароль должен содержать заглавные буквы")
    |> validate_format(:password, ~r/\p{Ll}/u, message: "пароль должен содержать строчные буквы")
    |> validate_confirmation(:password, message: "введённые пароли не совпадают")
    |> put_password_hash()
    |> validate_required(@required_fields, message: "обязательное поле")
    |> validate_role()
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:login, max: 50)
    |> unique_constraint(:login, name: :users_login_index)
  end

  @impl InnChecker.Schema
  def get(%{id: id}) when is_binary(id)do
    super(id)
  end
  def get(%{login: login}) do
    case Repo.get_by(__MODULE__, %{login: login}) do
      nil  -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def verify_user(%{password: password} = params) do
    with {:ok, user} <- get(params) do
      Argon2.check_pass(user, password)
    end
  end

  # private

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: pwd}} = changeset) do
    change(changeset, Argon2.add_hash(pwd))
  end
  defp put_password_hash(changeset), do: changeset

  defp validate_role(%Ecto.Changeset{changes: %{role: _}} = changeset) do
    if Ecto.Changeset.get_change(changeset, :role) in @roles do
      changeset
    else
      Ecto.Changeset.add_error(changeset, :role, "недопустимая роль")
    end
  end
  defp validate_role(changeset) do
    changeset
  end
end
