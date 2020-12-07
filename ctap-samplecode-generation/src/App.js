import React from 'react';
import { HashRouter, Route, Link } from "react-router-dom";

import './App.css';
import Main from './Components/Main.js';
import ContextProvider from './Components/ContextProvider'

function App() {

  return (

    <ContextProvider>
      <HashRouter basename='/'>
        <div className="App">
          <Route exact path="/" component={Main} />
        </div>
      </HashRouter>
    </ContextProvider>


  );
}

export default App;