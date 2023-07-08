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
            "id" => id,
            "type" => type,
            "seats" => seats,
            "datetime" => datetime,
            "origin" => origin,
            "destiny" => destiny,
            "offer_duration" => offer_duration
  }) do
    Logger.info("Adding flight: #{inspect id} #{inspect type} #{inspect seats}")

    TakeOff.Flight.add(%{id: id, type: type, seats: TakeOff.Util.keys_to_atoms(seats), datetime: datetime, origin: origin, destiny: destiny, offer_duration: offer_duration})
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
