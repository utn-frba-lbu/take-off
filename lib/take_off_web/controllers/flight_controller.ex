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

  def add(conn,
          %{
            "type" => type,
            "seats" => seats,
            "datetime" => datetime,
            "origin" => origin,
            "destiny" => destiny,
            "offer_duration" => offer_duration
  }) do
    Logger.info("Adding flight: #{inspect type} #{inspect seats}")

    # Send info to channel
    TakeOffWeb.Endpoint.broadcast!("test:flight", "new_msg", %{body: "New flight added!"})
    # TakeOffWeb.Endpoint.broadcast("test:flight", "new_msg", %{body: "New flight added!"})

    TakeOff.Flight.add(%{type: type, seats: seats, datetime: datetime, origin: origin, destiny: destiny, offer_duration: offer_duration})
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
