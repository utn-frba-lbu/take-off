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
    response = TakeOff.Reservation.book(
      %{
        user: user,
        flight_id: flight_id,
        seats: TakeOff.Util.keys_to_atoms(seats)
      }
    )

    Logger.info("response: #{inspect response}")

    conn
    |> put_status(
      case response.status do
        :booking_accepted -> :ok
        :flight_not_found -> :not_found
        :booking_denied -> :unprocessable_entity
        :flight_closed -> :unprocessable_entity
        _ -> :internal_server_error
      end
    )
    |> json(response)
  end
end
