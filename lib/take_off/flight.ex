defmodule TakeOff.Flight do
  use GenServer
  require Logger

  def start_link(initial_value) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  def init(initial_value) do
    {:ok, initial_value}
  end

  def index do
    GenServer.call(__MODULE__, :index)
  end

  def add(params) do
    Logger.info("Node list: #{inspect Node.list()}")
    TakeOff.Alert.notify(params)
    broadcast(:add, params)
    GenServer.cast({TakeOff.BookingCoordinator, :"a@127.0.0.1"}, {:new_flight, self(), params})
  end

  def reset do
    broadcast(:reset, [])
  end

  def broadcast(method, data) do
    Enum.map([Node.self | Node.list], fn node ->
      GenServer.cast({__MODULE__, node}, {method, self(), data})
    end)
  end

  # SERVER METHODS

  def handle_call(:index, _from, state) do
    {:reply, state, state}
  end

  def handle_cast(:reset, _state) do
    {:noreply, []}
  end

  def handle_cast({:reset, _pid, new_state}, _state) do
    Logger.info("received handle_cast: reset #{inspect new_state}")
    {:noreply, new_state}
  end

  def handle_cast({:add, _pid, params}, state) do
    Logger.info("received handle_cast: add #{inspect params}")
    {:noreply, [params | state]}
  end
end
