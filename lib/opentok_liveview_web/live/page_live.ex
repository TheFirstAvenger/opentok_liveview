defmodule OpentokLiveviewWeb.PageLive do
  use OpentokLiveviewWeb, :live_view

  alias OpentokLiveview.RoomMaster

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:rooms, RoomMaster.get_rooms_and_occupancy())
      |> assign(:username, nil)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("set_username", %{"set_username" => %{"username" => username}}, socket) do
    {:noreply, assign(socket, :username, nil_if_empty(username))}
  end

  @impl Phoenix.LiveView
  def handle_event("create_room", %{"create_room" => %{"room_name" => room_name}}, socket) do
    go_to_room(socket, room_name)
  end

  @impl Phoenix.LiveView
  def handle_event("join_room", %{"room_name" => room_name}, socket) do
    go_to_room(socket, room_name)
  end

  defp go_to_room(socket, room_name) do
    socket =
      push_redirect(socket,
        to: Routes.room_path(socket, :index, room_name, socket.assigns.username)
      )

    {:noreply, socket}
  end

  defp nil_if_empty(""), do: nil
  defp nil_if_empty(v), do: v
end
