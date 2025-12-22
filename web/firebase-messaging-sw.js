// Firebase Cloud Messaging Service Worker for FANCY PWA
// This service worker handles background push notifications via FCM

// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Firebase configuration - replace with your actual config
const firebaseConfig = {
  apiKey: "AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  authDomain: "fancy-app-xxxxx.firebaseapp.com",
  projectId: "fancy-app-xxxxx",
  storageBucket: "fancy-app-xxxxx.appspot.com",
  messagingSenderId: "xxxxxxxxxxxx",
  appId: "1:xxxxxxxxxxxx:web:xxxxxxxxxxxxxxxxxxxxxx"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firebase Messaging
const messaging = firebase.messaging();

const CACHE_NAME = 'fancy-pwa-v2';
const APP_ICON = '/icons/Icon-192.png';
const BADGE_ICON = '/icons/Icon-192.png';

// Install event - cache essential resources
self.addEventListener('install', (event) => {
  console.log('[FCM SW] Installing Service Worker v2');
  self.skipWaiting();
});

// Activate event
self.addEventListener('activate', (event) => {
  console.log('[FCM SW] Activating Service Worker');
  event.waitUntil(clients.claim());
});

// Handle FCM background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[FCM SW] Background message received:', payload);

  const notificationTitle = payload.notification?.title || payload.data?.title || 'FANCY';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || 'You have a new notification',
    icon: payload.notification?.icon || APP_ICON,
    badge: BADGE_ICON,
    tag: payload.data?.tag || `fancy-${Date.now()}`,
    data: payload.data || {},
    vibrate: [100, 50, 100],
    requireInteraction: true,
    actions: getNotificationActions(payload.data?.type),
    // For Android-like experience
    renotify: true,
    silent: false
  };

  // Add image if available (for rich notifications)
  if (payload.notification?.image || payload.data?.image) {
    notificationOptions.image = payload.notification?.image || payload.data?.image;
  }

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Get notification actions based on type
function getNotificationActions(type) {
  switch (type) {
    case 'message':
    case 'chat':
      return [
        { action: 'reply', title: 'Reply' },
        { action: 'open', title: 'Open Chat' }
      ];
    case 'match':
      return [
        { action: 'open', title: 'View Match' },
        { action: 'message', title: 'Send Message' }
      ];
    case 'like':
    case 'superlike':
      return [
        { action: 'open', title: 'View Profile' },
        { action: 'like_back', title: 'Like Back' }
      ];
    default:
      return [
        { action: 'open', title: 'Open' },
        { action: 'close', title: 'Dismiss' }
      ];
  }
}

// Legacy push event handler (fallback for non-FCM pushes)
self.addEventListener('push', (event) => {
  console.log('[FCM SW] Push received:', event);

  // Skip if it's an FCM message (handled by messaging.onBackgroundMessage)
  if (event.data) {
    try {
      const data = event.data.json();
      if (data.notification || data.fcmMessageId) {
        console.log('[FCM SW] FCM message, skipping legacy handler');
        return;
      }
    } catch (e) {
      // Not JSON, handle as text
    }
  }

  let notificationData = {
    title: 'FANCY',
    body: 'You have a new notification',
    icon: APP_ICON,
    badge: BADGE_ICON,
    tag: 'fancy-notification',
    data: {}
  };

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
      { action: 'close', title: 'Dismiss' }
    ]
  };

  event.waitUntil(
    self.registration.showNotification(notificationData.title, options)
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  console.log('[FCM SW] Notification clicked:', event);
  event.notification.close();

  const action = event.action;
  const data = event.notification.data || {};

  // Handle close/dismiss action
  if (action === 'close') {
    return;
  }

  // Determine URL to open based on notification data
  let urlToOpen = '/';

  if (data.chatId || data.chat_id) {
    urlToOpen = `/#/chats/${data.chatId || data.chat_id}`;
  } else if (data.userId || data.user_id) {
    urlToOpen = `/#/profile/${data.userId || data.user_id}`;
  } else if (data.matchId || data.match_id) {
    urlToOpen = '/#/chats';
  } else if (data.type === 'match' || data.type === 'like' || data.type === 'superlike') {
    urlToOpen = '/#/chats';
  } else if (data.type === 'message' || data.type === 'chat') {
    urlToOpen = '/#/chats';
  } else if (data.url) {
    urlToOpen = data.url;
  }

  // Handle special actions
  if (action === 'reply') {
    // For reply action, we could open the chat with input focused
    if (data.chatId || data.chat_id) {
      urlToOpen = `/#/chats/${data.chatId || data.chat_id}?action=reply`;
    }
  } else if (action === 'like_back') {
    // For like back action
    if (data.userId || data.user_id) {
      urlToOpen = `/#/profile/${data.userId || data.user_id}?action=like`;
    }
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
              data: data,
              action: action
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
  console.log('[FCM SW] Notification closed:', event);

  // Track notification dismissal if needed
  const data = event.notification.data || {};
  if (data.notificationId) {
    // Could send analytics event here
    console.log('[FCM SW] Notification dismissed:', data.notificationId);
  }
});

