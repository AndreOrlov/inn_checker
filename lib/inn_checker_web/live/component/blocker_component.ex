defmodule InnCheckerWeb.BlockerComponent do
  @moduledoc false

  use InnCheckerWeb, :live_component

  alias InnChecker.KV.Storage

  def render(assigns) do
    ~L"""
    <%= if is_blocked(@item_id) do %>
      <a title="<%= blocking_status(@item_id) %>" class="button" href="#" phx-capture-click="unblock" phx-value-id="<%= @item_id %>">Unblock</a>
    <% else %>
      <a title="<%= blocking_status(@item_id) %>" class="button" href="#" phx-capture-click="block" phx-value-id="<%= @item_id %>">Block</a>
    <% end %>
    """
  end

  def mount(socket) do
    IO.inspect({socket |> Map.to_list()}, label: MOUNT_BLOCKER)

    {:ok, assign(socket, default_assign())}
  end

  def update(%{item_id: item_id} = _assigns, socket) do
    IO.inspect({_assigns, socket |> Map.to_list()}, label: UPDATE_BLOCKER)

    {:ok, assign(socket, :item_id, item_id)}
  end

  # private

  defp default_assign(), do: %{item_id: ""}

  defp is_blocked(id) when is_binary(id) do
    case time_left_block(id) do
      :not_blocked -> false
      _            -> true
    end
  end

  defp blocking_status(id) when is_binary(id) do
    id |> time_left_block() |> formatter_blocking_status()
  end

  defp formatter_blocking_status(:not_blocked), do: "Row isn't blocking"
  defp formatter_blocking_status(:infinity), do: "Row locked"
  defp formatter_blocking_status(secs) when is_integer(secs),
    do: "Row'll be unlocked at #{DataTime.utc_now() |> DateTime.add(secs, :second) }"
  defp formatter_blocking_status(_), do: "Unknown status blocking"

  defp time_left_block(id) when is_binary(id) do
    case Storage.ttl(id) do
      {:error, :not_found_key}  -> :not_blocked
      {:error, :expire_not_set} -> :infinity
      {:ok, remaining}          -> remaining
      _                         -> :not_blocked
    end
  end

  defp blocked_row(id) do
    case Storage.put(id, DateTime.utc_now()) do
      :ok -> :infinity
      _   -> :not_blocked
    end
  end

  defp blocked_row(id, expire_sec) do
    case Storage.put(id, DateTime.utc_now(), expire_sec) do
      :ok -> expire_sec
      _   -> :not_blocked
    end
  end
end
