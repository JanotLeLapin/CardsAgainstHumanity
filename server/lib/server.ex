defmodule Server do
  use Application
  @behaviour :cowboy_websocket

  def start(_type, _args) do
    IO.puts("Starting server")

    Supervisor.start_link(
      [
        Plug.Cowboy.child_spec(
          scheme: :http,
          plug: Server.Router,
          dispatch: [
            {:_, [
              {:_, Server, []},
            ]},
          ],
          options: [port: 5000]
        ),
        Registry.child_spec(keys: :unique, name: Registry.Games)
      ],
      [strategy: :one_for_one, name: Server.Application]
    )
  end

  def init(req, _state), do: {:cowboy_websocket, req, req.path}
  def websocket_init(state) do
    # Find whether game exists for given room
    games = Registry.Games |> Registry.lookup(state)
    game = case games |> Enum.count() do
      0 ->
        # No game with given room id was found, creating a new one
        IO.puts("Creating new game with room ID: #{state}")
        {:ok, game} = Game |> GenServer.start(state)
        Registry.Games |> Registry.register(state, game)
        game
      _ ->
        # A game was found with the given room id
        {_, game} = games |> Enum.at(0)
        game
    end
    {:ok, game}
  end

  def websocket_handle({:text, json}, state) do
    payload = JSON.decode!(json)

    IO.inspect(payload)

    case payload["op"] do
      0 -> state |> Game.add_player(self(), payload["data"], true) # FIXME: UNSAFE: admin by default, that's no good!
      1 -> state |> Game.prompt()
      2 -> state |> Game.play(self(), payload["data"])
      3 -> state |> Game.reveal(self(), payload["data"])
      4 -> state |> Game.elect(self(), payload["data"])
    end

    {:ok, state}
  end

  def websocket_info({:packet, op, data}, state) do
    {:reply, {:text, JSON.encode!(%{"op" => op, "data" => data})}, state}
  end

  def terminate(_, _, state) do
    state |> Game.remove_player(self())
    :ok
  end

  defmodule Router do
    use Plug.Router

    plug :match
    plug :dispatch

    match _ do
      conn |> send_resp(200, "")
    end
  end
end