// Message event - handle messages from the main app
self.addEventListener('message', (event) => {
  console.log('[FCM SW] Message received:', event.data);

  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }

  // Handle show notification request from app
  if (event.data && event.data.type === 'SHOW_NOTIFICATION') {
    const { title, body, icon, tag, data, image } = event.data;
    const options = {
      body: body,
      icon: icon || APP_ICON,
      badge: BADGE_ICON,
      tag: tag || `fancy-${Date.now()}`,
      data: data,
      vibrate: [100, 50, 100],
      requireInteraction: true,
      actions: getNotificationActions(data?.type)
    };

    if (image) {
      options.image = image;
    }

    self.registration.showNotification(title, options);
  }

  // Handle FCM token update from app
  if (event.data && event.data.type === 'FCM_TOKEN_UPDATE') {
    console.log('[FCM SW] FCM token updated');
    // Token is managed by the app, just acknowledge
  }

  // Handle clear notifications request
  if (event.data && event.data.type === 'CLEAR_NOTIFICATIONS') {
    const tag = event.data.tag;
    self.registration.getNotifications({ tag: tag }).then((notifications) => {
      notifications.forEach((notification) => notification.close());
    });
  }
});

// Background sync for offline message sending
self.addEventListener('sync', (event) => {
  console.log('[FCM SW] Background sync:', event.tag);

  if (event.tag === 'send-message') {
    event.waitUntil(syncPendingMessages());
  } else if (event.tag === 'sync-notifications') {
    event.waitUntil(syncNotificationStatus());
  }
});

// Helper function to sync pending messages
async function syncPendingMessages() {
  console.log('[FCM SW] Syncing pending messages...');

  try {
    // Get pending messages from IndexedDB
    const db = await openDatabase();
    const tx = db.transaction('pendingMessages', 'readonly');
    const store = tx.objectStore('pendingMessages');
    const messages = await store.getAll();

    // Send each pending message
    for (const message of messages) {
      try {
        // Notify the app to send the message
        const clientList = await clients.matchAll({ type: 'window' });
        for (const client of clientList) {
          client.postMessage({
            type: 'SYNC_MESSAGE',
            message: message
          });
        }
      } catch (e) {
        console.error('[FCM SW] Error syncing message:', e);
      }
    }
  } catch (e) {
    console.error('[FCM SW] Error in syncPendingMessages:', e);
  }
}

// Helper function to sync notification status
async function syncNotificationStatus() {
  console.log('[FCM SW] Syncing notification status...');

  // Notify app to check for unread notifications
  const clientList = await clients.matchAll({ type: 'window' });
  for (const client of clientList) {
    client.postMessage({
      type: 'SYNC_NOTIFICATIONS'
    });
  }
}

// Simple IndexedDB helper
function openDatabase() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('FancyPWA', 1);

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);

    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains('pendingMessages')) {
        db.createObjectStore('pendingMessages', { keyPath: 'id', autoIncrement: true });
      }
    };
  });
}

// Periodic background sync (if supported)
self.addEventListener('periodicsync', (event) => {
  console.log('[FCM SW] Periodic sync:', event.tag);

  if (event.tag === 'check-notifications') {
    event.waitUntil(checkForNewNotifications());
  } else if (event.tag === 'update-badge') {
    event.waitUntil(updateAppBadge());
  }
});

// Check for new notifications
async function checkForNewNotifications() {
  console.log('[FCM SW] Checking for new notifications...');

  // Notify app to check for unread messages/notifications
  const clientList = await clients.matchAll({ type: 'window' });
  for (const client of clientList) {
    client.postMessage({
      type: 'CHECK_NOTIFICATIONS'
    });
  }
}

// Update app badge with unread count
async function updateAppBadge() {
  try {
    const clientList = await clients.matchAll({ type: 'window' });
    for (const client of clientList) {
      client.postMessage({
        type: 'GET_UNREAD_COUNT'
      });
    }
  } catch (e) {
    console.error('[FCM SW] Error updating badge:', e);
  }
}

// Handle badge update from app
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SET_BADGE') {
    const count = event.data.count || 0;
    if ('setAppBadge' in navigator) {
      if (count > 0) {
        navigator.setAppBadge(count);
      } else {
        navigator.clearAppBadge();
      }
    }
  }
});

console.log('[FCM SW] Firebase Messaging Service Worker loaded');
