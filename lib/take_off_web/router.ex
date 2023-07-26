defmodule TakeOffWeb.Router do
  use TakeOffWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TakeOffWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TakeOffWeb do
    pipe_through :browser

    get "/", PageController, :home

    get "/health-check", PageController, :health_check
  end

  scope "/reservations", TakeOffWeb do
    get "/", ReservationController, :index
    post "/", ReservationController, :book
  end

  scope "/flights", TakeOffWeb do
    get "/", FlightController, :index
    post "/", FlightController, :add
    post "/:id/subscriptions",  FlightController, :subscribe
    get "/:id/subscriptions",  FlightController, :flight_subscriptions
    get "/:id/coordinator", FlightController, :coordinator_node
  end

  scope "/alerts", TakeOffWeb do
    get "/", AlertController, :index
    post "/", AlertController, :add
  end

  # Other scopes may use custom stacks.
  # scope "/api", TakeOffWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:take_off, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TakeOffWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
