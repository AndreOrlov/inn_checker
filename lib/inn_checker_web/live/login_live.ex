defmodule InnCheckerWeb.LoginLive do
  @moduledoc false

  use InnCheckerWeb, :live_view

  alias InnChecker.Schema.User
  alias InnChecker.Session

  @impl true
  def mount(_params, %{"session_id" => session_id} = _session, socket) do
    Session.put(session_id, :user, nil)

    assigns = Map.put(default_assigns(), :session_id, session_id)

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("login", %{"login" => login, "password" => password} = _params, %{assigns: %{session_id: session_id}} = socket) do
    {user, socket} =
      case verify_user(login, password) do
        {:ok, user} -> {user, put_flash(socket, :info, "You are logged")}
        _           -> {nil, put_flash(socket, :error, "Wrong login or password")}
      end
    Session.put(session_id, :user, user)

    {:noreply, redirect(socket, to: "/admin")}
  end
  def handle_event("login", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:user_logged_in, user}, %{assigns: %{session_id: session_id}} = socket) do
    Session.put(session_id, :user, user)
    {:noreply, assign(socket, :user, user)}
  end

  # private

  defp default_assigns, do: %{login: "", password: ""}

  defp verify_user(login, password) do
    case User.verify_user(%{login: login, password: password}) do
      {:ok, _user} = res -> res
      _                  -> {:error, :invalid_user}
    end
  end
end
