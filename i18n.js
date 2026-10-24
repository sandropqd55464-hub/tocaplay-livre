/* TocaPlay – idiomas da interface (PT, EN, ES, FR).
   O app é escrito em português; aqui as palavras da tela são trocadas pelo idioma escolhido.
   Nomes de rádios, canais, vídeos e músicas não mudam. Escolha guardada em localStorage (tp_lang). */
(function () {
  'use strict';
  var LANGS = [['pt', 'Português'], ['en', 'English'], ['es', 'Español'], ['fr', 'Français']];
  var ok = function (l) { return LANGS.some(function (x) { return x[0] === l; }); };
  var L = null;
  try { var q = new URLSearchParams(location.search).get('lang'); if (ok(q)) { L = q; localStorage.setItem('tp_lang', q); } } catch (e) {}
  if (!L) { try { L = localStorage.getItem('tp_lang'); } catch (e) {} }
  if (!ok(L)) {
    L = 'pt';
    var nl = (navigator.languages || [navigator.language || 'pt']);
    for (var i = 0; i < nl.length; i++) { var c = String(nl[i]).slice(0, 2).toLowerCase(); if (ok(c)) { L = c; break; } if (i === 0) L = 'en'; }
  }
  window.TP_LANG = L;
  document.documentElement.lang = L === 'pt' ? 'pt-BR' : L;
  window.tpT = function (s) { return s; };

  // Language button in the header (next to "Baixar app")
  var GLOBE = '<svg width="17" height="17" fill="none" stroke="currentColor" stroke-width="2.1" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c-3 3-3 15 0 18M12 3c3 3 3 15 0 18"/></svg>';
  function addButton() {
    if (document.getElementById('langBtn')) return;
    var ref = document.getElementById('shareTop') || document.getElementById('installBtn'); if (!ref) return;
    var st = document.createElement('style');
    st.textContent = '.lang-wrap{position:relative}.lang-btn{display:flex;align-items:center;gap:5px;padding:9px 12px;border-radius:999px;font-weight:800;font-size:13.5px;background:rgba(255,210,63,.1);color:var(--yellow,#ffd23f);border:2px solid var(--yellow,#ffd23f);box-shadow:0 0 0 3px rgba(255,210,63,.12),0 0 14px rgba(255,210,63,.25);cursor:pointer;transition:background .15s,transform .15s}.lang-btn:hover{background:rgba(255,210,63,.2);transform:translateY(-1px)}.lang-btn svg{stroke:var(--yellow,#ffd23f)}'
      + '.lang-btn:focus-visible{outline:2px solid var(--yellow,#f5c518);outline-offset:2px}.lang-menu{position:absolute;right:0;top:calc(100% + 8px);min-width:170px;background:var(--card,#13201a);border:1px solid #2f4d3c;border-radius:14px;padding:6px;box-shadow:0 12px 30px rgba(0,0,0,.45);z-index:999}'
      + '.lang-menu button{display:flex;width:100%;align-items:center;justify-content:space-between;gap:10px;padding:10px 12px;border-radius:10px;background:none;border:0;color:var(--txt,#fff);font:inherit;font-weight:700;font-size:14.5px;cursor:pointer;text-align:left}'
      + '.lang-menu button:hover,.lang-menu button:focus-visible{background:var(--card2,#1b2a22)}.lang-menu button[aria-current="true"]{color:var(--yellow,#f5c518)}.lang-menu small{opacity:.6;font-weight:800}'
      + '@media(max-width:380px){.lang-btn span{display:none}.lang-btn{padding:9px 10px}}';
    document.head.appendChild(st);
    var w = document.createElement('div'); w.className = 'lang-wrap'; w.setAttribute('data-noi18n', '');
    w.innerHTML = '<button type="button" class="lang-btn" id="langBtn" aria-haspopup="true" aria-expanded="false" aria-label="Idioma / Language">' + GLOBE + '<span>' + L.toUpperCase() + '</span></button>'
      + '<div class="lang-menu" id="langMenu" role="menu" hidden>' + LANGS.map(function (x) { return '<button type="button" role="menuitemradio" data-lang="' + x[0] + '" aria-current="' + (x[0] === L) + '">' + x[1] + '<small>' + x[0].toUpperCase() + '</small></button>'; }).join('') + '</div>';
    ref.parentNode.insertBefore(w, ref);
    var b = w.querySelector('#langBtn'), m = w.querySelector('#langMenu');
    var close = function () { m.hidden = true; b.setAttribute('aria-expanded', 'false'); };
    b.addEventListener('click', function (e) { e.stopPropagation(); m.hidden = !m.hidden; b.setAttribute('aria-expanded', String(!m.hidden)); });
    m.addEventListener('click', function (e) { var t = e.target.closest('[data-lang]'); if (!t) return; var nlg = t.getAttribute('data-lang'); close(); if (nlg === L) return;
      try { localStorage.setItem('tp_lang', nlg); } catch (er) {}
      var u = new URL(location.href); u.searchParams.delete('lang'); location.replace(u.toString()); });
    document.addEventListener('click', function (e) { if (!w.contains(e.target)) close(); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', addButton); else addButton();

  if (L === 'pt') return;
  // The dictionary file calls __tpStart() when it loads. Written synchronously while the page is still being read,
  // so the Portuguese text never flashes on screen.
  window.__tpStart = function () { if (window.__tpStarted || !window.TP_DICT) return; window.__tpStarted = 1; start(); };
  var src = '/i18n-' + L + '.js?v=1';
  if (document.readyState === 'loading') document.write('<script src="' + src + '"><\/script>');
  else { var sc = document.createElement('script'); sc.src = src; document.head.appendChild(sc); }
  function start() {
    var D = window.TP_DICT || {}, PAT = [];
    Object.keys(D).forEach(function (k) { if (k.indexOf('{}') < 0) return;
      var re = '^' + k.split('{}').map(function (p) { return p.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }).join('(.+?)') + '$';
      PAT.push([new RegExp(re), D[k], k.replace(/\{\}/g, '').length]); });
    PAT.sort(function (a, b) { return b[2] - a[2]; });   // the most specific patterns first
    function look(s) {
      if (Object.prototype.hasOwnProperty.call(D, s)) return D[s];
      for (var i = 0; i < PAT.length; i++) { var m = s.match(PAT[i][0]); if (m) { var k = 1; return PAT[i][1].replace(/\{\}/g, function () { var g = m[k++]; return tr(g) || g; }); } }
      return null;
    }
    function tr(s) {
      if (!s || !/[A-Za-zÀ-ú]/.test(s)) return null;
      var m = s.match(/^([^A-Za-zÀ-ú0-9"«(¿¡{]*)([\s\S]*?)(\s*)$/); if (!m) return null;
      var core = m[2], t = look(core);
      if (t === null) { var p = core.match(/^([\s\S]*?)([\s…:.!?,;]+)$/); if (p) { t = look(p[1]); if (t !== null) t += p[2]; } }
      if (t === null && core.indexOf(' · ') > 0) { var parts = core.split(' · '), any = false; parts = parts.map(function (x) { var y = look(x); if (y !== null) { any = true; return y; } return x; }); if (any) t = parts.join(' · '); }
      return t === null ? null : m[1] + t + m[3];
    }
    window.tpT = function (s) { return tr(s) || s; };
    var SKIP = { SCRIPT: 1, STYLE: 1, TEXTAREA: 1, NOSCRIPT: 1, CODE: 1 }, ATTR = ['placeholder', 'title', 'aria-label', 'alt'], done = new WeakMap();
    function textNode(n) {
      var p = n.parentNode; if (!p || SKIP[p.nodeName] || (p.closest && p.closest('[data-noi18n],[contenteditable="true"]'))) return;
      var v = n.nodeValue; if (done.get(n) === v) return; var t = tr(v); if (t !== null && t !== v) { n.nodeValue = t; done.set(n, t); }
    }
    function attrs(el) { for (var i = 0; i < ATTR.length; i++) { var v = el.getAttribute(ATTR[i]); if (v) { var t = tr(v); if (t !== null && t !== v) el.setAttribute(ATTR[i], t); } } }
    function walk(root) {
      if (root.nodeType === 3) { textNode(root); return; }
      if (root.nodeType !== 1 || SKIP[root.nodeName]) return;
      attrs(root);
      var it = document.createTreeWalker(root, 5, null), n;   // elements + text
      while ((n = it.nextNode())) { if (n.nodeType === 3) textNode(n); else if (!SKIP[n.nodeName]) attrs(n); }
    }
    new MutationObserver(function (ms) {
      for (var i = 0; i < ms.length; i++) { var m = ms[i];
        if (m.type === 'childList') for (var j = 0; j < m.addedNodes.length; j++) walk(m.addedNodes[j]);
        else if (m.type === 'characterData') textNode(m.target);
        else if (m.type === 'attributes') attrs(m.target); }
    }).observe(document.documentElement, { subtree: true, childList: true, characterData: true, attributes: true, attributeFilter: ATTR });
    if (document.body) walk(document.body);
    if (document.head) walk(document.head);
    ['alert', 'confirm', 'prompt'].forEach(function (f) { var o = window[f]; if (typeof o === 'function') window[f] = function (msg, d) { return o.call(window, window.tpT(String(msg == null ? '' : msg)), d); }; });
  }
  if (window.TP_DICT) window.__tpStart();
})();
