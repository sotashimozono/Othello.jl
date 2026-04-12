import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import './index.css';
import { ConfigProvider } from './contexts/ConfigContext';
import { Layout } from './components/Layout';
import { GamePage } from './pages/GamePage';
import { TrainingPage } from './pages/TrainingPage';
import { TournamentPage } from './pages/TournamentPage';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <ConfigProvider>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<GamePage />} />
            <Route path="training" element={<TrainingPage />} />
            <Route path="tournament" element={<TournamentPage />} />
          </Route>
        </Routes>
      </ConfigProvider>
    </BrowserRouter>
  </StrictMode>,
);
