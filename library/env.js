// The toolbar's environment, applied to a page (the library and each framed screen).
import { PAINTINGS } from './pieces.js';

export const CONTROLS = [
  { key: 'painting', label: 'Painting', type: 'select', default: 'sunny-day', options: Object.entries(PAINTINGS).map(([k, [t]]) => [k, t]) },
  { key: 'glass', label: 'Glass', type: 'range', min: 0.1, max: 0.7, step: 0.02, default: 0.32 },
  { key: 'wash', label: 'Wash', type: 'range', min: 0, max: 0.6, step: 0.05, default: 0.2 },
  { key: 'blobs', label: 'Blobs', type: 'seg', default: 'drift', options: [['drift', 'Drift'], ['still', 'Still'], ['off', 'Off']] },
  { key: 'cycling', label: 'Cycle sizes', type: 'toggle', default: true },
  { key: 'reduceMotion', label: 'Reduce motion', type: 'toggle', default: false },
];

export function applyEnv(env, doc = document) {
  const root = doc.documentElement;
  root.style.setProperty('--glass', env.glass);
  root.style.setProperty('--wash', env.wash);
  root.style.setProperty('--painting', `url(${PAINTINGS[env.painting]?.[1] || PAINTINGS['sunny-day'][1]})`);
  root.classList.toggle('blobs-still', env.blobs === 'still');
  root.classList.toggle('blobs-off', env.blobs === 'off');
  root.classList.toggle('reduce-motion', !!env.reduceMotion);
}
