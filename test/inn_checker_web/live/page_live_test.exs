defmodule InnCheckerWeb.PageLiveTest do
  use InnCheckerWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")

    assert disconnected_html =~ "Input INN"
    assert render(page_live) =~ "Input INN"
  end
end
