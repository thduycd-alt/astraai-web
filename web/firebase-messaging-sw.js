// Firebase Messaging Service Worker — bắt buộc cho FCM trên Flutter Web
// File phải nằm ở web/firebase-messaging-sw.js

importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey:            "AIzaSyDmDps8oC6eZoE6JHkrOzF4N2GkqsinHl8",
  authDomain:        "astraai-a400f.firebaseapp.com",
  projectId:         "astraai-a400f",
  storageBucket:     "astraai-a400f.firebasestorage.app",
  messagingSenderId: "836225855307",
  appId:             "1:836225855307:web:bd463d199ee984a4b582ce",
  measurementId:     "G-M9LX0J11PZ"
});

const messaging = firebase.messaging();

// Nhận push notification khi browser/tab ĐÓNG hoặc ở background
messaging.onBackgroundMessage((payload) => {
  console.log('[AstraAI FCM] Background message:', payload);
  const title = payload.notification?.title || 'AstraAI Signals';
  const body  = payload.notification?.body  || '';
  const icon  = '/icons/Icon-192.png';

  return self.registration.showNotification(title, {
    body,
    icon,
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
    // Deep link khi user click notification
    actions: [{action: 'open', title: 'Xem ngay'}],
  });
});

// Xử lý click vào notification → mở tab app
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const symbol = event.notification.data?.symbol || '';
  const url    = symbol ? `/?symbol=${symbol}` : '/';
  event.waitUntil(
    clients.matchAll({type: 'window', includeUncontrolled: true}).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      return clients.openWindow(url);
    })
  );
});
