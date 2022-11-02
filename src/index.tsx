import { lazy } from 'solid-js';
import { render } from 'solid-js/web';
import { Route, Router, Routes } from '@solidjs/router';

const Home = lazy(() => import('./Home'))
const Game = lazy(() => import('./Game'))

import './index.css';

render(() =>
  <Router>
    <Routes>
      <Route path="/" component={Home} />
      <Route path="/:room" component={Game} />
    </Routes>
  </Router>,
  document.getElementById('root') as HTMLElement
);
