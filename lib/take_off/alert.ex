defmodule TakeOff.Alert do
  use GenServer
  require Logger

  def start_link(initial_value) do
    GenServer.start_link(__MODULE__, %{status: :initializing, alerts: []}, name: __MODULE__)
  end

  def init(initial_value) do
    {:ok, initial_value, {:continue, :load_state}}
  end

  def index do
    GenServer.call(__MODULE__, :index)
  end

  def add(alert) do
    GenServer.cast(__MODULE__, {:add, alert})

    broadcast(:add, alert)
  end

  def notify(flight) do
    GenServer.cast(__MODULE__, {:notify, flight})
  end

  def broadcast(method, data) do
    Enum.map(Node.list, fn node ->
      GenServer.cast({__MODULE__, node}, {method, data})
    end)
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> [] end)
  end

  # SERVER METHODS

  def handle_continue(:load_state, state) do
    Logger.info("trying to load state")

    alerts = Stream.map(Node.list, fn node -> GenServer.call({__MODULE__, node}, :index) end)
      |> Enum.find([], fn alerts -> alerts != :initializing end)

    Logger.info("alerts: #{inspect alerts}")

    {:noreply, Map.merge(state, %{status: :ready, alerts: alerts})}
  end

  def handle_call(:index, _from, state) do
    Logger.info("received handle_call: index")
    case state.status do
      :initializing -> {:reply, :initializing, state}
      :ready -> {:reply, state.alerts, state}
    end
  end

  def handle_cast({:add, alert}, state) do
    Logger.info("adding new alert: #{inspect alert}")
    {:noreply, Map.merge(state, %{alerts: [alert | state.alerts]})}
  end

  def handle_cast({:notify, flight}, state) do
    %{origin: origin, destination: destination, datetime: datetime} = flight
    # TODO: vamos a buscar por date, y el vuelo es por datetime, FIXEAR
    result = Enum.filter(state.alerts, fn %{origin: alert_origin, destination: alert_destination, date: alert_date} ->
      origin == alert_origin && destination == alert_destination && datetime == alert_date
    end)

    Enum.map(result, fn alert ->
      Task.start(fn ->
        Logger.info("sending alert to #{alert.user}")

        HTTPoison.post(alert.webhook_uri, Poison.encode!(flight))
      end)
    end)

    {:noreply, state}
  end
end
