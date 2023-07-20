defmodule TakeOffWeb.AlertController do
  use TakeOffWeb, :controller
  require Logger

  def index(conn, _) do
    alerts = TakeOff.Alert.index()
    Logger.info("Alerts: #{inspect alerts}")
    conn
    |> put_status(:ok)
    |> json(%{status: "ok", value: alerts})
  end

  def add(conn, %{"user" => user, "date" => date, "origin" => origin, "destination" => destination, "webhook_uri" => webhook_uri}) do
    Logger.info("Adding alert: #{inspect user} #{inspect date} #{inspect origin} #{inspect destination}")

    TakeOff.Alert.add(%{user: user, date: date, origin: origin, destination: destination, webhook_uri: webhook_uri})
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
    TakeOff.Alert.reset()
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
