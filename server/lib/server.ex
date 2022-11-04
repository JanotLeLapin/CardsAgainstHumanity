defmodule Server do
  use Application
  @behaviour :cowboy_websocket

  def start(_type, _args) do
    IO.puts("Starting server")

    {:ok, _} = Server.Config |> GenServer.start_link({}, name: :config)

    Supervisor.start_link(
      [
        Plug.Cowboy.child_spec(
          scheme: :http,
          plug: Server.Router,
          dispatch: [
            {:_, [
              {"/ws/[...]", Server, []},
              {:_, Plug.Cowboy.Handler, {Server.Router, []}},
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

    if payload["op"] == 10 do {:reply, {:text, JSON.encode!(%{"op" => 10, "data" => 10})}, state} else
      case payload["op"] do
        0 -> state |> Game.add_player(self(), payload["data"])
        1 -> state |> Game.prompt()
        2 -> state |> Game.play(self(), payload["data"])
        3 -> state |> Game.reveal(self(), payload["data"])
        4 -> state |> Game.elect(self(), payload["data"])
      end

      {:ok, state}
    end
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

    plug Plug.Static,
      at: "/",
      from: "../dist"
    plug :match
    plug :dispatch

    match _, do: conn |> put_resp_content_type("text/html") |> send_file(200, "../dist/index.html")
  end
end
