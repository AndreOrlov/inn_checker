defmodule InnCheckerWeb.LogoutLive do
  @moduledoc false

  use InnCheckerWeb, :live_view

  alias InnChecker.Session

  def render(assigns) do
    ~L"""
    """
  end

  @impl true
  def mount(_params, %{"session_id" => session_id} = _session, socket) do
    Session.put(session_id, :user, nil)

    {:ok, redirect(socket, to: "/")}
  end
end
