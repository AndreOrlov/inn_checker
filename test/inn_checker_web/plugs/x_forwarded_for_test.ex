defmodule XForwardedForTest do
  @moduledoc false

  alias InnCheckerWeb.XForwardedFor

  use ExUnit.Case, async: false
  use Plug.Test

  setup_all _context do
    ips = ~w[192.168.1.1 192.168.1.2 192.168.1.3]
    %{conn: conn(:get, "/"), ips: ips}
  end

  test "does not have field proxy", %{conn: conn} do

    opts = XForwardedFor.init()
    conn = XForwardedFor.call(conn, opts)

    assert {127, 0, 0, 1} == conn.remote_ip
  end

  test "has field x-forwarded-for proxy", %{conn: conn, ips: ips} do
    conn = put_req_header(conn, "x-forwarded-for", Enum.join(ips, ", "))

    opts = XForwardedFor.init()
    conn = XForwardedFor.call(conn, opts)

    assert {192, 168, 1, 1} == conn.remote_ip
  end

  test "has field x-real-ip proxy", %{conn: conn, ips: ips} do
    conn = put_req_header(conn, "x-real-ip", Enum.join(ips, ", "))

    opts = XForwardedFor.init([header: "x-real-ip"])
    conn = XForwardedFor.call(conn, opts)

    assert {192, 168, 1, 1} == conn.remote_ip
  end
end
