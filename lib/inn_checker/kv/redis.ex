defmodule InnChecker.KV.Redis do
  @moduledoc false

  # Client API

  # TODO: add spec to all public function
  def put(redix, key, value) do
    command = ["SET", key, value]

    case Redix.command(redix, command)do
      {:ok, _} -> :ok
      _        -> {:error, "Can not execute '#{commands_to_string(command)}'"}
    end
  end

  def put(redix, key, value, expire_sec) do
    commands = [
      ["SET", key, value],
      ["EXPIRE", key, expire_sec],
    ]

    case Redix.transaction_pipeline(redix, commands) do
      {:ok, _} -> :ok
      _        -> {:error, "Can not execute '#{commands_to_string(commands)}'"}
    end
  end

  def get(redix, key) do
    command = ["GET", key]

    case Redix.command(redix, command) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, res} -> {:ok, res}
      error      -> {:error, {error, "Error execute..."}}
    end
  end

  def delete(redix, key) do
    command = ["DEL", key]

    case Redix.command(redix, command) do
      {:ok, _} -> :ok
      _        -> {:error, "Can not execute '#{commands_to_string(command)}'"}
    end
  end

  defmacro __using__(opts) do
    redix = assert_valid_key(opts[:redix])

    quote do
      def put(key, value), do: unquote(__MODULE__).put(unquote(redix), key, value)
      def put(key, value, expire_sec), do: unquote(__MODULE__).put(unquote(redix), key, value, expire_sec)

      def get(key), do: unquote(__MODULE__).get(unquote(redix), key)
      def delete(key), do: unquote(__MODULE__).delete(unquote(redix), key)
    end
  end

  # Helpers

  defp commands_to_string(commands) do
    commands
    |> List.flatten
    |> Enum.join(" ")
  end

  defp assert_valid_key(nil) do
    raise CompileError, description: "You should specify redix option when use #{__MODULE__}"
  end
  defp assert_valid_key(app), do: app
end
