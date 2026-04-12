import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import type { ReactNode } from 'react';
import type { Config, PanelName } from '../types';
import { fetchConfig as apiFetchConfig } from '../api';

const STORAGE_KEY = 'reversi-panel-overrides';

type ConfigContextValue = {
  config: Config | null;
  panelVisible: (name: PanelName) => boolean;
  setPanelVisible: (name: PanelName, visible: boolean) => void;
  isFancy: boolean;
  setIsFancy: (v: boolean) => void;
};

const ConfigContext = createContext<ConfigContextValue | null>(null);

function loadPanelOverrides(): Partial<Record<PanelName, boolean>> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function savePanelOverrides(overrides: Partial<Record<PanelName, boolean>>) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(overrides));
}

export function ConfigProvider({ children }: { children: ReactNode }) {
  const [config, setConfig] = useState<Config | null>(null);
  const [panelOverrides, setPanelOverrides] = useState<Partial<Record<PanelName, boolean>>>(loadPanelOverrides);
  const [isFancy, setIsFancy] = useState(true);

  useEffect(() => {
    apiFetchConfig().then((data) => {
      setConfig(data);
      if (data.web) setIsFancy(data.web.fancy_mode);
    }).catch((err) => console.error('Failed to fetch config:', err));
  }, []);

  // Apply color CSS variables
  useEffect(() => {
    if (!config) return;
    const root = document.documentElement;
    const c = config.colors;
    if (c) {
      root.style.setProperty('--color-board', c.board || '#0d6b24');
      root.style.setProperty('--color-grid', c.grid || '#054712');
      root.style.setProperty('--color-black-piece', c.black_piece || '#121217');
      root.style.setProperty('--color-white-piece', c.white_piece || '#f0f0f4');
      root.style.setProperty('--color-board-light', (c.board || '#0d6b24') + 'cc');
    }
  }, [config]);

  const panelVisible = useCallback((name: PanelName): boolean => {
    if (name in panelOverrides) return panelOverrides[name]!;
    return config?.web?.panels?.[name] ?? false;
  }, [config, panelOverrides]);

  const setPanelVisible = useCallback((name: PanelName, visible: boolean) => {
    setPanelOverrides((prev) => {
      const next = { ...prev, [name]: visible };
      savePanelOverrides(next);
      return next;
    });
  }, []);

  return (
    <ConfigContext.Provider value={{ config, panelVisible, setPanelVisible, isFancy, setIsFancy }}>
      {children}
    </ConfigContext.Provider>
  );
}

export function useConfig(): ConfigContextValue {
  const ctx = useContext(ConfigContext);
  if (!ctx) throw new Error('useConfig must be used within ConfigProvider');
  return ctx;
}
