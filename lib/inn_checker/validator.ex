defmodule InnChecker.Validator do
  @moduledoc false

  def is_valid(multipliers, inn_string) do
    with {:ok, digit_list} <- convert_to_digit_list(inn_string),
      multiplied = multiply(digit_list),
      tenth_digit = Enum.at(digit_list, 9),
      ^tenth_digit <- calc_magic_number(multiplied)
    do
      true
    else
      _ -> false
    end
  end

  # private

  defp convert_to_digit_list(str) do
    case Integer.parse(str) do
      {number, ""} -> {:ok, Integer.digits(number)}
      _            -> {:error, :string_is_not_number}
    end
  end

  @multipliers [2, 4, 10, 3, 5, 9, 4, 6, 8]
  defp multiply(inn_digit_list) do
    Enum.zip(@multipliers, inn_digit_list) |> Enum.reduce(0, fn {i1, i2}, acc -> i1 * i2 + acc end)
  end

  @magic_digit 11
  defp calc_magic_number(multiplied) do
    res = multiplied - div(multiplied, @magic_digit) * @magic_digit
    case res do
      10 -> 0
      _  -> res
    end
  end
end
