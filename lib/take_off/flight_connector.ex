defmodule TakeOff.FlightConnector do
  use GenServer
  require Logger

  def start_link(initial_value) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  @impl true
  def init(value), do: {:ok, value}

  def broadcast(:flight, flight) do
    Logger.info("Connector - Broadcasting flight: #{inspect flight}")
    Enum.each(Node.list, fn node ->
      send({TakeOff.FlightConnector, node}, {:new_flight, Node.self, flight})
    end)
  end

  @impl true
  def handle_info({:new_flight, from, flight}, state) do
    Logger.info("Connector - Receiving flight: #{inspect flight}")
    TakeOff.Flight.receive(flight)
    {:noreply, state}
  end
end
