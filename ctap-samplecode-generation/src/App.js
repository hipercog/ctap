import React from 'react';
import { Route } from 'react-router-dom';

import './App.css';
import Main from './Components/Main.js';

function App() {
  return (
    <div className="App">
      <Route exact path="/" component={Main} />
    </div>
  );
}

export default App;