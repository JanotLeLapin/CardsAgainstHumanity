import { A } from '@solidjs/router';
import type { Component } from 'solid-js';
import { roomName } from './lib/util';

const App: Component = () => {
  return (
    <div class="h-screen grid place-items-center text-center">
      <div class="space-y-8">
        <h1>Cards Against Humanity</h1>
        <div class="grid grid-cols-[repeat(3,1fr)] gap-8 mx-4">
          <A href={`/${roomName()}`}><button class="w-full">Créer</button></A>
          <button>Rejoindre</button>
          <a href="https://github.com/JanotLeLapin/CardsAgainstHumanity" about="_blank"><button class="w-full">Code source</button></a>
        </div>
      </div>
    </div>
  );
};

export default App;
