defmodule TakeOff.Flight do
  use Agent
  require Logger

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def index do
    Agent.get(__MODULE__, & &1)
  end

  def create(params) do
    Logger.info("Flight - Creating flight: #{inspect params}")
    Agent.update(__MODULE__, fn list -> list ++ [params] end)
    TakeOff.Alert.notify(params)
    TakeOff.FlightConnector.broadcast(:flight, params)
  end

  def receive(params) do
    Logger.info("Flight - Receiving flight: #{inspect params}")
    Agent.update(__MODULE__, fn list -> list ++ [params] end)
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> [] end)
  end
end
