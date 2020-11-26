defmodule InnCheckerWeb.PageLive do
  @moduledoc false

  alias InnChecker.Validator

  use InnCheckerWeb, :live_view

  @impl true
  def mount(_params, %{"remote_ip" => remote_ip} = _session, socket) do
    {:ok, assign(socket, results: %{}, inn_value: "", history_queries: [], remote_ip: remote_ip)}
  end

  @impl true
  def handle_event("inn_check", %{"inn-value" => inn_value} = _params, socket) do
    history_queries = [inn_validation(inn_value) | socket.assigns[:history_queries]]
    {:noreply, assign(socket, inn_value: "", history_queries: history_queries)}
  end

  # private

  defp has_history([]), do: false
  defp has_history(_history_queries), do: true

  defp tuple_to_str(tuple, connector_str \\ ".")
  defp tuple_to_str(tuple, connector) when is_tuple(tuple) do
    tuple |> Tuple.to_list() |> Enum.join(connector)
  end

  defp inn_validation(inn_string) do
    case Validator.validation(inn_string) do
      {:ok, str} -> format_result(str, DateTime.utc_now(), "correct")
      _          -> format_result(inn_string, DateTime.utc_now(), "incorrect")
    end
  end

  defp format_result(inn_string, dt, result) do
    :io_lib.format("[~2..0B.~2..0B.~4..0B ~2..0B:~2..0B] ~s : ~s",
      [dt.day, dt.month, dt.year, dt.hour, dt.minute, inn_string, result]
    )
    |> IO.iodata_to_binary()
  end
end
