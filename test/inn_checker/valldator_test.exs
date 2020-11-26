defmodule InnChecker.ValidatorTest do
  @moduledoc false

  alias InnChecker.Validator

  use ExUnit.Case, async: true

  test "not digits INN" do
    inn = "12345678A9"

    assert {:error, :not_valid} == Validator.validation(inn)
  end

  test "wrong length INN" do
    inn = "12345678901"

    assert {:error, :wrong_format} == Validator.validation(inn)
  end

  test "correct 10 digit INN" do
    inn = "7723747750"

    assert {:ok, inn} == Validator.validation(inn)
  end

  test "wrong 10 digit INN" do
    inn = "7723747751"

    assert {:error, :not_valid} == Validator.validation(inn)
  end

  test "correct 12 digit INN" do
    inn = "500100732259"

    assert {:ok, inn} == Validator.validation(inn)
  end

  test "wrong 12 digit INN" do
    inn = "500100732250"

    assert {:error, :not_valid} == Validator.validation(inn)
  end
end
