// Exploded view: a WIP design library around a project's real pieces.
// Framework-free ES module. A project calls createLibrary() with its own
// specs, environment controls and screens; this file owns the shell.
//
//   createLibrary({
//     root: document.getElementById('app'),
//     title: 'Psst library',
//     specs: [...],          // see SPEC below
//     controls: [...],       // toolbar environment controls, see CONTROL below
//     apply: (env) => {},    // apply env to the page (CSS vars, classes, fonts)
//     screens: [...],        // [{ name, src, w?, h?, status? }] live screens in frames
//     frames: [375, 390, 430],
//     codeLabel: 'Usage',    // or 'In Swift' for native apps
//   })
//
// SPEC: { id, group, name, desc, status: 'built'|'proposed'|'designed'|'wip',
//         props: { size: ['sm','md'], tone: [...] }, matrix?: ['size'], skip?: (p) => bool,
//         render?: (props, env) => html string | Node, custom?: (env) => html,
//         stage?: 'light'|'dark'|'none', width?, source?: 'src/Button.jsx',
//         code?: (props) => string   // usage call, or the native code it stands for
//         native?: { file, view, notes } }   // for native apps: where the real view lives
//
// CONTROL: { key, label, type: 'select'|'seg'|'range'|'toggle', options?: [[value,label]],
//            min?, max?, step?, default }

const STORE = 'exploded-view:env';
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
const STATUS = { built: 'Built', wip: 'In progress', designed: 'Designed, not built', proposed: 'Proposed' };

