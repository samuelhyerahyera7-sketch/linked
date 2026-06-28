const LINKED_CACHE = 'linked-v2-cache-20260629';
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './assets/linked-logo.png',
  './assets/linked-logo-transparent.png',
  './assets/red-rose-transparent.png',
  './assets/bouquet.png',
  './assets/golden-rose.png',
  './assets/onboarding-couple-v2.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(LINKED_CACHE)
      .then(cache => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(key => key !== LINKED_CACHE).map(key => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    caches.match(event.request).then(cached => cached || fetch(event.request).then(response => {
      const copy = response.clone();
      caches.open(LINKED_CACHE).then(cache => cache.put(event.request, copy)).catch(() => {});
      return response;
    }).catch(() => caches.match('./index.html')))
  );
});
