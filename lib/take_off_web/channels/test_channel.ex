defmodule TakeOffWeb.TestChannel do
  use Phoenix.Channel
  require Logger

  def join("test:flight", message, socket) do
    Logger.info("Joining test:flight #{inspect(message)}")
    {:ok, socket}
  end

  def join("test:flight", message) do
    Logger.info("Joining test:flight #{inspect(message)}")
    {:ok, message}
  end

  def join("test:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("test:flight", %{"body" => body}, socket) do
    Logger.info("handle_in test:flight #{inspect(body)}")
    broadcast!(socket, "new_msg", %{body: body})
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    Logger.info("handle_in new_msg #{inspect(body)}")
    broadcast!(socket, "new_msg", %{body: body})
    {:noreply, socket}
  end

  intercept ["new_msg", "user_joined"]

  # do not send broadcasted `"user_joined"` events if this socket's user
  # is ignoring the user who joined.
  def handle_out("new_msg", msg, socket) do
    Logger.info("handle_out new_msg #{inspect(msg)}")
    # unless User.ignoring?(socket.assigns[:user], msg.user_id) do
    push(socket, "user_joined", msg)
    # end
    {:noreply, socket}
  end

  # def handle_in("new_msg", %{"body" => body}, socket) do
  #   broadcast!(socket, "new_msg", %{body: body})
  #   {:noreply, socket}
  # end
end
