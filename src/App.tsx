import type { Component } from 'solid-js';

const App: Component = () => {
  return (
    <div class="h-screen grid place-items-center text-center">
      <div class="space-y-8">
        <h1>Cards Against Humanity</h1>
        <div class="grid grid-cols-[repeat(3,1fr)] gap-8 mx-4">
          <button>Créer</button>
          <button>Rejoindre</button>
          <button>Code source</button>
        </div>
      </div>
    </div>
  );
};

export default App;
