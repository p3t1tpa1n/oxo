// Service Worker pour OXO Application

const CACHE_NAME = 'oxo-app-cache-v1';
const OFFLINE_URL = 'offline.html';
const ASSETS_TO_CACHE = [
  'index.html',
  'main.dart.js',
  'flutter_bootstrap.js',
  'favicon.png',
  'manifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/AssetManifest.json',
  'assets/FontManifest.json',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
  OFFLINE_URL
];

// Installation du service worker et mise en cache des ressources
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('Service Worker: Mise en cache des fichiers');
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
  self.skipWaiting();
});

// Activation du service worker et nettoyage des anciens caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('Service Worker: Suppression de l\'ancien cache', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Stratégie de cache "Network First" avec fallback vers le cache
self.addEventListener('fetch', (event) => {
  // On ignore les requêtes non GET
  if (event.request.method !== 'GET') return;
  
  // On ignore les requêtes vers d'autres origines (CORS)
  if (!event.request.url.startsWith(self.location.origin)) return;
  
  // Stratégie pour les fichiers HTML (sauf offline.html)
  if (event.request.mode === 'navigate' && 
      event.request.destination === 'document' && 
      !event.request.url.includes('offline.html')) {
    event.respondWith(
      fetch(event.request)
        .catch(() => {
          // En cas d'échec, on sert la page hors ligne
          return caches.match(OFFLINE_URL);
        })
    );
    return;
  }

  // Stratégie pour les autres ressources (Network First)
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Mise en cache de la nouvelle réponse
        const responseClone = response.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseClone);
        });
        return response;
      })
      .catch(() => {
        // Si réseau indisponible, on sert depuis le cache
        return caches.match(event.request)
          .then((response) => {
            if (response) return response;
            
            // Si la ressource n'est pas dans le cache, on vérifie si c'est une image
            if (event.request.url.match(/\.(jpg|jpeg|png|gif|svg)$/)) {
              // Pour les images, on peut renvoyer une image par défaut
              return caches.match('icons/Icon-192.png');
            }
            
            // Pour les autres ressources, on utilise la page hors ligne
            return caches.match(OFFLINE_URL);
          });
      })
  );
});

// Synchronisation en arrière-plan pour les opérations en attente
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-data') {
    event.waitUntil(syncData());
  }
});

// Gestion des notifications push
self.addEventListener('push', (event) => {
  if (event.data) {
    const data = event.data.json();
    const options = {
      body: data.body || 'Nouvelle notification',
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png',
      data: {
        url: data.url || '/'
      }
    };
    
    event.waitUntil(
      self.registration.showNotification('OXO', options)
    );
  }
});

// Gestion du clic sur une notification
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  if (event.notification.data && event.notification.data.url) {
    event.waitUntil(
      clients.openWindow(event.notification.data.url)
    );
  }
});

// Fonction pour synchroniser les données
async function syncData() {
  // Récupérer les données en attente de synchronisation
  const dataToSync = await getDataToSync();
  
  if (dataToSync && dataToSync.length > 0) {
    try {
      // Envoyer les données au serveur
      const response = await fetch('/api/sync', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(dataToSync)
      });
      
      if (response.ok) {
        // Nettoyer les données synchronisées
        await clearSyncedData();
      }
    } catch (error) {
      console.error('Erreur lors de la synchronisation:', error);
    }
  }
}

// Fonctions fictives pour la gestion des données à synchroniser
async function getDataToSync() {
  // Cette fonction serait implémentée via IndexedDB
  return [];
}

async function clearSyncedData() {
  // Cette fonction serait implémentée via IndexedDB
} 