defmodule TakeOff.Alert do
  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def index do
    Agent.get(__MODULE__, & &1)
  end

  def add(params) do
    Agent.update(__MODULE__, fn list -> list ++ [params] end)
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> [] end)
  end
end
