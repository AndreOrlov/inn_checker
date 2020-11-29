defmodule InnCheckerWeb.BlockerComponent do
  @moduledoc false

  use InnCheckerWeb, :live_component

  alias InnChecker.Trust

  import InnChecker.Blocker

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
    {:ok, assign(socket, default_assign())}
  end

  def update(%{id: id, item_id: item_id, user: user} = _assigns, socket) do
    {:ok, assign(socket, %{id: id, item_id: item_id, is_blocking: is_blocked(item_id), user: user})}
  end
  def update(%{id: id, item_id: item_id} = _assigns, socket) do
    {:ok, assign(socket, %{id: id, item_id: item_id, is_blocking: is_blocked(item_id)})}
  end

  def handle_event("block", %{"expire" => expire} = _params, %{assigns: %{id: id, item_id: item_id, user: user}} = socket) do
    with true <- Trust.can?(user, :manage, :admin),
      {exp, ""} <- Integer.parse(expire)
    do
      res = blocked_row(item_id, exp)
      send(self(), {:updated_blocking_status, %{id: id, item_id: item_id, is_blocking: is_blocked(res)}})
    end

    {:noreply, socket}
  end

  def handle_event("unblock", _params, %{assigns: %{id: id, item_id: item_id}} = socket) do
    res = unblocked_row(item_id)
    send(self(), {:updated_blocking_status, %{id: id, item_id: item_id, is_blocking: is_blocked(res)}})

    {:noreply, socket}
  end

  # private

  defp default_assign, do: %{id: "", item_id: "", is_blocking: false, user: nil}

  defp blocking_status(id) when is_binary(id) do
    id |> time_left_block() |> formatter_blocking_status()
  end

  defp formatter_blocking_status(:not_blocked), do: "Row isn't blocking"
  defp formatter_blocking_status(:infinity), do: "Row locked"
  defp formatter_blocking_status(secs) when is_integer(secs),
    do: "Row'll be unlocked at #{DateTime.utc_now() |> DateTime.add(secs, :second)}"
  defp formatter_blocking_status(_), do: "Unknown status blocking"
end
