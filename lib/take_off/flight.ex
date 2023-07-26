defmodule TakeOff.Flight do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{status: :initializing,  flights: %{}}, name: __MODULE__)
  end

  def init(initial_value) do
    {:ok, initial_value, {:continue, :load_state}}
  end

  def index do
    GenServer.call(__MODULE__, :index)
  end

  def add(params) do
    Logger.info("Adding flight: #{inspect params}")

    id = UUID.uuid4()
    now = DateTime.utc_now()
    flight = Map.merge(params, %{id: id, status: :open, created_at: now, updated_at: now})

    TakeOff.Alert.notify(flight)
    broadcast(:add, flight)
    TakeOff.BookingCoordinator.spawn(flight.id)

    flight
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

  def handle_continue(:load_state, state) do
    Logger.info("trying to load state")

    flights = Stream.map(Node.list, fn node -> GenServer.call({__MODULE__, node}, :index) end)
      |> Enum.find(%{}, fn flights -> flights != :initializing end)

    Logger.info("flights: #{inspect flights}")

    {:noreply, Map.merge(state, %{status: :ready, flights: flights})}
  end

  def handle_call(:index, _from, state) do
    Logger.info("received handle_call: index")
    case state.status do
      :initializing -> {:reply, :initializing, state}
      :ready -> {:reply, state.flights, state}
    end
  end

  def handle_call({:get_by_id, flight_id}, _from, state) do
    Logger.info("received handle_call: get_by_id #{inspect flight_id}")

    {:reply, Map.get(state.flights, flight_id), state}
  end

  def handle_cast({:update, _pid, updated_flight}, state) do
    Logger.info("received handle_cast: update #{inspect updated_flight}")

    flights = Map.put(state.flights, updated_flight.id, updated_flight)
    {:noreply, Map.merge(state, %{flights: flights})}
  end

  def handle_cast({:add, _pid, new_flight}, state) do
    Logger.info("received handle_cast: add #{inspect new_flight}")

    flights = Map.put(state.flights, new_flight.id, new_flight)
    {:noreply, Map.merge(state, %{flights: flights})}
  end
end
