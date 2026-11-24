// Snappl's pieces as HTML renditions. Data mirrors Sources/Snappl/SnapAction.swift;
// keep the two in step when actions, shortcuts or labels change.

export const ACTIONS = [
  { id: 'leftHalf', title: 'Left Half', keys: '⌥⌘←', region: [0, 0, 50, 100], axis: 'width' },
  { id: 'rightHalf', title: 'Right Half', keys: '⌥⌘→', region: [50, 0, 50, 100], axis: 'width' },
  { id: 'topHalf', title: 'Top Half', keys: '⌥⌘↑', region: [0, 0, 100, 50], axis: 'height' },
  { id: 'bottomHalf', title: 'Bottom Half', keys: '⌥⌘↓', region: [0, 50, 100, 50], axis: 'height' },
  { id: 'topLeft', title: 'Top Left', keys: '⌃⌘←', region: [0, 0, 50, 50], axis: 'width' },
  { id: 'topRight', title: 'Top Right', keys: '⌃⌘→', region: [50, 0, 50, 50], axis: 'width' },
  { id: 'bottomLeft', title: 'Bottom Left', keys: '⌃⇧⌘←', region: [0, 50, 50, 50], axis: 'width' },
  { id: 'bottomRight', title: 'Bottom Right', keys: '⌃⇧⌘→', region: [50, 50, 50, 50], axis: 'width' },
  { id: 'maximise', title: 'Maximise', keys: '⌥⌘F', region: [0, 0, 100, 100], axis: 'none' },
  { id: 'centre', title: 'Centre', keys: '⌥⌘C', region: [20, 15, 60, 70], axis: 'none' },
  { id: 'nextDisplay', title: 'Next Display', keys: '⌃⌥⌘→', region: [60, 0, 40, 100], axis: 'none' },
  { id: 'previousDisplay', title: 'Previous Display', keys: '⌃⌥⌘←', region: [0, 0, 40, 100], axis: 'none' },
  { id: 'restore', title: 'Restore', keys: '⌥⌘Z', region: [28, 22, 44, 56], axis: 'none' },
];
export const byId = Object.fromEntries(ACTIONS.map((a) => [a.id, a]));
export const MENU_SECTIONS = [['leftHalf', 'rightHalf', 'topHalf', 'bottomHalf'], ['topLeft', 'topRight', 'bottomLeft', 'bottomRight'], ['maximise', 'centre'], ['nextDisplay', 'previousDisplay', 'restore']];
export const SETTINGS_SECTIONS = [['leftHalf', 'rightHalf', 'topHalf', 'bottomHalf'], ['topLeft', 'topRight', 'bottomLeft', 'bottomRight'], ['maximise', 'centre', 'nextDisplay', 'previousDisplay', 'restore']];
export const CYCLE = [1 / 2, 2 / 3, 1 / 3];
export const PAINTINGS = {
  'sunny-day': ['Sunny Day', 'assets/sunny-day.jpg'],
  moonrise: ['Moonrise, Beaumaris', 'assets/moonrise.jpg'],
  'passing-trams': ['Passing Trams', 'assets/passing-trams.jpg'],
  'winter-night': ['Yarra Winter Night, 1929', 'assets/winter-night.jpg'],
};

// ---------- Small pieces ----------

export function glyph(region, scale = 1) {
  const [l, t, w, h] = region;
  const n = (v) => +v.toFixed(2);
  return `<svg class="sp-glyph" width="${16 * scale}" height="${12 * scale}" viewBox="0 0 16 12" aria-hidden="true"><rect x="0.75" y="0.75" width="14.5" height="10.5" rx="2.5" fill="none" stroke="currentColor" stroke-width="1.25"/><rect x="${n(2.5 + l * 0.11)}" y="${n(2.5 + t * 0.07)}" width="${n(w * 0.11)}" height="${n(h * 0.07)}" rx="1" fill="currentColor"/></svg>`;
}