export function createLibrary(opts) {
  const { root, title = 'Library', specs, controls = [], apply = () => {}, screens = [], frames = [375, 390, 430], codeLabel = 'Usage' } = opts;
  const defaults = Object.fromEntries(controls.map((c) => [c.key, c.default]));
  const base = { ...defaults, frame: frames[1] ?? frames[0], zoom: 0.6, status: 'all' };
  let env = { ...base, ...load() };
  let selected = specs[0]?.id;
  let selectedProps = {};

  function load() { try { return JSON.parse(localStorage.getItem(STORE) || '{}'); } catch { return {}; } }
  function save() { try { localStorage.setItem(STORE, JSON.stringify(env)); } catch { /* private mode */ } }

  const combos = (spec) => {
    if (!spec.props) return [{}];
    const axes = spec.matrix || Object.keys(spec.props);
    let out = [Object.fromEntries(Object.entries(spec.props).map(([k, v]) => [k, v[0]]))];
    for (const axis of axes) out = out.flatMap((c) => spec.props[axis].map((v) => ({ ...c, [axis]: v })));
    return out.filter((c) => !spec.skip?.(c));
  };
  const label = (spec, p) => (spec.matrix || Object.keys(spec.props || {})).map((k) => p[k]).join(' · ') || 'default';
  const out = (v) => (v instanceof Node ? v.outerHTML : v ?? '');
  const badge = (s) => (s && s !== 'built' ? `<span class="xv-badge xv-${s}">${STATUS[s] || s}</span>` : '');
  const visible = (spec) => env.status === 'all' || (spec.status || 'built') === env.status;

  // ---------- Toolbar ----------
  function toolbarHtml() {
    const ctl = (c) => {
      const v = env[c.key];
      if (c.type === 'select') return `<select data-env="${c.key}">${c.options.map(([o, l]) => `<option value="${esc(o)}" ${String(v) === String(o) ? 'selected' : ''}>${esc(l)}</option>`).join('')}</select>`;
      if (c.type === 'seg') return `<div class="xv-seg">${c.options.map(([o, l]) => `<button data-env="${c.key}" data-value="${esc(o)}" class="${String(v) === String(o) ? 'on' : ''}">${esc(l)}</button>`).join('')}</div>`;
      if (c.type === 'range') return `<input type="range" data-env="${c.key}" min="${c.min}" max="${c.max}" step="${c.step}" value="${v}" aria-label="${esc(c.label)}"><output>${v}</output>`;
      if (c.type === 'toggle') return `<button data-env="${c.key}" data-toggle class="xv-tog ${v ? 'on' : ''}" aria-pressed="${!!v}">${v ? 'On' : 'Off'}</button>`;
      return '';
    };
    return `<div class="xv-brand"><b>${esc(title)}</b><span>WIP</span></div>
      ${controls.map((c) => `<div class="xv-group"><span>${esc(c.label)}</span>${ctl(c)}</div>`).join('')}
      <div class="xv-group"><span>Show</span><select data-env="status"><option value="all">Everything</option>${Object.entries(STATUS).map(([k, l]) => `<option value="${k}" ${env.status === k ? 'selected' : ''}>${l}</option>`).join('')}</select></div>
      ${screens.length && frames.length ? `<div class="xv-group"><span>Frame</span><div class="xv-seg">${frames.map((f) => `<button data-env="frame" data-value="${f}" class="${env.frame == f ? 'on' : ''}">${f}</button>`).join('')}</div></div>` : ''}
      ${screens.length ? `<div class="xv-group"><span>Zoom</span><input type="range" data-env="zoom" min="0.3" max="1" step="0.05" value="${env.zoom}" aria-label="Zoom"></div>` : ''}
      <button class="xv-reset" data-reset>Reset</button>`;
  }

  // ---------- Canvas ----------
  function specHtml(spec) {
    let body;
    if (spec.custom) body = `<div class="xv-stage xv-stage-${spec.stage || 'light'}">${spec.custom(env)}</div>`;
    else body = `<div class="xv-stage xv-stage-${spec.stage || 'light'}"><div class="xv-variants">${combos(spec).map((p) => `
      <figure class="xv-variant" data-props='${esc(JSON.stringify(p))}'>
        <div class="xv-specimen" style="${spec.width ? `width:${spec.width}px` : ''}">${out(spec.render(p, env))}</div>
        <figcaption>${esc(label(spec, p))}</figcaption>
      </figure>`).join('')}</div></div>`;
    return `<section class="xv-spec" id="spec-${spec.id}" data-spec="${spec.id}" ${visible(spec) ? '' : 'hidden'}>
      <header class="xv-spec-head"><div><span class="xv-group-label">${esc(spec.group)}</span><h2>${esc(spec.name)} ${badge(spec.status)}</h2></div><p>${spec.desc || ''}</p></header>
      ${body}</section>`;
  }

  function screensHtml() {
    if (!screens.length) return '';
    const z = Number(env.zoom), w = Number(env.frame);
    return `<section class="xv-spec" id="spec-screens" data-spec="screens"><header class="xv-spec-head"><div><span class="xv-group-label">Screens</span><h2>Live screens</h2></div><p>The real screens with sample data. Toolbar changes reach them too.</p></header>
      <div class="xv-screens">${screens.map((s) => { const h = s.h || 844, sw = s.w || w; return `
        <figure><div class="xv-frame" style="width:${sw * z}px;height:${h * z}px"><iframe src="${esc(s.src)}" title="${esc(s.name)}" loading="lazy" style="width:${sw}px;height:${h}px;transform:scale(${z})"></iframe></div>
        <figcaption><b>${esc(s.name)}</b> ${badge(s.status)} <a href="${esc(s.src)}" target="_blank" rel="noopener">Open ↗</a></figcaption></figure>`; }).join('')}</div></section>`;
  }

  // ---------- Inspector ----------
  function inspectorHtml() {
    const spec = specs.find((s) => s.id === selected);
    if (!spec) return '<p class="xv-tip">Click any piece to inspect it.</p>';
    const p = { ...(spec.props ? Object.fromEntries(Object.entries(spec.props).map(([k, v]) => [k, v[0]])) : {}), ...selectedProps };
    const code = spec.code?.(p);
    const n = spec.native;
    return `<div class="xv-insp-head"><span class="xv-group-label">${esc(spec.group)}</span><h3>${esc(spec.name)}</h3>${badge(spec.status)}<p>${spec.desc || ''}</p></div>
      ${spec.render ? `<div class="xv-stage xv-stage-${spec.stage || 'light'} xv-insp-stage"><div class="xv-specimen">${out(spec.render(p, env))}</div></div>` : ''}
      ${spec.props ? `<div class="xv-props">${Object.entries(spec.props).map(([k, vals]) => `<label><span>${esc(k)}</span><select data-prop="${esc(k)}">${vals.map((v) => `<option ${p[k] === v ? 'selected' : ''}>${esc(v)}</option>`).join('')}</select></label>`).join('')}</div>` : ''}
      ${code ? `<div class="xv-code"><span>${esc(codeLabel)}</span><pre><code>${esc(code)}</code></pre></div>` : ''}
      ${n ? `<div class="xv-code"><span>In the app</span><p><code>${esc(n.file || '')}</code>${n.view ? ` · <code>${esc(n.view)}</code>` : ''}</p>${n.notes ? `<p>${n.notes}</p>` : ''}</div>` : ''}
      ${spec.source ? `<div class="xv-code"><span>Source</span><p><code>${esc(spec.source)}</code></p></div>` : ''}`;
  }

  // ---------- Mount ----------
  const groups = [...new Set(specs.map((s) => s.group))];
  document.title = title;
  document.body.classList.add('xv-body');
  root.classList.add('xv');
  root.innerHTML = `<header class="xv-toolbar"></header>
    <nav class="xv-nav"><input class="xv-search" type="search" placeholder="Find a piece…" aria-label="Find a piece">
      ${groups.map((g) => `<div class="xv-nav-group"><span>${esc(g)}</span>${specs.filter((s) => s.group === g).map((s) => `<a href="#spec-${s.id}" data-nav="${s.id}">${esc(s.name)}${s.status && s.status !== 'built' ? '<i></i>' : ''}</a>`).join('')}</div>`).join('')}
      ${screens.length ? '<div class="xv-nav-group"><span>Screens</span><a href="#spec-screens" data-nav="screens">Live screens</a></div>' : ''}</nav>
    <main class="xv-canvas"></main>
    <aside class="xv-inspector" aria-label="Inspector"></aside>`;
  const $ = (s) => root.querySelector(s);

  function render() {
    apply(env);
    for (const f of root.querySelectorAll('iframe')) f.contentWindow?.postMessage({ type: 'exploded-view:env', env }, '*');
    $('.xv-toolbar').innerHTML = toolbarHtml();
    $('.xv-canvas').innerHTML = specs.map(specHtml).join('') + screensHtml();
    $('.xv-inspector').innerHTML = inspectorHtml();
    for (const a of root.querySelectorAll('[data-nav]')) a.classList.toggle('on', a.dataset.nav === selected);
  }
  const set = (patch) => { env = { ...env, ...patch }; save(); render(); };

  $('.xv-toolbar').addEventListener('click', (e) => {
    const b = e.target.closest('button');
    if (!b) return;
    if (b.dataset.reset !== undefined) return set({ ...base });
    if (b.dataset.toggle !== undefined) return set({ [b.dataset.env]: !env[b.dataset.env] });
    if (b.dataset.value !== undefined) { const raw = b.dataset.value; set({ [b.dataset.env]: Number.isNaN(Number(raw)) ? raw : Number(raw) }); }
  });
  $('.xv-toolbar').addEventListener('change', (e) => { const k = e.target.dataset.env; if (k) set({ [k]: e.target.type === 'range' ? Number(e.target.value) : e.target.value }); });
  $('.xv-toolbar').addEventListener('input', (e) => {
    if (e.target.type !== 'range') return;
    env = { ...env, [e.target.dataset.env]: Number(e.target.value) };
    e.target.nextElementSibling?.tagName === 'OUTPUT' && (e.target.nextElementSibling.value = e.target.value);
    apply(env); save();
  });
  $('.xv-canvas').addEventListener('click', (e) => {
    const spec = e.target.closest('.xv-spec');
    if (!spec || spec.dataset.spec === 'screens') return;
    const v = e.target.closest('.xv-variant');
    selected = spec.dataset.spec; selectedProps = v ? JSON.parse(v.dataset.props) : {};
    $('.xv-inspector').innerHTML = inspectorHtml();
    for (const a of root.querySelectorAll('[data-nav]')) a.classList.toggle('on', a.dataset.nav === selected);
  });
  $('.xv-inspector').addEventListener('change', (e) => {
    const k = e.target.dataset.prop;
    if (k) { selectedProps = { ...selectedProps, [k]: e.target.value }; $('.xv-inspector').innerHTML = inspectorHtml(); }
  });
  $('.xv-nav').addEventListener('click', (e) => { const a = e.target.closest('[data-nav]'); if (a && a.dataset.nav !== 'screens') { selected = a.dataset.nav; selectedProps = {}; $('.xv-inspector').innerHTML = inspectorHtml(); } });
  $('.xv-search').addEventListener('input', (e) => {
    const q = e.target.value.toLowerCase();
    for (const a of root.querySelectorAll('[data-nav]')) a.hidden = !!q && !a.textContent.toLowerCase().includes(q);
    for (const s of root.querySelectorAll('.xv-spec')) s.hidden = (!!q && !s.querySelector('h2').textContent.toLowerCase().includes(q)) || (s.dataset.spec !== 'screens' && !visible(specs.find((x) => x.id === s.dataset.spec)));
  });

  render();
  return { set, get env() { return env; } };
}
