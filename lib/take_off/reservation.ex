defmodule TakeOff.Reservation do
  use GenServer
  require Logger

  def start_link(_initial_value) do
    GenServer.start_link(__MODULE__, %{status: :initializing,  bookings: []}, name: __MODULE__)
  end

  def init(initial_value) do
    {:ok, initial_value, {:continue, :load_state}}
  end

  def index do
    GenServer.call(__MODULE__, :index)
  end

  defp confirm_booking(coordinator_pid, booking) do
    # Send the booking attempt to the coordinator
    try do
      response = GenServer.call(coordinator_pid, {:book, booking})
      GenServer.cast(__MODULE__, {response, booking})

      if response == :booking_accepted do
        Logger.info("booking accepted")
        %{status: response, message: "booking accepted"}
      else
        Logger.info("booking denied")
        %{status: response, message: "not enough seats available"}
      end
    rescue
      _ -> %{status: :booking_denied, message: "error booking flight"}
    catch
      :exit, e -> %{status: :booking_denied, message: "coordinator exited"}
    end
  end

  # Reservation { user: "123", flight_id: 123, seats: {window: 10} }
  def book(booking) do
    pid = TakeOff.BookingCoordinator.get_coordinator_pid(booking.flight_id)
    flight = TakeOff.Flight.get_by_id(booking.flight_id)
    case flight do
      nil -> %{status: :flight_not_found, message: "flight not found"}
      %{status: :closed} -> %{status: :flight_closed, message: "flight closed"}
      _ when pid == nil -> %{status: :flight_not_available, message: "flight is not available"}
      _ -> confirm_booking(pid, booking)
    end
  end

  def broadcast(method, data, false) do
    Enum.map(Node.list, fn node ->
      GenServer.cast({__MODULE__, node}, {method, self(), data})
    end)
  end

  def get_state_from_node(node) do
    try do
      GenServer.call({__MODULE__, node}, :index)
    rescue
      _ -> nil
    catch
      :exit, e -> nil
    end
  end

  # SERVER METHODS

  def handle_continue(:load_state, state) do
    Logger.info("trying to load state")

    bookings = Stream.map(Node.list, fn node -> get_state_from_node(node) end)
      |> Enum.find([], fn bookings -> bookings != nil and bookings != :initializing end)

    {:noreply, Map.merge(state, %{status: :ready, bookings: bookings})}
  end

  # confirmation of a booking from the coordinator
  def handle_cast({:booking_accepted, booking}, state) do
    Logger.info("booking confirmed: #{inspect booking}")
    # Send the booking to all nodes
    broadcast(:new_booking, booking, false)
    {:noreply, Map.merge(state, %{bookings: [booking | state.bookings]})}
  end

  # denial of a booking from the coordinator
  def handle_cast({:booking_denied, booking}, state) do
    Logger.info("booking denied: #{inspect booking}")
    {:noreply, state}
  end

  # notification of new booking confirmed by other nodes
  def handle_cast({:new_booking, _pid, booking}, state) do
    Logger.info("new booking received: #{inspect booking}")
    {:noreply, Map.merge(state, %{bookings: [booking | state.bookings]})}
  end

  def handle_call(:index, _from, state) do
    case state.status do
      :initializing -> {:reply, :initializing, state}
      :ready -> {:reply, state.bookings, state}
    end
  end
end