export const keycaps = (keys, opts = {}) => `<span class="sp-keys" style="${opts.lg ? 'gap:6px' : ''}">${[...keys].map((k) => `<span class="sp-key ${opts.lg ? 'lg' : ''} ${opts.pressed ? 'pressed' : ''}">${k}</span>`).join('')}</span>`;
export const switchEl = (on) => `<span class="sp-switch ${on ? 'on' : ''}" role="switch" aria-checked="${on}"></span>`;
export const tabs = (selected) => `<span class="sp-tabs">${['Shortcuts', 'General'].map((t) => `<span class="sp-tab ${t === selected ? 'on' : ''}">${t}</span>`).join('')}</span>`;
export const pill = (label, disabled) => `<span class="sp-pill ${disabled ? 'disabled' : ''}">${label}</span>`;
export const inkButton = (label, lg) => `<span class="sp-ink ${lg ? 'lg' : ''}">${label}</span>`;
export const wallLabel = (title, artist = 'Clarice Beckett') => `<span class="sp-chip sp-wall"><i>${title}</i><span>${artist}</span></span>`;
export const blobs = () => '<div class="sp-blobs" aria-hidden="true"><span class="sp-blob a"></span><span class="sp-blob b"></span><span class="sp-blob c"></span></div>';
export const painted = (inner, style = '', painting) =>
  `<div class="sp sp-ground" style="${painting ? `--painting:url(${PAINTINGS[painting][1]});` : ''}${style}">${blobs()}<div class="sp-content">${inner}</div></div>`;

// ---------- Shortcut row ----------

export function shortcutRow(action, state = 'rest') {
  const a = byId[action];
  const control = {
    rest: keycaps(a.keys), hover: keycaps(a.keys),
    recording: '<span class="sp-record">Type a shortcut…</span>',
    refused: '<span class="sp-record">Add ⌘, ⌥ or ⌃</span>',
    empty: '<span class="sp-empty">Record shortcut</span>',
  }[state];
  return `<div class="sp-row ${state === 'hover' ? 'hover' : ''}">${glyph(a.region)}<span class="label">${a.title}</span>${control}<span class="sp-clear" aria-hidden="true">✕</span></div>`;
}

export const settingRow = (title, detail, accessory) =>
  `<div class="sp-setting"><span class="text"><b>${title}</b>${detail ? `<small>${detail}</small>` : ''}</span>${accessory}</div>`;

// ---------- Menu ----------

export function menu(state = 'normal', highlight = 'leftHalf') {
  const item = (a) => `<div class="sp-mi ${a.id === highlight ? 'hl' : ''}">${glyph(a.region)}<span class="label">${a.title}</span><span class="kb">${a.keys}</span></div>`;
  const top = state === 'no-access'
    ? '<div class="sp-mi indent"><span class="label">Allow Snappl in Accessibility…</span></div><div class="sp-sep"></div>'
    : state === 'taken' ? '<div class="sp-mi indent dim"><span class="label">Some shortcuts are taken by another app</span></div><div class="sp-sep"></div>' : '';
  return `<div class="sp sp-menu" role="menu">${top}${MENU_SECTIONS.map((s) => s.map((id) => item(byId[id])).join('')).join('<div class="sp-sep"></div>')}
    <div class="sp-sep"></div><div class="sp-mi indent"><span class="label">Settings…</span><span class="kb">⌘,</span></div>
    <div class="sp-mi indent"><span class="label">Quit Snappl</span><span class="kb">⌘Q</span></div></div>`;
}

// ---------- Snap pop-up ----------

export function popupLabel(a, step) {
  const s = step % 3;
  if (/Half$/.test(a.title)) { const side = a.title.replace(' Half', ''); return [`${side} half`, `${side} two thirds`, `${side} third`][s]; }
  if (['topLeft', 'topRight', 'bottomLeft', 'bottomRight'].includes(a.id)) { const c = a.title[0] + a.title.slice(1).toLowerCase(); return [c, `${c} · ⅔`, `${c} · ⅓`][s]; }
  if (a.id === 'nextDisplay') return 'Next display';
  if (a.id === 'previousDisplay') return 'Previous display';
  return a.title;
}

