export type CacheEntry<T> = {
  value: T;
  freshUntil: number;
  staleUntil: number;
};

type Pending<T> = Promise<T>;

export class MemoryCache {
  private readonly entries = new Map<string, CacheEntry<unknown>>();
  private readonly pending = new Map<string, Pending<unknown>>();

  async getOrLoad<T>(
    key: string,
    loader: () => Promise<T>,
    freshMs: number,
    staleMs: number,
  ): Promise<T> {
    const now = Date.now();
    const entry = this.entries.get(key) as CacheEntry<T> | undefined;

    if (entry && now < entry.freshUntil) {
      return entry.value;
    }

    const existing = this.pending.get(key) as Pending<T> | undefined;
    if (existing) return existing;

    const pending = loader()
      .then((value) => {
        this.entries.set(key, {
          value,
          freshUntil: Date.now() + freshMs,
          staleUntil: Date.now() + staleMs,
        });
        return value;
      })
      .catch((error) => {
        if (entry && now < entry.staleUntil) {
          return entry.value;
        }
        throw error;
      })
      .finally(() => {
        this.pending.delete(key);
      });

    this.pending.set(key, pending);
    return pending;
  }

  invalidate(prefix?: string) {
    if (!prefix) {
      this.entries.clear();
      return;
    }
    for (const key of this.entries.keys()) {
      if (key.startsWith(prefix)) this.entries.delete(key);
    }
  }
}
