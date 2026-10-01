import { MemoryCache } from './memory-cache';

describe('MemoryCache', () => {
  it('coalesces concurrent loads into one database read', async () => {
    const cache = new MemoryCache();
    const loader = jest.fn().mockResolvedValue({ description: 'cached' });

    const [first, second] = await Promise.all([
      cache.getOrLoad('cause:en', loader, 60_000, 60_000),
      cache.getOrLoad('cause:en', loader, 60_000, 60_000),
    ]);

    expect(first).toEqual(second);
    expect(loader).toHaveBeenCalledTimes(1);
  });

  it('serves the previous value when a refresh fails inside stale lifetime', async () => {
    const cache = new MemoryCache();
    const loader = jest.fn()
      .mockResolvedValueOnce('old')
      .mockRejectedValueOnce(new Error('database unavailable'));

    await expect(cache.getOrLoad('x', loader, 0, 60_000)).resolves.toBe('old');
    await expect(cache.getOrLoad('x', loader, 0, 60_000)).resolves.toBe('old');
    expect(loader).toHaveBeenCalledTimes(2);
  });
});
