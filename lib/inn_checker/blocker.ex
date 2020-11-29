defmodule InnChecker.Blocker do
  @moduledoc """
  Blocker calc INN
  """

  alias InnChecker.KV.Storage

  def is_blocked(:not_blocked) do
    false
  end
  def is_blocked(:infinity) do
    true
  end
  def is_blocked(num) when is_integer(num) do
    false
  end
  def is_blocked(id) when is_binary(id) do
    case time_left_block(id) do
      :not_blocked -> false
      _            -> true
    end
  end

  def time_left_block(id) when is_binary(id) do
    case Storage.ttl(id) do
      {:error, :not_found_key}  -> :not_blocked
      {:error, :expire_not_set} -> :infinity
      {:ok, remaining}          -> remaining
      _                         -> :not_blocked
    end
  end

  def blocked_row(id) do
    case Storage.put(id, DateTime.utc_now()) do
      :ok -> :infinity
      _   -> :not_blocked
    end
  end

  def blocked_row(id, 0) do
    blocked_row(id)
  end
  def blocked_row(id, expire_sec) when is_integer(expire_sec) do
    case Storage.put(id, DateTime.utc_now(), expire_sec) do
      :ok -> expire_sec
      _   -> :not_blocked
    end
  end

  def unblocked_row(id) do
    case Storage.delete(id) do
      :ok -> :not_blocked
      _   -> :infinity
    end
  end
end
