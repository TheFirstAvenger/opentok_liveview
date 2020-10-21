defmodule OpentokLiveviewWeb.RoomLive do
  use OpentokLiveviewWeb, :live_view

  alias OpentokLiveview.RoomMaster

  @impl Phoenix.LiveView
  def mount(%{"room_name" => room_name, "username" => username} = _params, _session, socket) do
    socket =
      socket
      |> assign(:username, username)
      |> assign(:room_name, room_name)
      |> assign(:room, nil)

    if connected?(socket) do
      case RoomMaster.join_room(room_name, username, self()) do
        {:ok, room} ->
          {:ok, assign(socket, :room, room)}

        {:error, reason} ->
          {:ok, socket |> put_flash(:error, reason) |> redirect(to: "/")}
      end
    else
      {:ok, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:room_updated, room}, socket) do
    {:noreply, assign(socket, :room, room)}
  end

  @impl Phoenix.LiveView
  def handle_event("get_publish_info", _, socket) do
    %{token: token} = get_me(socket)
    {:reply, %{key: get_key(), token: token, session_id: socket.assigns.room.session_id}, socket}
  end

  def handle_event("store_stream_id", %{"stream_id" => stream_id}, socket) do
    RoomMaster.store_stream_id(socket.assigns.room_name, socket.assigns.username, stream_id)
    {:noreply, socket}
  end

  defp get_key, do: Application.fetch_env!(:ex_opentok, :key)

  def get_me(%{assigns: %{room: room, username: username}}), do: user_in_room(room, username)

  defp user_in_room(%{users: users}, username), do: Enum.find(users, &(&1.name == username))
  defp others_in_room(%{users: users}, username), do: Enum.reject(users, &(&1.name == username))
end
