import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { MotionConfig } from 'motion/react';
import '@fontsource/inter/400.css';
import '@fontsource/inter/500.css';
import '@fontsource/inter/600.css';
import '@fontsource/plus-jakarta-sans/600.css';
import '@fontsource/plus-jakarta-sans/700.css';
import '@fontsource/plus-jakarta-sans/800.css';
import './amIndex.css';
import AmApp from './amApp.jsx';
import { AmAuthProvider } from './lib/amAuth.jsx';
import { AmToaster } from './components/amToast.jsx';

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <MotionConfig reducedMotion="user">
      <BrowserRouter>
        <AmAuthProvider>
          <AmApp />
          <AmToaster />
        </AmAuthProvider>
      </BrowserRouter>
    </MotionConfig>
  </StrictMode>,
);
