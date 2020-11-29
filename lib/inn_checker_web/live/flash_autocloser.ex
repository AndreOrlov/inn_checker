defmodule InnCheckerWeb.FlashAutocloser do
  @moduledoc """
  Autoclose live flash message
  """

  import Phoenix.LiveView, only: [put_flash: 3, clear_flash: 1]

  defmacro __using__(_opts) do
    quote do
      def put_flash_autoclose(socket, kind, msg_str, expire_ms \\ 3000)
      def put_flash_autoclose(socket, kind, msg_str, expire_ms) when kind in ~w[error info]a do
        Process.send_after(self(), :clear_flash, expire_ms)
        put_flash(socket, kind, msg_str)
      end

      def handle_info(:clear_flash, socket) do
        {:noreply, clear_flash(socket)}
      end
    end
  end
end
