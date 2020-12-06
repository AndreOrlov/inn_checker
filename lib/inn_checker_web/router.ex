defmodule InnCheckerWeb.Router do
  use InnCheckerWeb, :router

  pipeline :browser do
    plug InnChecker.Session.Plug
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {InnCheckerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug InnCheckerWeb.XForwardedFor, header: "x-real-ip"
    plug :put_client_ip
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", InnCheckerWeb do
    pipe_through :browser

    live "/", PageLive, :index
    live "/login", LoginLive, :index
    live "/logout", LogoutLive, :index
    live "/admin", AdminLive, :index
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: InnCheckerWeb.Telemetry
    end
  end

  defp put_client_ip(conn, _) do
    Plug.Conn.put_session(conn, :remote_ip, conn.remote_ip)
  end
end
