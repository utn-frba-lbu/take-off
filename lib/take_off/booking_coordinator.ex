defmodule TakeOff.BookingCoordinator do
  use GenServer
  require Logger

  def start_link(initial_value) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  @spec init(any) :: {:ok, any}
  def init(initial_value) do
    {:ok, initial_value}
  end

  def handle_cast({:new_flight, _pid, flight}, state) do
    Logger.info("received new flight: #{inspect flight}")
    {:noreply, [flight | state]}
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
    flight_index = Enum.find_index(state, fn flight -> flight[:id] == booking[:flight_id] end)
    flight = Enum.at(state, flight_index)
    doable = Enum.all?(booking.seats, fn {type, amount} -> flight.seats[type] >= amount end)

    new_state = if doable do
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
      List.replace_at(state, flight_index, %{flight | seats: Enum.into(updated_seats, %{})})
    else
      Logger.info("booking is not doable")
      # Send rejected
      GenServer.cast(from, {:booking_denied, self(), booking})
      state
    end

    # Send the updated flights to all nodes
    broadcast_all_flights(new_state)

    {:noreply, new_state}
  end

  def broadcast_all_flights(flights) do
    Logger.info("broadcasting all flights")
    Enum.map([Node.self | Node.list], fn node ->
      GenServer.cast({TakeOff.Flight, node}, {:reset, self(), flights})
    end)
  end

  def handle_call(:flights, _from, state) do
    {:reply, state, state}
  end
end
