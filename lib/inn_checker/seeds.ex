defmodule InnChecker.Seeds do
  @moduledoc false

  alias InnChecker.Schema.User

  def run(_) do
      User.delete(:all)

      ~w[admin admin_inactve operator]a
      |> Enum.map(& seed/1)
  end

  defp seed(:admin) do
    {:ok, _} = User.create(%{
      login: "w",
      password: "2wW34",
      password_confirmarion: "2wW34",
      role: "admin",
      status: "active",
    })
    :ok
  end
  defp seed(:admin_inactve) do
    {:ok, _} = User.create(%{
      login: "e",
      password: "3eE45",
      password_confirmarion: "3eE45",
      role: "admin",
      status: "inactive",
    })
    :ok
  end
  defp seed(:operator) do
    User.create(%{
      login: "q",
      password: "1qQ23",
      password_confirmarion: "1qQ23",
      role: "operator",
      status: "active",
    })
    :ok
  end
end
