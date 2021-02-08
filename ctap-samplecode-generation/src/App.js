import React from 'react';
import { HashRouter, Route } from "react-router-dom";

import './App.css';
import Main from './Components/Main.js';
import IntroPage from './Components/IntroPage';
import ContextProvider from './Reducers/ContextProvider'
import Typography from "@material-ui/core/Typography";


function App() {

  return (

    <ContextProvider>
      <HashRouter basename='/'>
        <Typography variant='h2' align="center" style={{marginTop: '2rem'}}>CTAP Code Generation Tool</Typography>
        <div className="App">
          <Route exact path="/" component={IntroPage} />
          <Route path='/start' component={Main} />
        </div>
      </HashRouter>
    </ContextProvider>


  );
}

export default App;