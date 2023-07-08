defmodule TakeOffWeb.ReservationController do
  use TakeOffWeb, :controller
  require Logger

  def index(conn, _) do
    bookings = TakeOff.Reservation.index()
    Logger.info("Reservation: #{inspect bookings}")
    conn
    |> put_status(:ok)
    |> json(%{status: "ok", value: bookings})
  end

  def book(conn,
    %{
      "user" => user,
      "flight_id" => flight_id,
      "seats" => seats
    }
  ) do
    Logger.info("booking: #{inspect seats}")
    TakeOff.Reservation.confirm_reservartion(
      %{
        user: user,
        flight_id: flight_id,
        seats: seats
      }
    )

    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
