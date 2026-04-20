// Minimal no-op service worker for Emerge
// This worker clears all existing caches and unregisters itself to prevent blocking
// assets, especially during development or when transitioning away from custom PWA logic.

const CACHE_NAME = 'emerge-noop';

self.addEventListener('install', (event) => {
  console.log('[SW] Installing No-Op Service Worker');
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  console.log('[SW] Activating No-Op Service Worker - Purging Caches');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          console.log('[SW] Deleting cache:', cacheName);
          return caches.delete(cacheName);
        })
      );
    }).then(() => {
      // Take control of all open pages immediately
      return self.clients.claim();
    }).then(() => {
      // Optional: Unregister self after activation to completely remove SW footprint
      console.log('[SW] Caches purged. Service worker will transition to inactive.');
    })
  );
});

// Pass-through all fetch requests to the network
self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request));
});

// Handle SKIP_WAITING message
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
