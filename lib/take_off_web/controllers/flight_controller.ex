defmodule TakeOffWeb.FlightController do
  use TakeOffWeb, :controller
  require Logger

  def index(conn, _) do
    flights = TakeOff.Flight.index()
    Logger.info("Flights: #{inspect flights}")
    conn
    |> put_status(:ok)
    |> json(%{status: "ok", value: TakeOff.Flight.index()})
  end

  def add(conn, %{"type" => type, "seats" => seats}) do
    Logger.info("Adding flight: #{inspect type} #{inspect seats}")

    TakeOff.Flight.add(%{type: type, seats: seats})
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end

  def add(conn, _) do
    conn
    |> put_status(:bad_request)
    |> json(%{status: "error"})
  end

  def reset(conn, _) do
    TakeOff.Flight.reset()
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
