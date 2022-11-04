# OP Codes
#
# Client bound:
# - 0 -> authorized
# - 1 -> player joined
# - 2 -> player left
# - 3 -> prompt
# - 4 -> card played
# - 5 -> card revealed
# - 6 -> winner elected
#
# Server bound:
# - 0 -> authorization
# - 1 -> start game request
# - 2 -> play card
# - 3 -> reveal card
# - 4 -> elect card
defmodule Game do
  @behaviour GenServer

  def add_player(game, pid, name, admin \\ false), do: game |> GenServer.cast({:add, pid, name, admin})
  def remove_player(game, pid), do: game |> GenServer.cast({:remove, pid})
  def broadcast(game, fun), do: game |> GenServer.cast({:broadcast, fun})
  def prompt(game), do: game |> GenServer.cast({:prompt})
  def play(game, pid, card), do: game |> GenServer.cast({:play, pid, card})
  def reveal(game, pid, pos), do: game |> GenServer.cast({:reveal, pid, pos})
  def elect(game, pid, card), do: game |> GenServer.cast({:elect, pid, card})

  @impl true
  def init(room) do
    {:ok, %{
      "players" => [],
      "prompt" => nil,
      "room" => room,
    }}
  end

  @impl true
  def handle_cast({:add, pid, name, admin}, state) do
    # Make sure the given player is not already authenticated
    if state["players"] |> Enum.find(fn player -> player["pid"] == pid end) != nil do
      {:noreply, state}
    else
      # Send new player packet to every player
      state["players"] |> Enum.each(fn player ->
        player["pid"] |> send({:packet, 1, name})
      end)

      players = [%{
        "pid" => pid,
        "name" => name,
        "score" => 0,
        "cards" => [],
        "selected" => nil,
        "revealed" => false,
        "tsar" => false,
        "admin" => admin,
        "spectator" => true,
      } | state["players"]]

      IO.inspect(players)

      # Send current player list to new player
      pid |> send({:packet, 0, players |> Enum.map(fn player -> %{
        "name" => player["name"],
        "score" => player["score"],
        "spectator" => player["spectator"],
        "played" => player["selected"] != nil,
        "tsar" => player["tsar"],
      } end)})

      {:noreply, state |> Map.put("players", players)}
    end
  end

  @impl true
  def handle_cast({:broadcast, fun}, state) do
    state["players"] |> Enum.each(fun)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove, pid}, state) do
    # Find name of removed player
    name = state["players"] |> Enum.find(fn player -> player["pid"] == pid end)

    # Filter out removed player
    players = state["players"] |> Enum.filter(fn player ->
      if player["pid"] != pid do
        # Send left player packet
        player["pid"] |> send({:packet, 2, name})
        true
      else
        false
      end
    end)
    {:noreply, state |> Map.put("players", players)}
  end

  @impl true
  def handle_cast({:prompt}, state) do
    prompt = :config |> Server.Config.prompt
    next_tsar = state["players"] |> Enum.random()
    players = state["players"] |> Enum.map(fn player ->
      card_count = player["cards"] |> Enum.count
      new_cards = if player["tsar"], do: [], else: :config |> Server.Config.answers(7 - card_count)

      # Send prompt packet to player
      player["pid"] |> send({:packet, 3, %{
        "tsar" => next_tsar["name"],
        "new_cards" => new_cards,
        "prompt" => prompt
      }})

      player
        # Reset selected card and tsar property for the next round
        |> Map.put("selected", nil)
        |> Map.put("tsar", player["pid"] == next_tsar["pid"])
        |> Map.put("cards", player["cards"] ++ new_cards)
        |> Map.put("spectator", false)
    end)

    {:noreply, state
      |> Map.put("players", players)
      |> Map.put("prompt", prompt)
    }
  end

  @impl true
  def handle_cast({:play, pid, card}, state) do
    sender = state["players"] |> Enum.find(fn player -> player["pid"] == pid end)
    players = state["players"] |> Enum.map(fn player ->
      player["pid"] |> send({:packet, 4, sender["name"]})
      if player["pid"] == pid, do: player |> Map.put("selected", card), else: player
    end)
    {:noreply, state |> Map.put("players", players)}
  end

  @impl true
  def handle_cast({:reveal, pid, pos}, state) do
    # Did all players select a card
    if state["players"] |> Enum.find(fn player -> !player["selected"] && !player["tsar"] && !player["spectator"] end) do {:noreply, state} else
      # Is sender the tsar
      sender = state["players"] |> Enum.find(fn player -> player["pid"] == pid end)
      if !sender["tsar"] do {:noreply, state} else
        # Find first non-revealed card
        revealed = state["players"] |> Enum.find(fn player -> !player["revealed"] && !player["tsar"] && !player["spectator"] end)
        if !revealed do {:noreply, state} else
          players = state["players"] |> Enum.map(fn player ->
            player["pid"] |> send({:packet, 5, %{
              "card" => revealed["selected"],
              "pos" => pos,
            }})
            if player["pid"] == revealed["pid"], do: player |> Map.put("revealed", true), else: player
          end)
          {:noreply, state |> Map.put("players", players)}
        end
      end
    end
  end

  @impl true
  def handle_cast({:elect, pid, card}, state) do
    # Was sender the tsar
    sender = state["players"] |> Enum.find(fn player -> player["pid"] == pid end)
    if !sender["tsar"] do {:noreply, state} else
      # Were all the cards revealed
      if state["players"] |> Enum.find(fn player -> !player["revealed"] && !player["tsar"] && !player["spectator"] end) do {:noreply, state} else
        # Find winner
        winner = state["players"] |> Enum.find(fn player -> player["selected"] == card end)
        if !winner do {:noreply, state} else
          state["players"] |> Enum.each(fn player ->
            player["pid"] |> send({:packet, 6, winner["name"]})
          end)
          players = state["players"] |> Enum.map(fn player -> if player["name"] == winner["name"], do: player |> Map.put("score", player["score"] + 1), else: player end)
          {:noreply, state |> Map.put("players", players)}
        end
      end
    end
  end
end
