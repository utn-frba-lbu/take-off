defmodule TakeOff.BookingCoordinator do
  use GenServer
  require Logger

  def start_link(_initial_value) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(initial_value) do
    Horde.Registry.register(TakeOff.HordeRegistry, :coordinator, self())
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, initial_value, {:continue, :load_state}}
  end

  def handle_continue(:load_state, _args) do
    Logger.info("trying to load state")
    flight_state = Enum.reduce([Node.self | Node.list], %{updated_time: nil, flights: []}, fn node, acc ->
      node_state = GenServer.call({TakeOff.Flight, node}, :index)

      if acc.updated_time == nil or node_state.updated_time > acc.updated_time do
        node_state
      else
        acc
      end
    end)

    if flight_state.updated_time != nil do
      Logger.info("loaded flight state at #{inspect flight_state.updated_time}")
    else
      Logger.info("no previous flight state found")
    end

    reservation_state = Enum.reduce([Node.self | Node.list], %{updated_time: nil, bookings: []}, fn node, acc ->
      node_state = GenServer.call({TakeOff.Reservation, node}, :index)

      if acc.updated_time == nil or node_state.updated_time > acc.updated_time do
        node_state
      else
        acc
      end
    end)

    if reservation_state.updated_time != nil do
      Logger.info("loaded reservation state at #{inspect reservation_state.updated_time}")
    else
      Logger.info("no previous reservation state found")
    end

    broadcast_all_flights(flight_state)
    broadcast_all_reservations(reservation_state)

    state = %{updated_time: DateTime.utc_now(), flights: flight_state.flights, bookings: reservation_state.bookings}
    {:noreply, state}
  end

  def spawn() do
    child_spec =
      %{
        id: :coordinator,
        start: {__MODULE__, :start_link, [[]]},
        restart: :transient, # TODO revisar
      }

    if get_coordinator_pid() == nil do
      TakeOff.HordeSupervisor.start_child(child_spec)
    end
  end

  def get_coordinator_pid() do
    case Horde.Registry.lookup(TakeOff.HordeRegistry, :coordinator) do
      [] -> nil
      [{pid, _}] -> pid
    end
  end

  def handle_cast({:new_flight, _pid, flight}, state) do
    Logger.info("received new flight: #{inspect flight}")
    {:noreply, %{updated_time: DateTime.utc_now(), flights: [flight | state.flights], bookings: state.bookings}}
  end

  # booking { user: "123", flight_id: 123, seats: {window: 10, middle: 5} }
  def handle_cast({:book, from, booking}, state) do
    Logger.info("received booking attempt: #{inspect booking}")
    Logger.info("booking attempt from: #{inspect from}")

    # Iterate over the state to find the flight
    # flight = {
    #   id: 123,
    #   seats: {
    #     window: 10,
    #     aisle: 10,
    #     middle: 10
    #   }
    # }
    flight_index = Enum.find_index(state.flights, fn flight -> flight[:id] == booking[:flight_id] end)
    flight = Enum.at(state.flights, flight_index)
    doable = Enum.all?(booking.seats, fn {type, amount} -> flight.seats[type] >= amount end)

    new_flights = if doable do
      Logger.info("booking is doable for: #{inspect from}}}")
      # Send accepted
      GenServer.cast(from, {:booking_accepted, self(), booking})
      # Update state
      updated_seats = Enum.map(flight.seats, fn {type, amount} ->
        # check if the booking want to book a seat of the current type
        if booking.seats[type] do
          {type, amount - booking.seats[type]}
        else
          {type, amount}
        end
      end)
      List.replace_at(state.flights, flight_index, %{flight | seats: Enum.into(updated_seats, %{})})
    else
      Logger.info("booking is not doable")
      # Send rejected
      GenServer.cast(from, {:booking_denied, self(), booking})
      state.flights
    end

    new_state = %{updated_time: DateTime.utc_now(), flights: new_flights, bookings: [booking | state.bookings]}

    # Send the updated flights to all nodes
    broadcast_all_flights(%{updated_time: new_state.updated_time, flights: new_flights})

    {:noreply, new_state}
  end

  def broadcast_all_flights(flights) do
    Logger.info("broadcasting all flights")
    Enum.map([Node.self | Node.list], fn node ->
      GenServer.cast({TakeOff.Flight, node}, {:reset, self(), flights})
    end)
  end

  def broadcast_all_reservations(reservations) do
    Logger.info("broadcasting all reservations")
    Enum.map([Node.self | Node.list], fn node ->
      GenServer.cast({TakeOff.Reservation, node}, {:update_bookings, self(), reservations})
    end)
  end

  @impl GenServer
  @doc """
  Handler that will be called when a node has joined the cluster.
  """
  def handle_info({:nodeup, node, _node_type}, state) do
    GenServer.cast({TakeOff.Flight, node}, {:reset, self(), state.flights})
    GenServer.cast({TakeOff.Reservation, node}, {:update_bookings, self(), state.bookings})
    {:noreply, state}
  end

  @impl GenServer
  @doc """
  Handler that will be called when a node has left the cluster.
  """
  def handle_info({:nodedown, node, _node_type}, state) do
    {:noreply, state}
  end

end
