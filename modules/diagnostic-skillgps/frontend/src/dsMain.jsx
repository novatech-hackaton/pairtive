import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import DsApp from './dsApp.jsx';
import './dsIndex.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <DsApp />
    </BrowserRouter>
  </React.StrictMode>,
);
