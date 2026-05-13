/// <reference types="jest" />
import {
  signPrivateObjectKeysDeduped,
  signPublicMediaUrlsDeduped,
} from '../../src/storage/batch-private-object-sign';

describe('signPrivateObjectKeysDeduped', () => {
  it('dedupes keys and calls signer once per unique key', async () => {
    const calls: string[] = [];
    const sign = async (k: string) => {
      calls.push(k);
      return `signed:${k}`;
    };
    const map = await signPrivateObjectKeysDeduped(
      ['a', 'b', 'a', null, undefined, '', '  '],
      sign,
    );
    expect(calls.sort()).toEqual(['a', 'b']);
    expect(map.get('a')).toBe('signed:a');
    expect(map.get('b')).toBe('signed:b');
  });
});

describe('signPublicMediaUrlsDeduped', () => {
  it('dedupes URLs and calls signUrls once per distinct value', async () => {
    const batches: string[][] = [];
    const map = await signPublicMediaUrlsDeduped(
      ['https://a/1.jpg', 'https://b/2.png', 'https://a/1.jpg', '', '  '],
      async (unique) => {
        batches.push([...unique]);
        return unique.map((u) => `signed:${u}`);
      },
    );
    expect(batches).toHaveLength(1);
    expect(batches[0].sort()).toEqual(['https://a/1.jpg', 'https://b/2.png'].sort());
    expect(map.get('https://a/1.jpg')).toBe('signed:https://a/1.jpg');
    expect(map.get('https://b/2.png')).toBe('signed:https://b/2.png');
  });
});
