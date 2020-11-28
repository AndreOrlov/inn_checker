defmodule InnCheckerWeb.AdminLive do
  @moduledoc false

  use InnCheckerWeb, :live_view

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

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  def handle_info({:updated_blocking_status, blocker}, socket) do
    IO.inspect(socket, label: UPDATED_BLOCKING_STATUS_ADMIN_LIVE)
    send_update BlockerComponent, id: blocker.id, item_id: blocker.item_id, is_blocking: blocker.is_blocking
    {:noreply, socket}
  end

  # private

  defp default_assigns(), do: %{history_queries: [], user: nil}

  defp put_flash_autoclose(socket, kind, msg_str, expire_ms \\ 3000)
  defp put_flash_autoclose(socket, kind, msg_str, expire_ms) when kind in ~w[error info]a do
    Process.send_after(self(), :clear_flash, 5000)
    put_flash(socket, kind, msg_str)
  end

  defp has_history([]), do: false
  defp has_history([_ | _]), do: true

  defp history_load(), do: History.get(:all)
end
