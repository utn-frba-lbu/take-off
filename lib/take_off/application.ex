defmodule TakeOff.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: [:"a@127.0.0.1", :"b@127.0.0.1"]],
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: MyApp.ClusterSupervisor]]},
      # Start the Telemetry supervisor
      TakeOffWeb.Telemetry,
      # Start the PubSub system
      # {Phoenix.PubSub, name: TakeOff.PubSub},
      {Phoenix.PubSub, [name: TakeOff.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start Finch
      {Finch, name: TakeOff.Finch},
      # Start the Endpoint (http/https)
      TakeOffWeb.Endpoint,
      {TakeOff.Reservation, 0},
      {TakeOff.Flight, []},
      {TakeOff.Alert, []},
      # Start a worker by calling: TakeOff.Worker.start_link(arg)
      # {TakeOff.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TakeOff.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TakeOffWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
