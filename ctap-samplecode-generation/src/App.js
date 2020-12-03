import React, { useReducer, createContext } from 'react';
import { Route } from 'react-router-dom';

import './App.css';
import Main from './Components/Main.js';
import ContextProvider from './Components/ContextProvider'

function App() {

  return (
    <ContextProvider>
      <div className="App">
        <Route exact path="/" component={Main} />
      </div>
    </ContextProvider>


  );
}

export default App;