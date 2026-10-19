// Service worker: deixa o app instalável e abre rápido mesmo com internet fraca.
// Ao mudar o index.html, aumente a versão abaixo para os celulares pegarem a nova.
const CACHE = 'tocaplay-v30';
const SHELL = ['/', '/index.html', '/manifest.json', '/icon.svg', '/icon-192.png', '/icon-512.png', '/privacidade.html', '/config.js'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  // Só cuida dos arquivos do próprio site; rádios, API e Supabase passam direto.
  if (e.request.method !== 'GET' || url.origin !== location.origin || url.pathname.startsWith('/api/')) return;
  e.respondWith(
    fetch(e.request)
      .then(res => { const copy = res.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); return res; })
      .catch(() => caches.match(e.request).then(r => r || caches.match('/index.html')))
  );
});
