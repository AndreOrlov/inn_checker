defmodule InnCheckerWeb.AdminLive do
  @moduledoc false

  use InnCheckerWeb, :live_view
  use InnCheckerWeb.FlashAutocloser

  alias InnChecker.Schema.History
  alias InnChecker.Session

  @impl true
  def mount(_params, %{"session_id" => session_id} = _session, socket) do
    socket =
      case Session.get(session_id, :user) do
        nil  ->
          redirect(socket, to: "/login")

        user ->
          if connected?(socket) do
            Process.send_after(self(), :clear_flash, 5000)
            send(self(), :update)
          end
          assign(socket, %{default_assigns() | user: user})
      end

      {:ok, socket}
  end
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: "/login")}
  end

  @impl true
  def handle_event("drop", %{"id" => id}, socket) do
    socket =
      case History.delete(id) do
        {:ok, _deleted_row} -> assign(socket, history_queries: history_load())
        _                   -> put_flash_autoclose(socket, :error, "Can not delete")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:update, socket) do
    history_queries = history_load()
    {:noreply, assign(socket, history_queries: history_queries)}
  end

  def handle_info({:updated_blocking_status, blocker}, socket) do
    socket.assigns.history_queries
    |> history_group_by_ip()
    |> Map.get(blocker.item_id, [])
    |> Enum.each(fn id ->
      send_update BlockerComponent, id: build_id(id), item_id: blocker.item_id, is_blocking: blocker.is_blocking
    end)

    {:noreply, socket}
  end

  # private

  defp default_assigns, do: %{history_queries: [], user: nil}

  defp build_id(id), do: "blocker_#{id}"

  defp has_history([]), do: false
  defp has_history([_ | _]), do: true

  defp history_load, do: History.get(:all)

  # group id by ip field
  defp history_group_by_ip(histories) do
    histories
    |> Enum.group_by(&Map.take(&1, [:ip]))
    |> Enum.map(fn {key, values} ->
      [:id]
      |> Enum.map(fn key_to_list ->
        {key_to_list, Enum.map(values, & Map.fetch!(&1, key_to_list))}
      end)
      |> Enum.into(key)
    end)
    |> Enum.reduce(%{}, fn i, acc -> Map.put(acc, i.ip, i.id) end)
  end
end
