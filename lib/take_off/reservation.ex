defmodule TakeOff.Reservation do
  alias Mix.Tasks.Phx.Gen
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

  defp confirm_booking(booking) do
    # Send the booking attempt to the coordinator
    pid = TakeOff.BookingCoordinator.get_coordinator_pid(booking.flight_id)

    response = GenServer.call(pid, {:book, booking})
    GenServer.cast(__MODULE__, {response, booking})

    if response == :booking_accepted do
      Logger.info("booking accepted")
      %{status: response, message: "booking accepted"}
    else
      Logger.info("booking denied")
      %{status: response, message: "not enough seats available"}
    end
  end

  # Reservation { user: "123", flight_id: 123, seats: {window: 10} }
  def book(booking) do
    # Nice to have: Check if the seat is available, raise if not
    flight = TakeOff.Flight.get_by_id(booking.flight_id)
    case flight do
      nil -> %{status: :flight_not_found, message: "flight not found"}
      %{status: :closed} -> %{status: :flight_closed, message: "flight closed"}
      _ -> confirm_booking(booking)
    end
  end

  def broadcast(method, data, false) do
    Enum.map(Node.list, fn node ->
      GenServer.cast({__MODULE__, node}, {method, self(), data})
    end)
  end

  # SERVER METHODS

  # confirmation of a booking from the coordinator
  def handle_cast({:booking_accepted, booking}, state) do
    Logger.info("booking confirmed: #{inspect booking}")
    # Send the booking to all nodes
    broadcast(:new_booking, booking, false)
    {:noreply, [booking | state]}
  end

  # denial of a booking from the coordinator
  def handle_cast({:booking_denied, booking}, state) do
    Logger.info("booking denied: #{inspect booking}")
    {:noreply, state}
  end

  # notification of new booking confirmed by other nodes
  def handle_cast({:new_booking, _pid, booking}, state) do
    Logger.info("new booking received: #{inspect booking}")
    {:noreply, [booking | state]}
  end

  def handle_call(:index, _from, state) do
    {:reply, state, state}
  end
end
