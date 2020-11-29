defmodule InnCheckerWeb.PageLive do
  @moduledoc false

  use InnCheckerWeb, :live_view
  use InnCheckerWeb.FlashAutocloser

  alias InnChecker.Schema.History
  alias InnChecker.Validator

  import InnChecker.Blocker

  @impl true
  def mount(_params, %{"remote_ip" => remote_ip} = _session, socket) do
    if connected?(socket), do: send(self(), :update)

    {:ok, assign(socket, %{default_assigns() | remote_ip: tuple_to_str(remote_ip)})}
  end

  @impl true
  def handle_info(:update, %{assigns: %{remote_ip: remote_ip}} = socket) do
    history_queries = history_load_for(remote_ip)
    {:noreply, assign(socket, history_queries: history_queries)}
  end

  @impl true
  def handle_event("inn_check", %{"inn-value" => inn_value} = _params, %{assigns: %{remote_ip: remote_ip}} = socket) do
    if is_blocked(remote_ip)  do
      socket = put_flash_autoclose(socket, :error, "Your ip is blocked")

      {:noreply, assign(socket, inn_value: "")}
    else
      history_queries = [inn_validation(inn_value, remote_ip) | socket.assigns[:history_queries]]
      {:noreply, assign(socket, inn_value: "", history_queries: history_queries)}
    end
  end

  # private

  def default_assigns, do: %{inn_value: "", history_queries: [], remote_ip: "inknown"}

  defp has_history([]), do: false
  defp has_history(_history_queries), do: true

  defp tuple_to_str(tuple, connector_str \\ ".")
  defp tuple_to_str(tuple, connector) when is_tuple(tuple) do
    tuple |> Tuple.to_list() |> Enum.join(connector)
  end

  defp inn_validation(inn_string, remote_ip) do
    {status, res_validation} =
      case Validator.validation(inn_string) do
        {:ok, validated_str} -> {"correct", validated_str}
        _                    -> {"incorrect", inn_string}
      end

    case inn_validation_save(remote_ip, res_validation, status) do
      {:ok, %History{} = history} -> format_result(history.inn, history.inserted_at, history.status)
      {:error, %Ecto.Changeset{}} -> "Can not save result"
    end
  end

  defp format_result(inn_string, dt, result) do
    :io_lib.format("[~2..0B.~2..0B.~4..0B ~2..0B:~2..0B] ~s : ~s",
      [dt.day, dt.month, dt.year, dt.hour, dt.minute, inn_string, result]
    )
    |> IO.iodata_to_binary()
  end

  defp inn_validation_save(ip, inn_string, result) when is_tuple(ip) do
    inn_validation_save(tuple_to_str(ip), inn_string, result)
  end
  defp inn_validation_save(ip, inn_string, result) do
    case History.create(%{ip: ip, inn: inn_string, status: result}) do
      {:ok, _history} = res -> res
      {:error, _}          -> {:error, :not_save}
    end
  end

  defp history_load_for(ip) when is_tuple(ip) do
    history_load_for(tuple_to_str(ip))
  end
  defp history_load_for(ip) when is_binary(ip) do
    History.get(%{ip: ip})
    |> Enum.map(fn %History{inn: inn, inserted_at: inserted_at, status: status} ->
        # TODO: store this string in table histories
        format_result(inn, inserted_at, status)
       end)
  end
end
