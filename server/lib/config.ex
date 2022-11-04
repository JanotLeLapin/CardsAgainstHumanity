defmodule Server.Config do
  @behaviour GenServer

  @spec prompt(any) :: String.t
  def prompt(any), do: GenServer.call(any, {:prompt})
  @type count :: number()
  @spec answers(any, count) :: list(String.t)
  def answers(any, count \\ 1), do: GenServer.call(any, {:answers, count})

  def init(_) do
    config = File.read!("../config.toml") |> Toml.decode!
    {:ok, config}
  end

  def handle_call({:prompt}, _, state) do
    {:reply, state["cards"]["prompts"] |> Enum.random, state}
  end

  def handle_call({:answers, count}, _, state) do
    {:reply, state["cards"]["answers"] |> Enum.take_random(count), state}
  end
end

