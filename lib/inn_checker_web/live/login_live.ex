defmodule InnCheckerWeb.LoginLive do
  @moduledoc false

  use InnCheckerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # TODO: rad
    # if connected?(socket), do: send(self(), :update)

    {:ok, socket}
  end
end
