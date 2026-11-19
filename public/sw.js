// Service Worker for LAST TRENCH PWA Fullscreen Support
const CACHE_NAME = 'last-trench-v2';
const PRECACHE_ASSETS = [
	'/',
	'/manifest.json',
	'/index.html',
	'/index.js',
	'/icon-144.png',
	'/icon-192.png',
	'/icon-512.png',
	'/icon-maskable-144.png',
	'/icon-maskable-192.png',
	'/icon-maskable-512.png'
];

self.addEventListener('install', (event) => {
	self.skipWaiting();
	event.waitUntil(
		caches.open(CACHE_NAME).then((cache) => {
			return cache.addAll(PRECACHE_ASSETS).catch((err) => {
				console.warn('[SW] Pre-caching partial assets failed:', err);
			});
		})
	);
});

self.addEventListener('activate', (event) => {
	event.waitUntil(
		caches.keys().then((cacheNames) => {
			return Promise.all(
				cacheNames.map((name) => {
					if (name !== CACHE_NAME) {
						return caches.delete(name);
					}
				})
			);
		}).then(() => self.clients.claim())
	);
});

self.addEventListener('fetch', (event) => {
	// Only handle same-origin GET requests
	if (event.request.method !== 'GET') return;
	const url = new URL(event.request.url);
	if (url.origin !== self.location.origin) return;

	event.respondWith(
		fetch(event.request)
			.then((response) => {
				// Cache valid responses for offline resilience
				if (response && response.status === 200 && response.type === 'basic') {
					const responseToCache = response.clone();
					caches.open(CACHE_NAME).then((cache) => {
						cache.put(event.request, responseToCache).catch(() => {});
					});
				}
				return response;
			})
			.catch(() => {
				return caches.match(event.request).then((cachedResponse) => {
					if (cachedResponse) {
						return cachedResponse;
					}
					// If navigating to page offline, return cached index.html
					if (event.request.mode === 'navigate') {
						return caches.match('/');
					}
				});
			})
	);
});
