defmodule TakeOffWeb.FlightController do
  use TakeOffWeb, :controller
  require Logger

  def index(conn, _) do
    flights = TakeOff.Flight.index()
    Logger.info("Flights: #{inspect flights}")
    conn
    |> put_status(:ok)
    |> json(%{status: "ok", value: flights})
  end

  def add(conn,
          %{
            "type" => type,
            "seats" => seats,
            "datetime" => datetime,
            "origin" => origin,
            "destination" => destination,
            "offer_duration" => offer_duration
  }) do
    Logger.info("Adding flight: #{inspect type} #{inspect seats}")

    {:ok, datetime, _} = DateTime.from_iso8601(datetime)

    TakeOff.Flight.add(
      %{
        type: type,
        seats: TakeOff.Util.keys_to_atoms(seats),
        datetime: datetime,
        origin: origin,
        destination: destination,
        offer_duration: offer_duration
      }
    )
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end

  def add(conn, _) do
    conn
    |> put_status(:bad_request)
    |> json(%{status: "error"})
  end

  def subscribe(conn, %{"id" => flight_id, "user" => user, "webhook_uri" => webhook_uri}) do
    Logger.info("Subscribing user: #{inspect user} to flight #{inspect flight_id}")

    TakeOff.Subscription.add(%{flight_id: flight_id, user: user, webhook_uri: webhook_uri})

    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end

  def flight_subscriptions(conn, %{"id" => flight_id}) do
    Logger.info("Getting subscriptions for flight #{inspect flight_id}")
    subs = TakeOff.Subscription.flight_subscriptions(flight_id)

    conn
    |> put_status(:ok)
    |> json(%{status: "ok", value: subs})
  end
end
