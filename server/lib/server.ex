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
        Registry.child_spec(keys: :duplicate, name: Registry.Server),
      ],
      [strategy: :one_for_one, name: Server.Application]
    )
  end

  def init(req, _state) do
    {:cowboy_websocket, req, %{
      "name" => nil,
      "room" => req["path"],
      "cards" => ["Foo", "Bar"],
      "tsar" => false,
      "score" => 0,
      # Only admin if he is the first player in the room
      "admin" => Enum.empty?((Registry.Server |> Registry.lookup(req["path"])))
    }}
  end

  def websocket_init(state) do
    Registry.Server |> Registry.register(state["room"], {})
    {:ok, state}
  end

  # Message from client
  # Server bound OP codes:
  # - 0 => identification packet
  # - 2 => start game request
  def websocket_handle({:text, json}, state) do
    payload = JSON.decode!(json)

    case payload["op"] do
      0 ->
        if !state["name"] do
          name = payload["name"]
          broadcast(state["room"], :new_player, %{"name" => name, "pid" => self()})
          # TODO: Random cards
          add_card(state["cards"], state |> Map.put("name", name))
        else
          {:ok, state}
        end
      2 ->
        if state["admin"] do
          prompt(state["room"], "What is your favorite color?")
        end

        {:ok, state}
    end
  end

  # Message from other process
  # Client bound OP codes:
  # - 0 => new player joined
  # - 1 => added cards
  # - 2 => prompt
  def websocket_info({op, data}, state) do
    case op do
      :tsar ->
        broadcast(state["room"], :prompt, %{"prompt" => data["prompt"], "tsar" => state["name"]}, true)
        {:ok, state}
      _ ->
        {code, json} = case op do
          :new_player ->
            pid = data["pid"]
            if pid do pid |> send({:new_player, %{"name" => state["name"]}}) end
            {0, data["name"]}
          :prompt -> {2, data}
          x -> {255, %{"op" => x, "data" => data}}
        end

        {:reply, {:text, JSON.encode!(%{"op" => code, "data" => json})}, state}
    end
  end

  defp prompt(room, prompt) do
    {pid, _} = Registry.Server |> Registry.lookup(room) |> Enum.random()
    pid |> send({:tsar, %{"prompt" => prompt}})
  end

  defp add_card(cards, state) do
    {
      :reply,
      {:text, JSON.encode!(%{"op" => 1, "data" => cards})},
      state |> Map.put("cards", state["cards"] ++ cards),
    }
  end

  defp broadcast(room, opcode, data, send_to_self \\ false) do
    each_client(room, fn pid ->
      if (pid != self() || send_to_self) do pid |> send({opcode, data}) end
    end)
  end

  defp each_client(room, f) do
    Registry.Server |> Registry.dispatch(room, fn entries ->
      for {pid, _} <- entries do f.(pid) end
    end)
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
