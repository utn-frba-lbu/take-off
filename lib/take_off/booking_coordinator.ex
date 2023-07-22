defmodule TakeOff.BookingCoordinator do
  use GenServer
  require Logger

  def start_link(flight_id) do
    Logger.info("starting coordinator for flight #{flight_id}")
    GenServer.start_link(__MODULE__, flight_id, name: String.to_atom("coordinator_#{flight_id}"))
  end

  def init(flight_id) do
    Logger.info("initializing coordinator for flight #{inspect flight_id}")
    Horde.Registry.register(TakeOff.HordeRegistry, {:coordinator, flight_id}, self())
    {:ok, %{flight_id: flight_id, status: :initializing}, {:continue, :load_state}}
  end

  def spawn(flight_id) do
    Logger.info("spawning coordinator for flight #{flight_id}")
    child_spec =
      %{
        id: {:coordinator, flight_id},
        start: {__MODULE__, :start_link, [flight_id]},
        restart: :transient, # TODO revisar
      }
    coordinator_pid = get_coordinator_pid(flight_id)
    Logger.info("coordinator_pid: #{inspect coordinator_pid}")
    if get_coordinator_pid(flight_id) == nil do
      Logger.info("starting child")
      TakeOff.HordeSupervisor.start_child(child_spec)
    end
  end

  def get_coordinator_pid(flight_id) do
    case Horde.Registry.lookup(TakeOff.HordeRegistry, {:coordinator, flight_id}) do
      [] -> nil
      [{pid, _}] -> pid
    end
  end

  def update_flight(flight, seats) do
    # Update state
    updated_seats = Enum.map(flight.seats, fn {type, amount} ->
      if seats[type] do
        {type, amount - seats[type]}
      else
        {type, amount}
      end
    end)

    updated_status = if Enum.all?(updated_seats, fn {_, amount} -> amount == 0 end), do: :closed, else: flight.status

    Map.merge(flight, %{updated_at: DateTime.utc_now(), seats: Enum.into(updated_seats, %{}), status: updated_status})
  end

  def broadcast_flight(flight) do
    Logger.info("broadcasting all flight")
    Enum.map([Node.self | Node.list], fn node ->
      GenServer.cast({TakeOff.Flight, node}, {:update, self(), flight})
    end)
  end

  # SERVER METHODS

  def handle_continue(:load_state, state) do
    Logger.info("trying to load state")

    flight = Enum.map([Node.self | Node.list], fn node -> GenServer.call {TakeOff.Flight, node}, {:get_by_id, state[:flight_id]} end)
      |> Enum.max_by(fn node_flight -> if node_flight, do: node_flight.updated_at, else: -1 end)

    time_to_close = DateTime.add(flight.created_at, flight.offer_duration, :day) |> DateTime.diff(DateTime.utc_now(), :millisecond)
    :timer.send_after(time_to_close, :close_flight)

    {:noreply, Map.merge(state, %{status: :ready, flight: flight})}
  end

  # booking { user: "123", flight_id: 123, seats: {window: 10, middle: 5} }
  def handle_call({:book, booking}, _from, state) do
    Logger.info("received booking attempt: #{inspect booking}")

    flight = state.flight

    is_valid = Enum.all?(booking.seats, fn {type, amount} -> flight.seats[type] >= amount end)

    updated_flight = if is_valid, do: update_flight(flight, booking.seats), else: flight

    new_state = Map.merge(state, %{flight: updated_flight})

    # Send the updated flight to all nodes
    broadcast_flight(updated_flight) # TODO Maybe we can not send the flight if it is not updated

    response = if is_valid, do: :booking_accepted, else: :booking_denied

    if updated_flight.status == :closed do
      Logger.info("flight is full, killing coordinator")
      TakeOff.Subscription.notify(updated_flight)

      {:stop, :normal, response, new_state}
    else
      if is_valid, do: TakeOff.Subscription.cancel_if_exists(booking.user, booking.flight_id)
      {:reply, response, new_state}
    end
  end

  def handle_info(:close_flight, state) do
    Logger.info("closing flight #{inspect state[:flight_id]}")

    new_flight = Map.merge(state.flight, %{status: :closed})
    broadcast_flight(new_flight)

    {:stop, :normal, Map.merge(state, %{flight: new_flight})}
  end
end
