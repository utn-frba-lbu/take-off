defmodule TakeOff.Flight do
  use GenServer
  require Logger

  def start_link(initial_value) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  def index do
    GenServer.call(__MODULE__, :index)
  end

  def init(initial_value) do
    {:ok, initial_value}
  end

  def add(params) do
    Logger.info("Node list: #{inspect Node.list()}")
    Node.list() |>
    Enum.map(fn node ->
      send({__MODULE__, node}, {:add, self(), params})
    end)
    TakeOff.Alert.notify(params)
  end

  def reset do
    GenServer.cast(__MODULE__, :reset)
  end

  # SERVER METHODS

  def handle_call(:index, _from, state) do
    {:reply, state, state}
  end

  def handle_cast(:reset, _state) do
    {:noreply, []}
  end

  def handle_info({:add, _pid, params}, state) do
    Logger.info("received handle_cast: #{inspect params}")
    {:noreply, [params | state]}
  end
end
