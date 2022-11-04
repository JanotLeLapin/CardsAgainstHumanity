import { useParams } from '@solidjs/router';
import { Component, createSignal, For, onMount, Show } from 'solid-js';
import { Card, grid } from './components/Card';

type Message = {
  op: number;
  data: any;
}

type Player = {
  name: string;
  score: number;
  spectator: boolean;
  played: boolean;
  tsar: boolean;
}

const Game: Component = () => {
  const params = useParams();

  const [getName, setName] = createSignal<string>('Foo');
  const [isConnected, setConnected] = createSignal<boolean>(false);
  const [isAdmin, setAdmin] = createSignal<boolean>(false);
  const [getConn, setConn] = createSignal<WebSocket | null>(null);

  const [getPlayers, setPlayers] = createSignal<Player[]>([]);
  const [getCards, setCards] = createSignal<string[]>([]);
  const [getSelections, setSelections] = createSignal<string[]>([]);
  const [getWinner, setWinner] = createSignal<string | null>(null);

  const [getPrompt, setPrompt] = createSignal<string | null>(null);

  const send = (op: number, data: any) => getConn()?.send(JSON.stringify({ op, data }));
  const login = () => send(0, getName());
  const play = (card: string) => send(2, card);
  const reveal = (position: number) => send(3, position);
  const elect = (card: string) => send(4, card);

  onMount(() => {
    const endpoint = 'ws://' + (window.location.origin.includes('://localhost:') ? 'localhost:5000' : window.location.origin.replace('http://', '')) + '/ws/';
    const connection = new WebSocket(endpoint + params.room)
    setConn(connection);

    connection.onopen = () => {
      console.log('Connected!');
      setInterval(() => connection.send(JSON.stringify({ op: 10 })), 20000);
    }

    connection.onmessage = (e) => {
      const message = JSON.parse(e.data) as Message;
      console.log(message)
      switch (message.op) {
        case 0:
          const { players, admin }: { players: Player[], admin: boolean } = message.data;
          setConnected(true);
          setAdmin(admin);
          setPlayers(players);
          break;
        case 1:
          const player: string = message.data;
          setPlayers([...getPlayers(), {
            name: player,
            score: 0,
            played: false,
            spectator: true,
            tsar: false,
          } as Player]);
          break;
        case 2:
          setPlayers(getPlayers().filter(p => p.name !== message.data))
          break;
        case 3:
          const { prompt, new_cards, tsar }: { prompt: string, new_cards: string[], tsar: string } = message.data;

          setPlayers(getPlayers().map(player => {
            return {
              ...player,
              spectator: false,
              played: false,
              tsar: player.name === tsar,
            }
          }));
          setSelections([]);
          setWinner(null);
          setPrompt(prompt);
          setCards([...new_cards, ...getCards()]);
          break;
        case 4:
          const name: string = message.data;

          setSelections([...getSelections(), '']);
          setPlayers(getPlayers().map(player => {
            return {
              ...player,
              played: player.played || player.name === name,
            };
          }));
          break;
        case 5:
          const { card, pos }: { card: string, pos: number } = message.data;
          setSelections(getSelections().map((s, i) => (pos === i) ? card : s));
          break;
        case 6:
          const winner: string = message.data;
          setPlayers(getPlayers().map(player => {
            return {
              ...player,
              score: player.name === winner ? player.score + 1 : player.score,
            };
          }));
          setWinner(winner);
      }
    }
  })

  const Lobby: Component = () => {
    return <div class="fixed bottom-4 right-4">
      <Show when={isAdmin()} fallback={<h3>En attente du démarrage de la partie...</h3>}>
        <button onClick={_ => getConn()?.send(JSON.stringify({ op: 1 }))}>Démarrer la partie</button>
      </Show>
    </div>
  }

  return <div>
    <div class="fixed h-screen w-96 px-6 py-4 bg-gray-900 top-0 right-0">
      <For each={getPlayers()}>{player => <span class="flex justify-between"><p class="font-semibold">{player.name}</p> {player.score}</span>}</For>
    </div>
    <div class="mr-96">
      <Show when={isConnected()} fallback={
        <div class="h-screen grid place-items-center">
          <div class="text-center space-y-8">
            <h3>Rejoindre la partie</h3>
            <div class="flex space-x-4">
              <input type="text" onChange={e => setName((e.target as any).value)} />
              <button onClick={login}>Connexion</button>
            </div>
          </div>
        </div>
      }>
        <Show when={getPrompt()} fallback={<Lobby />}>
          <div class="m-8"><Card content={getPrompt() as string} /></div>
          <Show when={getPlayers().find(player => !player.played && !player.tsar)} fallback={
            <div class={grid}><For each={getSelections()}>{(selection, i) => <Card content={selection} onClick={() => getSelections().includes('') ? reveal(i()) : elect(selection)} />}</For></div>
          }>
            <Show when={getPlayers().find(player => player.tsar)?.name !== getName()} fallback={<h3 class="text-center">Vous êtes le Tsar, vous devez attendre que les joueurs choisissent leur carte.</h3>}>
              <div class={grid}><For each={getCards()}>{card => <Card content={card} onClick={() => play(card)} />}</For></div>
            </Show>
          </Show>
        </Show>
      </Show>
      <Show when={getWinner()}>
        <div class="fixed w-full text-center bottom-2">
          <h3>{getWinner()} remporte la partie !</h3>
        </div>
      </Show>
    </div>
  </div>;
};

export default Game;
