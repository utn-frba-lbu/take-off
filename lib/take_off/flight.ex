defmodule TakeOff.Flight do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(initial_value) do
    {:ok, initial_value}
  end

  def index do
    GenServer.call(__MODULE__, :index)
  end

  def add(params) do
    Logger.info("Adding flight: #{inspect params}")

    id = UUID.uuid4()
    flight = Map.merge(params, %{id: id, status: :open, created_at: DateTime.utc_now(), updated_at: DateTime.utc_now()})

    TakeOff.Alert.notify(flight)

    broadcast(:add, flight)

    TakeOff.BookingCoordinator.spawn(flight.id)
  end

  def reset do
    broadcast(:reset, nil)
  end

  def broadcast(method, data) do
    Enum.map([Node.self | Node.list], fn node ->
      GenServer.cast({__MODULE__, node}, {method, self(), data})
    end)
  end

  def get_by_id(flight_id) do
    GenServer.call(__MODULE__, {:get_by_id, flight_id})
  end

  # SERVER METHODS

  def handle_call(:index, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_by_id, flight_id}, _from, state) do
    Logger.info("received handle_call: get_by_id #{inspect flight_id}")
    Logger.info("state: #{inspect state}")
    {:reply, Map.get(state, flight_id), state}
  end

  def handle_cast(:reset, _state) do
    {:noreply, %{}}
  end

  def handle_cast({:update, _pid, updated_flight}, state) do
    Logger.info("received handle_cast: reset #{inspect updated_flight}")

    {:noreply, Map.put(state, updated_flight.id, updated_flight)}
  end

  def handle_cast({:add, _pid, new_flight}, state) do
    Logger.info("received handle_cast: add #{inspect new_flight}")

    {:noreply, Map.put(state, new_flight.id, new_flight)}
  end
end
