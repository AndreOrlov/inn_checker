defmodule InnCheckerWeb.BlockerComponent do
  @moduledoc false

  use InnCheckerWeb, :live_component

  alias InnChecker.KV.Storage

  def render(assigns) do
    ~L"""
    <div>
    <%= if @is_blocking do %>
      <a title="<%= blocking_status(@item_id) %>"
         class="button"
         href="#"
         phx-capture-click="unblock"
         phx-value-id="<%= @item_id %>"
         phx-target="<%= @myself %>">
        Unblock
      </a>
    <% else %>
       <form phx-submit="block" phx-target="<%= @myself %>">
        <input style="width:60px" type="number" name="expire" min="0" max="120" value=0 step=10>
        <button title="<%= blocking_status(@item_id) %>" type="submit" phx-disable-with="Block">Block</button>
      </form
    <% end %>
    </div>
    """
  end

  def mount(socket) do
    IO.inspect({socket |> Map.to_list()}, label: MOUNT_BLOCKER)

    {:ok, assign(socket, default_assign())}
  end

  def update(%{id: id, item_id: item_id} = _assigns, socket) do
    IO.inspect({_assigns, socket |> Map.to_list()}, label: UPDATE_BLOCKER)

    {:ok, assign(socket, %{id: id, item_id: item_id, is_blocking: is_blocked(item_id)})}
  end

  def handle_event("block", %{"expire" => expire} = _params, %{assigns: %{id: id, item_id: item_id}} = socket) do
    IO.inspect({_params, socket}, label: BLOCK_EVENT)

    with {exp, ""} <- Integer.parse(expire) |> IO.inspect() do
      res = blocked_row(item_id, exp) |> IO.inspect(label: WITH_BLOCK)
      send(self(), {:updated_blocking_status, %{id: id, item_id: item_id, is_blocking: is_blocked(res)}})
    end

    {:noreply, socket}
  end

  def handle_event("unblock", _params, %{assigns: %{id: id, item_id: item_id}} = socket) do
    IO.inspect({_params, socket}, label: UNBLOCK_EVENT)

    res = unblocked_row(item_id)
    send(self(), {:updated_blocking_status, %{id: id, item_id: item_id, is_blocking: is_blocked(res)}})

    {:noreply, socket}
  end
  # private

  defp default_assign(), do: %{id: "", item_id: "", is_blocking: false}

  defp is_blocked(:not_blocked) do
    false
  end
  defp is_blocked(:infinity) do
    true
  end
  defp is_blocked(num) when is_integer(num) do
    false
  end
  defp is_blocked(id) when is_binary(id) do
    case time_left_block(id) do
      :not_blocked -> false
      _            -> true
    end |> IO.inspect(label: IS_BLOCKED_COMPONENT)
  end

  defp blocking_status(id) when is_binary(id) do
    id |> time_left_block() |> formatter_blocking_status()
  end

  defp formatter_blocking_status(:not_blocked), do: "Row isn't blocking"
  defp formatter_blocking_status(:infinity), do: "Row locked"
  defp formatter_blocking_status(secs) when is_integer(secs),
    do: "Row'll be unlocked at #{DateTime.utc_now() |> DateTime.add(secs, :second)}"
  defp formatter_blocking_status(_), do: "Unknown status blocking"

  defp time_left_block(id) when is_binary(id) do
    case Storage.ttl(id) do
      {:error, :not_found_key}  -> :not_blocked
      {:error, :expire_not_set} -> :infinity
      {:ok, remaining}          -> remaining
      _                         -> :not_blocked
    end |> IO.inspect(label: TIME_LEFT_BLOCK)
  end

  defp blocked_row(id) do
    case Storage.put(id, DateTime.utc_now()) do
      :ok -> :infinity
      _   -> :not_blocked
    end |> IO.inspect(label: BLOCKED_ROW1)
  end

  defp blocked_row(id, 0) do
    blocked_row(id) |> IO.inspect(label: BLOCKED_ROW2_1)
  end
  defp blocked_row(id, expire_sec) when is_integer(expire_sec) do
    case Storage.put(id, DateTime.utc_now(), expire_sec) do
      :ok -> expire_sec
      _   -> :not_blocked
    end |> IO.inspect(label: BLOCKED_ROW2)
  end

  defp unblocked_row(id) do
    case Storage.delete(id) do
      :ok -> :not_blocked
      _   -> :infinity
    end
  end
end
