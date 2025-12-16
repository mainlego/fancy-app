// Service Worker for FANCY PWA Push Notifications
// This service worker handles background push notifications

const CACHE_NAME = 'fancy-pwa-v1';

// Install event - cache essential resources
self.addEventListener('install', (event) => {
  console.log('[SW] Installing Service Worker');
  self.skipWaiting();
});

// Activate event
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating Service Worker');
  event.waitUntil(clients.claim());
});

// Push event - handle incoming push notifications
self.addEventListener('push', (event) => {
  console.log('[SW] Push received:', event);

  let notificationData = {
    title: 'FANCY',
    body: 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'fancy-notification',
    data: {}
  };

  // Parse push data if available
  if (event.data) {
    try {
      const data = event.data.json();
      notificationData = {
        title: data.title || notificationData.title,
        body: data.body || notificationData.body,
        icon: data.icon || notificationData.icon,
        badge: data.badge || notificationData.badge,
        tag: data.tag || notificationData.tag,
        data: data.data || {}
      };
    } catch (e) {
      console.log('[SW] Error parsing push data:', e);
      notificationData.body = event.data.text();
    }
  }

  const options = {
    body: notificationData.body,
    icon: notificationData.icon,
    badge: notificationData.badge,
    tag: notificationData.tag,
    data: notificationData.data,
    vibrate: [100, 50, 100],
    requireInteraction: true,
    actions: [
      { action: 'open', title: 'Open' },
      { action: 'close', title: 'Close' }
    ]
  };

  event.waitUntil(
    self.registration.showNotification(notificationData.title, options)
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked:', event);
  event.notification.close();

  const action = event.action;
  const data = event.notification.data || {};

  // Handle close action
  if (action === 'close') {
    return;
  }

  // Determine URL to open based on notification data
  let urlToOpen = '/';

  if (data.chatId) {
    urlToOpen = `/#/chats/${data.chatId}`;
  } else if (data.userId) {
    urlToOpen = `/#/profile/${data.userId}`;
  } else if (data.matchId) {
    urlToOpen = '/#/chats';
  } else if (data.url) {
    urlToOpen = data.url;
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // If app is already open, focus it and navigate
        for (const client of clientList) {
          if ('focus' in client) {
            client.focus();
            client.postMessage({
              type: 'NOTIFICATION_CLICK',
              url: urlToOpen,
              data: data
            });
            return;
          }
        }
        // If app is not open, open it
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});

// Notification close event
self.addEventListener('notificationclose', (event) => {
  console.log('[SW] Notification closed:', event);
});

// Message event - handle messages from the main app
self.addEventListener('message', (event) => {
  console.log('[SW] Message received:', event.data);

  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }

  // Handle show notification request from app
  if (event.data && event.data.type === 'SHOW_NOTIFICATION') {
    const { title, body, icon, tag, data } = event.data;
    self.registration.showNotification(title, {
      body: body,
      icon: icon || '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: tag,
      data: data,
      vibrate: [100, 50, 100]
    });
  }
});

// Background sync for offline message sending
self.addEventListener('sync', (event) => {
  console.log('[SW] Background sync:', event.tag);

  if (event.tag === 'send-message') {
    event.waitUntil(sendPendingMessages());
  }
});

// Helper function to send pending messages (placeholder)
async function sendPendingMessages() {
  // This would sync messages that were queued while offline
  console.log('[SW] Syncing pending messages...');
}

// Periodic background sync (if supported)
self.addEventListener('periodicsync', (event) => {
  console.log('[SW] Periodic sync:', event.tag);

  if (event.tag === 'check-notifications') {
    event.waitUntil(checkForNewNotifications());
  }
});

// Helper function to check for new notifications (placeholder)
async function checkForNewNotifications() {
  console.log('[SW] Checking for new notifications...');
}
