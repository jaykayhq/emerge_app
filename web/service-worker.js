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
      // Unregister self after activation to completely remove the SW
      // footprint. A stale service worker (from older PWA deploys) can
      // keep serving mismatched index.html/assets and reproduce the
      // AssetManifest.bin.json 404 symptom even after a redeploy.
      return self.registration.unregister();
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
