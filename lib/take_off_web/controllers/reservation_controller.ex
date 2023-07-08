defmodule TakeOffWeb.ReservationController do
  use TakeOffWeb, :controller
  require Logger

  # def value(conn, _params) do
  #   conn
  #   |> put_status(:ok)
  #   |> json(%{status: "ok", value: TakeOff.Reservation.value()})
  # end

  # def increment(conn, _params) do
  #   TakeOff.Reservation.increment()
  #   conn
  #   |> put_status(:ok)
  #   |> json(%{status: "ok"})
  # end
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
        seats: TakeOff.Util.keys_to_atoms(seats)
      }
    )

    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
