const CACHE_NAME = 'la-casa-admin-v1';

self.addEventListener('install', event => {
  self.skipWaiting();
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(['./admin.html'])).catch(() => {}));
});

self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', event => {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (e) {
    data = { title: 'Novo pedido chegou!', body: event.data ? event.data.text() : 'Abra o painel para conferir.' };
  }

  const title = data.title || 'Novo pedido chegou!';
  const options = {
    body: data.body || 'Abra o painel administrativo para conferir.',
    tag: data.tag || 'novo-pedido',
    renotify: true,
    vibrate: [350, 150, 350, 150, 500],
    badge: data.badge || './icon-192.png',
    icon: data.icon || './icon-192.png',
    data: {
      url: data.url || './admin.html',
      order_id: data.order_id || null
    },
    actions: [
      { action: 'open-orders', title: 'Ver pedidos' }
    ]
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  const targetUrl = event.notification.data && event.notification.data.url ? event.notification.data.url : './admin.html';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(clients => {
      for (const client of clients) {
        if ('focus' in client) {
          client.navigate(targetUrl).catch(() => {});
          return client.focus();
        }
      }
      return self.clients.openWindow(targetUrl);
    })
  );
});
