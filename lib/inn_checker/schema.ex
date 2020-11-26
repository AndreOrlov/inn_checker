defmodule InnChecker.Schema do
  @moduledoc """
  Generic module for ecto schema models.

  Provides basic CRUD operations (get, create, update, delete).

  ## Usage

  Add `use InnChecker.Schema` **AFTER** `schema` definition. You can override some logic by your needs (in such cases
  don't forget about catch-all methods):

    defmodule YourModel do
      schema "your_model" do
        field :name, :string
      end

      use InnChecker.Schema

      def get(:all), do: :all |> super() |> Enum.map(& Map.put(:sum, &1.x + &1.y))
      def get(query), do: super(query)
    end
  """

  alias InnChecker.Repo
  alias Ecto.{Query, Schema, UUID}

  import Ecto.Changeset

  @dialyzer {:nowarn_function, cast_map_changes_with_opts: 4}

  @type repo_result :: {:ok, Schema.t()} | {:error, term()}

  @callback get(query :: :all | binary() | Query.t()) :: repo_result() | [Schema.t()]
  @callback create(map()) :: repo_result()
  @callback update(binary() | Schema.t(), map()) :: repo_result()
  @callback delete(:all | binary() | Schema.t()) :: :ok | {:error, term()}

  def cast_data(changeset, opts), do: cast_map(changeset, :data, opts)

  def cast_map(%Ecto.Changeset{changes: changes} = changeset, field, opts) do
    if Map.has_key?(changes, field) do
      changes |> Map.get(field) |> cast_map_changes(changeset, field, opts)
    else
      changeset
    end
  end
  def cast_map(changeset, _field, _opts), do: changeset

  defp cast_map_changes(%{} = data, changeset, field, opts) do
    data
    |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), v} end)
    |> cast_map_changes_with_opts(changeset, field, opts)
  end
  defp cast_map_changes(_, changeset, _, _), do: changeset

  defp cast_map_changes_with_opts(data, changeset, field, opts) when is_function(opts, 2) do
    case opts.(data, changeset) do
      %Ecto.Changeset{} = changeset -> changeset
      opts                          -> cast_map_changes_with_opts(data, changeset, field, opts)
    end
  end
  defp cast_map_changes_with_opts(data, changeset, field, opts) do
    fields = Keyword.fetch!(opts, :fields)
    validate = Keyword.get(opts, :validate, & &1)
    {%{}, fields}
    |> cast(data, Map.keys(fields))
    |> validate.()
    |> case do
      %{valid?: true, changes: %{} = data} ->
        put_change(changeset, field, data)
      %{valid?: true} ->
        changeset
      %{valid?: false, errors: errors} ->
        Enum.reduce(errors, changeset, fn {error_field, msg}, changeset ->
          add_error(changeset, "#{field}.#{error_field}", msg)
        end)
    end
  end

  defmacro __using__(_opts) do
    quote(location: :keep) do
      @behaviour unquote(__MODULE__)

      import unquote(__MODULE__), only: [cast_data: 2, cast_map: 3]

      @impl unquote(__MODULE__)
      def get(:all) do
        unquote(Repo).all(__MODULE__)
      end
      def get(id) when is_binary(id) do
        with {:ok, id}            <- unquote(UUID).cast(id),
             %__MODULE__{} = item <- unquote(Repo).get(__MODULE__, id) do
          {:ok, item}
        else
          nil -> {:error, :not_found}
          _   -> {:error, :wrong_uuid}
        end
      end
      def get(%unquote(Query){} = query) do
        Repo.all(query)
      end

      @impl unquote(__MODULE__)
      def create(params) do
        %__MODULE__{}
        |> changeset(params)
        |> Repo.insert()
      end

      @impl unquote(__MODULE__)
      def update(id, params) when is_binary(id) do
        with {:ok, record} <- get(id), do: update(record, params)
      end
      def update(%__MODULE__{} = record, params) do
        record
        |> changeset(params)
        |> Repo.update()
      end

      @impl unquote(__MODULE__)
      def delete(:all) do
        Repo.delete_all(__MODULE__)
      end
      def delete(id) when is_binary(id) do
        with {:ok, record} <- get(id), do: delete(record)
      end
      def delete(%__MODULE__{} = record) do
        Repo.delete(record)
      end
      def delete(_), do: :ok

      defoverridable create: 1, delete: 1, get: 1, update: 2
    end
  end
end
