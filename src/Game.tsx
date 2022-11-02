import { useParams } from '@solidjs/router';
import { Component, createSignal, For, onMount } from 'solid-js';
import { Card, grid } from './components/Card';

type Message = {
  op: number;
  data: any;
}

const Game: Component = () => {
  const params = useParams();

  const [getConn, setConn] = createSignal<WebSocket | null>(null);

  const [getCards, setCards] = createSignal<string[]>([])

  onMount(() => {
    const connection = new WebSocket(`ws://localhost:5000/${params.room}`)
    setConn(connection);

    connection.onopen = () => {
      connection.send(JSON.stringify({
        "op": 0,
        "name": "Foo",
      }));
    }

    connection.onmessage = (e) => {
      const message = JSON.parse(e.data) as Message;
      switch (message.op) {
        case 1:
          setCards(message.data)
          break;
      }
    }
  })
  return <div>
    <div class={grid}>
      <For each={getCards()}>
        {card => <Card content={card} />}
      </For>
    </div>
  </div>;
};

export default Game;

