defmodule TakeOff.Subscription do
  use GenServer
  require Logger

  def start_link(initial_value) do
    GenServer.start_link(__MODULE__, %{status: :initializing, subscriptions: %{}}, name: __MODULE__)
  end

  def init(initial_value) do
    {:ok, initial_value, {:continue, :load_state}}
  end

  def index do
    GenServer.call(__MODULE__, :index)
  end

  def add(subscription) do
    GenServer.cast(__MODULE__, {:add, subscription})

    broadcast(:add, subscription)
  end

  def notify(flight) do
    GenServer.cast(__MODULE__, {:notify, flight})
  end

  def broadcast(method, data) do
    Enum.map(Node.list, fn node ->
      GenServer.cast({__MODULE__, node}, {method, data})
    end)
  end

  # SERVER METHODS

  def handle_continue(:load_state, state) do
    Logger.info("trying to load state")

    subscriptions = Stream.map(Node.list, fn node -> GenServer.call({__MODULE__, node}, :index) end)
      |> Enum.find(%{}, fn subscriptions -> subscriptions != :initializing end)

    Logger.info("subscriptions: #{inspect subscriptions}")

    {:noreply, Map.merge(state, %{status: :ready, subscriptions: subscriptions})}
  end

  def handle_call(:index, _from, state) do
    Logger.info("received handle_call: index")
    case state.status do
      :initializing -> {:reply, :initializing, state}
      :ready -> {:reply, state.subscriptions, state}
    end
  end

  def handle_cast({:add, subscription}, state) do
    Logger.info("adding new subscription: #{inspect subscription}")
    flight_subscription = Map.get(state.subscriptions, subscription.flight_id, [])
    new_subscriptions = Map.put(state.subscriptions, subscription.flight_id, [subscription | flight_subscription])
    {:noreply, Map.merge(state, %{subscriptions: new_subscriptions})}
  end

  def handle_cast({:notify, flight}, state) do
    {flight_subscriptions, subscriptions} = Map.pop(state.subscriptions, flight.id)

    Logger.info("state: #{inspect state}")

    Logger.info("sending flight #{flight.id} to #{inspect flight_subscriptions}")

    Enum.map(flight_subscriptions, fn subscription ->
      Task.start(fn ->
        Logger.info("sending subscription to #{subscription.user}")

        HTTPoison.post(subscription.webhook_uri, Poison.encode!(flight))
      end)
    end)

    {:noreply, Map.merge(state, %{subscriptions: subscriptions})}
  end
end