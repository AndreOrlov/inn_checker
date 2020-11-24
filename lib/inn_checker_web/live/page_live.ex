defmodule InnCheckerWeb.PageLive do
  @moduledoc false

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

    history_queries = [inn_value | socket.assigns[:history_queries]]
    {:noreply, assign(socket, inn_value: inn_value, history_queries: history_queries)}
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
end