// The window's region on screen after this step, as fractions (x, y, w, h).
export function snapRegion(a, step, cycling = true) {
  const f = cycling && a.axis !== 'none' ? CYCLE[step % 3] : 0.5;
  switch (a.id) {
    case 'leftHalf': return [0, 0, f, 1];
    case 'rightHalf': return [1 - f, 0, f, 1];
    case 'topHalf': return [0, 0, 1, f];
    case 'bottomHalf': return [0, 1 - f, 1, f];
    case 'topLeft': return [0, 0, f, 0.5];
    case 'topRight': return [1 - f, 0, f, 0.5];
    case 'bottomLeft': return [0, 0.5, f, 0.5];
    case 'bottomRight': return [1 - f, 0.5, f, 0.5];
    case 'maximise': return [0, 0, 1, 1];
    case 'centre': return [0.2, 0.15, 0.6, 0.7];
    case 'restore': return [0.28, 0.22, 0.44, 0.56];
    default: return [0.12, 0.1, 0.6, 0.75];
  }
}

export function miniDisplay(region, axis = 'none') {
  const [x, y, w, h] = region;
  const guides = axis === 'width' ? [1 / 3, 1 / 2, 2 / 3].map((g) => `<span class="guide" style="left:${4 + 88 * g}px;top:6px;bottom:6px;width:1px"></span>`).join('')
    : axis === 'height' ? [1 / 3, 1 / 2, 2 / 3].map((g) => `<span class="guide" style="top:${4 + 54 * g}px;left:6px;right:6px;height:1px"></span>`).join('') : '';
  const fw = Math.max(88 * w, 2), fh = Math.max(54 * h, 2);
  return `<div class="sp-display">${guides}<span class="fill" style="left:${4 + 88 * x}px;top:${4 + 54 * y}px;width:${fw}px;height:${fh}px;border-radius:${Math.min(7, fw / 2, fh / 2)}px"></span></div>`;
}

export function popup(action, step = 0, cycling = true) {
  const a = byId[action];
  const axis = cycling ? a.axis : 'none';
  const dots = axis !== 'none' ? `<div class="sp-dots">${[0, 1, 2].map((i) => `<span class="sp-dot ${i === step % 3 ? 'on' : ''}"></span>`).join('')}</div>` : '';
  return `<div class="sp sp-popup" role="status" data-action="${action}" data-step="${step}">${miniDisplay(snapRegion(a, step, cycling), axis)}
    <div style="display:flex;flex-direction:column;align-items:center;gap:9px"><span class="name">${cycling ? popupLabel(a, step) : popupLabel(a, 0)}</span>${dots}</div></div>`;
}

// ---------- Screens ----------

