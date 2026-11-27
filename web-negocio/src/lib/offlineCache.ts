const CACHE_PREFIX = "reservall:http-cache:v1:";
const MAX_ENTRIES = 80;
const MAX_AGE_MS = 1000 * 60 * 60 * 24 * 7; // 7 días
const MAX_BODY_LENGTH = 1_500_000; // ~1.5 MB por respuesta

export interface CachedResponse {
  body: string;
  contentType: string;
  storedAt: number;
}

function cacheKey(url: string): string {
  return `${CACHE_PREFIX}${url}`;
}

function safeStorage(): Storage | null {
  try {
    const key = "__reservall_storage_test__";
    window.localStorage.setItem(key, "1");
    window.localStorage.removeItem(key);
    return window.localStorage;
  } catch {
    return null;
  }
}

function pruneCache(storage: Storage): void {
  const now = Date.now();
  const entries: { key: string; storedAt: number }[] = [];

  for (let index = 0; index < storage.length; index += 1) {
    const key = storage.key(index);
    if (!key || !key.startsWith(CACHE_PREFIX)) continue;

    try {
      const raw = storage.getItem(key);
      if (!raw) continue;
      const parsed = JSON.parse(raw) as Partial<CachedResponse>;
      const storedAt = Number(parsed.storedAt ?? 0);

      if (!storedAt || now - storedAt > MAX_AGE_MS) {
        storage.removeItem(key);
        index -= 1;
        continue;
      }

      entries.push({ key, storedAt });
    } catch {
      storage.removeItem(key);
      index -= 1;
    }
  }

  if (entries.length <= MAX_ENTRIES) return;

  entries
    .sort((a, b) => a.storedAt - b.storedAt)
    .slice(0, entries.length - MAX_ENTRIES)
    .forEach((entry) => storage.removeItem(entry.key));
}

export function readCachedResponse(url: string): CachedResponse | null {
  const storage = safeStorage();
  if (!storage) return null;

  try {
    const raw = storage.getItem(cacheKey(url));
    if (!raw) return null;

    const parsed = JSON.parse(raw) as Partial<CachedResponse>;
    if (
      typeof parsed.body !== "string" ||
      typeof parsed.storedAt !== "number" ||
      Date.now() - parsed.storedAt > MAX_AGE_MS
    ) {
      storage.removeItem(cacheKey(url));
      return null;
    }

    return {
      body: parsed.body,
      contentType: parsed.contentType || "application/json",
      storedAt: parsed.storedAt,
    };
  } catch {
    return null;
  }
}

export function writeCachedResponse(
  url: string,
  body: string,
  contentType: string,
): void {
  if (body.length > MAX_BODY_LENGTH) return;

  const storage = safeStorage();
  if (!storage) return;

  try {
    const entry: CachedResponse = {
      body,
      contentType: contentType || "application/json",
      storedAt: Date.now(),
    };
    storage.setItem(cacheKey(url), JSON.stringify(entry));
    pruneCache(storage);
  } catch {
    // Sin espacio o almacenamiento bloqueado: la app sigue funcionando online.
  }
}

export function clearHttpCache(): void {
  const storage = safeStorage();
  if (!storage) return;

  const keys: string[] = [];
  for (let index = 0; index < storage.length; index += 1) {
    const key = storage.key(index);
    if (key?.startsWith(CACHE_PREFIX)) keys.push(key);
  }
  keys.forEach((key) => storage.removeItem(key));
}

export function cachedResponseToResponse(cached: CachedResponse): Response {
  return new Response(cached.body, {
    status: 200,
    statusText: "OK",
    headers: {
      "Content-Type": cached.contentType,
      "X-ReservAll-Offline": "1",
    },
  });
}
