// Placeholder service worker
// This file will be replaced by Flutter's build process
self.addEventListener('install', function(e) {
  self.skipWaiting();
});

self.addEventListener('activate', function(e) {
  self.clients.claim();
});

self.addEventListener('fetch', function(e) {
  e.respondWith(fetch(e.request));
}); 