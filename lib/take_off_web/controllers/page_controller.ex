defmodule TakeOffWeb.PageController do
  use TakeOffWeb, :controller
  require Logger

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def health_check(conn, _params) do
    Logger.info("Health check")

    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end
end