export function settingsWindow({ pane = 'Shortcuts', recording = null, hover = null, cleared = [], trusted = true, login = true, showPopup = true, cycling = true, painting = 'sunny-day' } = {}) {
  const head = `<div style="display:flex;gap:8px;padding:16px 20px 0" class="sp-lights"><i></i><i></i><i></i></div>
    <div style="display:flex;align-items:center;justify-content:space-between;padding:12px 24px 4px"><b style="font-size:22px;line-height:28px;font-weight:600;letter-spacing:-0.4px">${pane}</b>${tabs(pane)}</div>`;
  let body;
  if (pane === 'Shortcuts') {
    const state = (id) => (id === recording ? 'recording' : cleared.includes(id) ? 'empty' : id === hover ? 'hover' : 'rest');
    body = SETTINGS_SECTIONS.map((s) => `<div class="sp-glass sp-list">${s.map((id) => shortcutRow(id, state(id))).join('')}</div>`).join('')
      + `<div class="sp-glass">${settingRow('Cycle sizes on repeat', 'Press a half again for ⅔, then ⅓', switchEl(cycling))}</div>`;
  } else {
    body = `<div class="sp-glass" style="padding:4px 0">${settingRow('Open at login', '', switchEl(login))}<div class="sp-divider"></div>
      ${settingRow('Show snap pop-up', 'The glass tile that shows where the window went', switchEl(showPopup))}<div class="sp-divider"></div>
      ${settingRow('Accessibility', trusted ? 'Allowed. Snappl can move windows.' : 'Needed to move other apps’ windows', trusted ? '' : pill('Open Settings'))}</div>`;
  }
  const foot = `<div style="position:absolute;left:20px;right:20px;bottom:20px;display:flex;justify-content:space-between;align-items:flex-end">${wallLabel(PAINTINGS[painting][0])}${pane === 'Shortcuts' ? pill('Restore Spectacle defaults', cleared.length === 0) : ''}</div>`;
  return painted(`<div style="height:740px;position:relative">${head}<div style="display:flex;flex-direction:column;gap:12px;padding:8px 20px">${body}</div>${foot}</div>`, 'width:600px;height:740px;border-radius:12px', painting);
}

export function desktop(inner, { menuOpen = false, w = 960, h = 600 } = {}) {
  return `<div class="sp sp-desktop" style="width:${w}px;height:${h}px">
    <div class="sp-menubar"><b>Notes</b><span>File</span><span>Edit</span><span class="right"><span class="sp-statusitem ${menuOpen ? 'open' : ''}">${glyph([0, 0, 50, 100])}</span><span>Tue 24 Nov 9:41</span></span></div>
    ${inner}<span style="position:absolute;left:12px;bottom:10px;font-size:11px;color:rgba(255,255,255,0.8)">Stand-in wallpaper: the real pop-up and menu float over the user's own</span></div>`;
}

export function popupOnDesktop({ action = 'leftHalf', step = 1, cycling = true } = {}) {
  const [x, y, w, h] = snapRegion(byId[action], step, cycling);
  const W = 960, H = 600, top = 30, pad = 6, aw = W - pad * 2, ah = H - top - pad;
  const win = `<div style="position:absolute;left:${pad + aw * x}px;top:${top + ah * y}px;width:${aw * w}px;height:${ah * h}px;transition:all 240ms var(--ease)" class="sp-window"><div style="height:100%;background:rgba(250,250,250,0.92);padding:14px" ><div class="sp-lights"><i></i><i></i><i></i></div></div></div>`;
  return desktop(`${win}<div style="position:absolute;left:50%;top:${top + ah / 2}px;transform:translate(-50%,-50%);z-index:4">${popup(action, step, cycling)}</div>`, { w: W, h: H });
}

export function menuOnDesktop(state = 'normal') {
  return desktop(`<div style="position:absolute;top:30px;right:96px;z-index:4">${menu(state)}</div>`, { menuOpen: true, h: 520 });
}

