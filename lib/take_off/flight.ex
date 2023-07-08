defmodule TakeOff.Flight do
  use Agent

  def start_link(initial_value) do
    TakeOffWeb.TestChannel.join("test:flight", %{"body" => "New flight added!"})
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def index do
    Agent.get(__MODULE__, & &1)
  end

  def add(params) do
    Agent.update(__MODULE__, fn list -> list ++ [params] end)
    TakeOff.Alert.notify(params)
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> [] end)
  end
end
