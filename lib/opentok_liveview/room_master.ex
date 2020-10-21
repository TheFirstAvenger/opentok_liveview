defmodule OpentokLiveview.RoomMaster do
  @moduledoc """
  state:
  %{
    rooms: [
      %{
        name: "Party Room",
        users: [
          %{
            name: "John",
            token: "abcdefg",
            pid: liveview_pid,
            stream_id: "asdf1234"
          }
        ]
      }
    ]
  }
  """
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def join_room(room_name, username, pid) do
    GenServer.call(__MODULE__, {:join_room, room_name, username, pid})
  end

  def get_rooms_and_occupancy do
    GenServer.call(__MODULE__, :get_rooms_and_occupancy)
  end

  def store_stream_id(room_name, username, stream_id) do
    GenServer.call(__MODULE__, {:store_stream_id, room_name, username, stream_id})
  end

  def init(:ok) do
    {:ok, %{rooms: []}}
  end

  def handle_call(:get_rooms_and_occupancy, _, %{rooms: rooms} = state) do
    rooms = cleanup_rooms(rooms)

    return =
      Enum.map(rooms, fn %{name: name, users: users} ->
        {name, length(users)}
      end)

    {:reply, return, %{state | rooms: rooms}}
  end

  def handle_call({:join_room, room_name, username, pid}, _, %{rooms: rooms} = state) do
    rooms = cleanup_rooms(rooms)

    {%{users: existing_users, session_id: session_id} = room, other_rooms} =
      get_or_create_room(rooms, room_name)

    existing_users
    |> Enum.find(&(&1.name == username))
    |> case do
      nil ->
        Logger.info("adding #{username} to #{room_name}")
        token = ExOpentok.Token.generate(session_id)
        users = [%{name: username, pid: pid, token: token, stream_id: nil} | existing_users]
        room = %{room | users: users}
        Enum.map(existing_users, fn %{pid: pid} -> send(pid, {:room_updated, room}) end)
        rooms = [room | other_rooms]
        {:reply, {:ok, room}, %{state | rooms: rooms}}

      _ ->
        {:reply, {:error, "user already in room"}, %{state | rooms: rooms}}
    end
  end

  def handle_call({:store_stream_id, room_name, username, stream_id}, _, %{rooms: rooms} = state) do
    rooms = cleanup_rooms(rooms)
    {[%{users: users} = room], other_rooms} = Enum.split_with(rooms, &(&1.name == room_name))

    users =
      Enum.map(users, fn
        %{name: ^username} = user -> %{user | stream_id: stream_id}
        user -> user
      end)

    room = %{room | users: users}
    Enum.map(users, &send(&1.pid, {:room_updated, room}))

    {:reply, :ok, %{state | rooms: [room | other_rooms]}}
  end

  defp get_or_create_room(rooms, room_name) do
    rooms
    |> Enum.split_with(&(&1.name == room_name))
    |> case do
      {[], _} ->
        Logger.info("creating room #{room_name}")
        {%{name: room_name, users: [], session_id: generate_session_id()}, rooms}

      {[room], other_rooms} ->
        {room, other_rooms}
    end
  end

  defp cleanup_rooms(rooms) do
    rooms
    |> Enum.map(&remove_inactive_users/1)
    |> Enum.reject(&(length(&1.users) == 0))
  end

  defp remove_inactive_users(%{users: users} = room) do
    case Enum.split_with(users, &Process.alive?(&1.pid)) do
      {_, []} ->
        room

      {active, _inactive} ->
        room = %{room | users: active}
        Enum.map(active, &send(&1.pid, {:room_updated, room}))
        room
    end
  end

  defp generate_session_id do
    %{"session_id" => session_id} = ExOpentok.init()
    session_id
  end
end
