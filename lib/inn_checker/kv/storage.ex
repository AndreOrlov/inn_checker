defmodule InnChecker.KV.Storage do
  @moduledoc false

  use InnChecker.KV.Redis, redix: Redix
end
