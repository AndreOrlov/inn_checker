defmodule InnChecker.Session do
  @moduledoc """
  User session handling
  """

  defmodule Plug do
    @moduledoc """
    Plug for storing session_id in `conn` session
    """

    @session_key "session_id"

    alias Elixir.Plug.Conn
    alias InnChecker.Session

    def init(default), do: default

    def call(%Conn{} = conn, _) do
      conn = Conn.fetch_session(conn)
      case Conn.get_session(conn, @session_key) do
        nil ->
          conn |> start_session()

        id ->
          case Session.get_session(id) do
            {:error, :not_found} -> conn |> start_session()
            {:ok, _}             -> conn
          end
      end
    end

    def auth?(%Conn{} = conn) do
      conn = Conn.fetch_session(conn)
      res =
        case Conn.get_session(conn, @session_key) do
          nil -> nil
          id  -> Session.get(id, :user)
        end
      !!res
    end

    defp start_session(conn) do
      case Session.start_session() do
        {:ok, id} -> Conn.put_session(conn, @session_key, id)
        _         -> conn
      end
    end
  end

  use GenServer
  @session_ttl 1_000 * 60 * 60 * 24 # one day

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_session do
    GenServer.call(__MODULE__, :create_session)
  end

  def invalidate_session(id) do
    GenServer.call(__MODULE__, {:invalidate_session, id})
  end

  def get(id, key, default \\ nil) do
    case get_session(id) do
      {:ok, session} -> Map.get(session, key, default)
      _              -> default
    end
  end

  def put(id, key, value) do
    put_session(id, %{key => value})
  end

  def pop(id, key, default \\ nil) do
    GenServer.call(__MODULE__, {:pop_session, id, key, default})
  end

  def get_session(id) do
    GenServer.call(__MODULE__, {:get_session, id})
  end

  def put_session(id, data) when is_map(data) do
    GenServer.call(__MODULE__, {:put_session, id, data})
  end
  def put_session(id, data) when is_list(data) do
    if Keyword.keyword?(data) do
      GenServer.call(__MODULE__, {:put_session, id, Enum.into(data, %{})})
    else
      {:error, :invalid_session}
    end
  end

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call(:create_session, _, st) do
    id = UUID.uuid4()
    timer = Process.send_after(self(), {:remove_session, id}, @session_ttl)
    {:reply, {:ok, id}, Map.put(st, id, {timer, %{}})}
  end
  def handle_call({:invalidate_session, id}, _, st) do
    case Map.get(st, id) do
      {timer, data} ->
        Process.cancel_timer(timer)
        timer = Process.send_after(self(), {:remove_session, id}, @session_ttl)
        {:reply, :ok, Map.put(st, id, {timer, data})}
      _ ->
        {:reply, {:error, :not_found}, st}
    end
  end
  def handle_call({:get_session, id}, _, st) do
    case Map.get(st, id) do
      {_, data} ->
        {:reply, {:ok, data}, st}
      _ ->
        {:reply, {:error, :not_found}, st}
    end
  end
  def handle_call({:put_session, id, new_data}, _, st) when is_map(new_data) do
    case Map.get(st, id) do
      {timer, data} ->
        data = Map.merge(data, new_data)
        Process.cancel_timer(timer)
        timer = Process.send_after(self(), {:remove_session, id}, @session_ttl)
        {:reply, {:ok, data}, Map.put(st, id, {timer, data})}
      _ ->
        {:reply, {:error, :not_found}, st}
    end
  end
  def handle_call({:pop_session, id, key, default}, _, st) do
    case Map.get(st, id) do
      {timer, data} ->
        {value, data} = Map.pop(data, key, default)
        Process.cancel_timer(timer)
        timer = Process.send_after(self(), {:remove_session, id}, @session_ttl)
        {:reply, value, Map.put(st, id, {timer, data})}
      _ ->
        {:reply, default, st}
    end
  end

  @impl GenServer
  def handle_info({:remove_session, id}, st) do
    {:noreply, Map.delete(st, id)}
  end
end
