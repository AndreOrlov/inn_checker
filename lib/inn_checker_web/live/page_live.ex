defmodule InnCheckerWeb.PageLive do
  @moduledoc false

  alias InnChecker.Validator

  use InnCheckerWeb, :live_view

  @impl true
  def mount(_params, %{"remote_ip" => remote_ip} = _session, socket) do
    # TODO: rad
    IO.inspect({SESSION, _session})

    # TODO: удалить ненужные аттрибуты
    {:ok, assign(socket, query: "", results: %{}, inn_value: "", history_queries: [], remote_ip: remote_ip)}
  end

  # TODO: rad
  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  @impl true
  def handle_event("inn_check", %{"inn-value" => inn_value} = params, socket) do
    # TODO: rad
    IO.inspect({inn_value, socket |> Map.to_list(), socket.assigns[:history_queries], params})

    history_queries = [inn_validation(inn_value) | socket.assigns[:history_queries]]
    {:noreply, assign(socket, inn_value: "", history_queries: history_queries)}
  end

  # TODO: rad
  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  # private

  # TODO: rad
  defp search(query) do
    if not InnCheckerWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end

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
