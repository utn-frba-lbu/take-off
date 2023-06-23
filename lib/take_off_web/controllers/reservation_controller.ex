defmodule TakeOffWeb.ReservationController do
  use TakeOffWeb, :controller
  require Logger

  def value(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok", value: TakeOff.Reservation.value()})
  end

  def increment(conn, _params) do
    TakeOff.Reservation.increment()
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
