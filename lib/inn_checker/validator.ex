defmodule InnChecker.Validator do
  @moduledoc false


  def is_valid(multipliers, inn_string) when String.is_length(inn_string) == 10 do
    with {:ok, digit_list} <- convert_to_digit_list(inn_string),
      multiplied = multiply(digit_list),
      ten_digit = Enum.at(9),
      ^ten_digit <- calc_magic_number(multiplied)
    do
      true
    else
      false
    end
  end

  # private

  # TODO: конвертировать в цифры!
  def convert_to_digit_list(str) do
    case Integer.parse(str) do
      {_, ""} -> {:ok, String.to_char(str)}
      _       -> {:error, :string_is_not_number}
    end
  end

  def multiply(multipliers, inn_digit_list) do
    Enum.zip(multipliers, inn_string) |> Enum.reduce(0, fn {i1, i2}, acc -> i1 * i2 + acc end)
  end

  @magic_digit 11
  def calc_magic_number(multiplied) do
    res = multiplied - div(multiplied, @magic_digit) * @magic_digit
    case res do
      10 -> 0
      _  -> res
    end
  end
end