export function firstRun(step = 'ask', pressed = 0) {
  const sheet = step === 'ask'
    ? `<div style="width:44px;height:44px;border-radius:12px;background:rgba(255,255,255,0.8);display:flex;align-items:center;justify-content:center">${glyph([0, 0, 50, 100], 1.5)}</div>
       <div><b style="display:block;font-size:24px;line-height:29px;letter-spacing:-0.4px;margin-bottom:8px">Let Snappl move your windows</b>
       <p style="margin:0;font-size:14px;line-height:22px;color:var(--ink-2)">macOS asks before any app can move another app’s windows. Snappl only moves and resizes them. It never reads what’s inside.</p></div>
       <div style="display:flex;justify-content:space-between;align-items:center"><small style="color:var(--ink-3);font-size:12px">Waiting for access</small>${inkButton('Open Accessibility Settings', true)}</div>`
    : `<div><small style="font-size:12px;font-weight:500;color:var(--ink-2)">✓ Access granted</small><b style="display:block;font-size:24px;line-height:29px;letter-spacing:-0.4px;margin:8px 0">Now try it</b>
       <p style="margin:0;font-size:14px;line-height:22px;color:var(--ink-2)">Once for half. Again for two thirds, again for a third.</p></div>
       <div style="display:flex;justify-content:space-between;align-items:center;padding:18px 20px;border-radius:16px;background:rgba(255,255,255,0.35)">${keycaps('⌥⌘←', { lg: true, pressed: pressed > 0 })}
         <span style="display:flex;align-items:center;gap:14px"><b style="font-size:13px">${pressed ? popupLabel(byId.leftHalf, pressed - 1).replace('Left ', '').replace(/^./, (c) => c.toUpperCase()) : 'Full screen'}</b>${miniDisplay(pressed ? snapRegion(byId.leftHalf, pressed - 1) : [0, 0, 1, 1])}</span></div>
       ${settingRow('Show icon in menu bar', '', switchEl(true))}${settingRow('Open at login', '', switchEl(true))}
       <div style="display:flex;justify-content:flex-end">${inkButton('Done')}</div>`;
  return painted(`<div style="padding:56px 32px 32px;height:540px;box-sizing:border-box"><div class="sp-lights" style="position:absolute;top:16px;left:16px"><i></i><i></i><i></i></div>
    <div class="sp-glass" style="padding:28px;border-radius:22px;display:flex;flex-direction:column;gap:20px">${sheet}</div>
    <span style="position:absolute;left:16px;bottom:16px">${wallLabel('Yarra Winter Night, 1929')}</span></div>`, 'width:600px;height:540px;border-radius:12px', 'winter-night');
}

export function installWindow() {
  return `<div class="sp sp-window" style="width:640px;background:#f3f2f0">
    <div style="height:28px;display:flex;align-items:center;justify-content:center;position:relative;box-shadow:inset 0 -0.5px 0 rgba(0,0,0,0.12)"><span class="sp-lights" style="position:absolute;left:12px"><i></i><i></i><i></i></span><b style="font-size:13px;color:var(--ink-2)">Snappl</b></div>
    <div style="position:relative;width:640px;height:400px;background:url(assets/dmg-background.png) 0 0 / 640px 400px">
      <div style="position:absolute;left:106px;top:136px;width:128px;text-align:center"><img src="assets/app-icon.png" alt="" style="width:128px;height:128px"><div style="font-size:13px;margin-top:4px">Snappl</div></div>
      <div style="position:absolute;left:406px;top:136px;width:128px;text-align:center"><div style="width:128px;height:128px;display:flex;align-items:center;justify-content:center;font-size:12px;color:var(--ink-3)">(Finder draws<br>the folder)</div><div style="font-size:13px;margin-top:4px">Applications</div></div>
    </div></div>`;
}

export function renderScreen(name, env = {}) {
  const cycling = env.cycling !== false;
  const painting = env.painting || 'sunny-day';
  switch (name) {
    case 'settings-shortcuts': return settingsWindow({ cycling, painting });
    case 'settings-recording': return settingsWindow({ recording: 'topHalf', hover: 'rightHalf', cleared: ['restore'], cycling, painting });
    case 'settings-general': return settingsWindow({ pane: 'General', painting });
    case 'settings-no-access': return settingsWindow({ pane: 'General', trusted: false, login: false, painting });
    case 'popup': return popupOnDesktop({ cycling });
    case 'menu': return menuOnDesktop('normal');
    case 'menu-no-access': return menuOnDesktop('no-access');
    case 'first-run-ask': return firstRun('ask');
    case 'first-run-try': return firstRun('try', 2);
    case 'install': return installWindow();
    default: return `<p>Unknown screen ${name}</p>`;
  }
}
