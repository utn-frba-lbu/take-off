defmodule TakeOff.Alert do
  use Agent
  require Logger

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def index do
    Agent.get(__MODULE__, & &1)
  end

  def add(params) do
    Agent.update(__MODULE__, fn list -> list ++ [params] end)
  end

  def notify(flight) do
    %{origin: origin, destination: destination, datetime: datetime} = flight
    # TODO: vamos a buscar por date, y el vuelo es por datetime, FIXEAR
    result = Enum.filter(TakeOff.Alert.index, fn %{origin: alert_origin, destination: alert_destination, date: alert_date} ->
      origin == alert_origin && destination == alert_destination && datetime == alert_date
    end)
    Logger.info("Notify flight: #{inspect result}")
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> [] end)
  end
end
