defmodule TakeOff.Reservation do
  use GenServer
  require Logger

  def start_link(initial_value) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  def init(initial_value) do
    {:ok, initial_value}
  end

  # Reservation { user: "123", flight_id: 123, seats: {window: 10} }
  def confirm_reservartion(booking) do
    # Nice to have: Check if the seat is available, raise if not

    # Send the booking attempt to the coordinator
    GenServer.cast({TakeOff.BookingCoordinator, :"a@127.0.0.1"}, {:book, self(), booking})
  end

  # SERVER METHODS

  def handle_cast({:booking_accepted, _pid, booking}, state) do
    Logger.info("booking confirmed: #{inspect booking}")
    {:noreply, [booking | state]}
  end

  def handle_cast({:booking_denied, _pid, booking}, state) do
    Logger.info("booking denied: #{inspect booking}")
    {:noreply, state}
  end

  # def value do
  #   Agent.get(__MODULE__, & &1)
  # end

  # def increment do
  #   Agent.update(__MODULE__, &(&1 + 1))
  # end
end
