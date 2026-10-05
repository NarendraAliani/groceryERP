(() => {
  const DB_NAME = 'groceryERP';
  const STORE_NAME = 'syncQueue';
  let databasePromise;
  function openDatabase() {
    if (databasePromise) return databasePromise;
    databasePromise = new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, 1);
      request.onupgradeneeded = () => {
        if (!request.result.objectStoreNames.contains(STORE_NAME)) request.result.createObjectStore(STORE_NAME, { keyPath: 'id', autoIncrement: true });
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
    return databasePromise;
  }
  async function queue(payload) {
    const db = await openDatabase();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      tx.objectStore(STORE_NAME).add({ payload, createdAt: Date.now() });
      tx.oncomplete = resolve;
      tx.onerror = () => reject(tx.error);
    });
  }
  async function flush() {
    if (!navigator.onLine) return;
    const db = await openDatabase();
    const rows = await new Promise((resolve, reject) => {
      const r = db.transaction(STORE_NAME, 'readonly').objectStore(STORE_NAME).getAll();
      r.onsuccess = () => resolve(r.result);
      r.onerror = () => reject(r.error);
    });
    for (const row of rows) {
      try {
        const response = await fetch('/api/pos/checkout', { method:'POST', headers:{'Content-Type':'application/json','X-CSRF-Token':document.querySelector('meta[name="csrf-token"]')?.content || ''}, body:JSON.stringify(row.payload) });
        const result = await response.json();
        if (!result.success) break;
        db.transaction(STORE_NAME,'readwrite').objectStore(STORE_NAME).delete(row.id);
      } catch (e) { break; }
    }
  }
  window.OfflineDB = { queue, flush };
  window.addEventListener('online', flush);
  window.addEventListener('load', flush);
  setInterval(flush, 30000);
})();
