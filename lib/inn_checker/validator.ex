defmodule InnChecker.Validator do
  @moduledoc false

  # "7723747750" correct ten-digit INN
  # "500100732259" correct twelve-digit INN

  @spec validation(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def validation(inn_string) do
    case String.length(inn_string) do
      10 -> validation10(inn_string)
      12 -> validation12(inn_string)
      _  -> {:error, :wrong_format}
    end
  end

  # private

  @multipliers9 [2, 4, 10, 3, 5, 9, 4, 6, 8]
  defp validation10(inn_string) do
    is_valid(inn_string, @multipliers9, 9)
  end

  @multipliers10 [7, 2, 4, 10, 3, 5, 9, 4, 6, 8]
  @multipliers11 [3, 7, 2, 4, 10, 3, 5, 9, 4, 6, 8]
  defp validation12(inn_string) do
    with {:ok, _} <- is_valid(inn_string, @multipliers10, 10),
      {:ok, _} <- is_valid(inn_string, @multipliers11, 11)
    do
      {:ok, inn_string}
    end
  end

  defp is_valid(inn_string, multipliers, index_checker) do
    with {:ok, digit_list} <- convert_to_digit_list(inn_string),
      multiplied = multiply(multipliers, digit_list),
      tenth_digit = Enum.at(digit_list, index_checker),
      ^tenth_digit <- calc_magic_number(multiplied)
    do
      {:ok, inn_string}
    else
      _ -> {:error, :not_valid}
    end
  end

  defp convert_to_digit_list(str) do
    case Integer.parse(str) do
      {number, ""} -> {:ok, Integer.digits(number)}
      _            -> {:error, :string_is_not_number}
    end
  end

  defp multiply(multipliers, inn_digit_list) do
    Enum.zip(multipliers, inn_digit_list) |> Enum.reduce(0, fn {i1, i2}, acc -> i1 * i2 + acc end)
  end

  @magic_digit 11
  defp calc_magic_number(multiplied) do
    case rem(multiplied, @magic_digit) do
      10  -> 0
      res -> res
    end
  end
end
