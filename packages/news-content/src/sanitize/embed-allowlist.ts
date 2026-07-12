const ALLOWED_IFRAME_HOSTS = new Set([
  'www.youtube.com',
  'youtube.com',
  'www.youtube-nocookie.com',
  'youtube-nocookie.com',
  'player.vimeo.com',
  'vimeo.com',
]);

/** HTTPS origins for CSP `frame-src` (admin preview + landing embeds). */
export const NEWS_EMBED_FRAME_SRC_ORIGINS = [
  'https://www.youtube.com',
  'https://youtube.com',
  'https://www.youtube-nocookie.com',
  'https://youtube-nocookie.com',
  'https://player.vimeo.com',
  'https://vimeo.com',
] as const;

export function isAllowedEmbedUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'https:') return false;
    return ALLOWED_IFRAME_HOSTS.has(parsed.hostname);
  } catch {
    return false;
  }
}

function normalizeVideoPageUrl(input: string): string {
  const trimmed = input.trim();
  if (!trimmed) return trimmed;
  if (/^https?:\/\//i.test(trimmed)) return trimmed;
  return `https://${trimmed}`;
}

export function youtubeEmbedUrl(url: string): string | null {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.replace(/^www\./, '');
    if (host === 'youtu.be') {
      const id = parsed.pathname.slice(1).split('/')[0];
      return id ? `https://www.youtube-nocookie.com/embed/${id}` : null;
    }
    if (host === 'youtube.com' || host === 'youtube-nocookie.com') {
      const shortsId = parsed.pathname.match(/^\/shorts\/([^/?]+)/)?.[1];
      if (shortsId) return `https://www.youtube-nocookie.com/embed/${shortsId}`;
      const id = parsed.searchParams.get('v') ?? parsed.pathname.match(/\/embed\/([^/?]+)/)?.[1];
      return id ? `https://www.youtube-nocookie.com/embed/${id}` : null;
    }
    return null;
  } catch {
    return null;
  }
}

export function vimeoEmbedUrl(url: string): string | null {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.replace(/^www\./, '');
    if (host === 'vimeo.com') {
      const id = parsed.pathname.split('/').filter(Boolean)[0];
      return id ? `https://player.vimeo.com/video/${id}` : null;
    }
    if (host === 'player.vimeo.com') {
      return parsed.href;
    }
    return null;
  } catch {
    return null;
  }
}

export function embedUrlFromVideoLink(url: string): string | null {
  const normalized = normalizeVideoPageUrl(url);
  return youtubeEmbedUrl(normalized) ?? vimeoEmbedUrl(normalized);
}

export function embedProviderFromUrl(url: string): 'youtube' | 'vimeo' | null {
  if (!isAllowedEmbedUrl(url)) return null;
  try {
    const host = new URL(url).hostname.replace(/^www\./, '');
    if (host.includes('youtube') || host === 'youtu.be') return 'youtube';
    if (host.includes('vimeo')) return 'vimeo';
  } catch {
    return null;
  }
  return null;
}

function escapeHtmlAttr(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

export function buildEmbedIframeHtml(embedUrl: string): string {
  // Always normalize watch/shorts/share URLs to proper embed endpoints.
  const normalized = embedUrlFromVideoLink(embedUrl);
  const candidate = normalized ?? embedUrl;
  if (!isAllowedEmbedUrl(candidate)) return '';
  let safeSrc: string;
  try {
    safeSrc = escapeHtmlAttr(new URL(candidate).href);
  } catch {
    return '';
  }
  return `<div class="news-embed"><iframe src="${safeSrc}" title="Embedded video" loading="lazy" referrerpolicy="strict-origin-when-cross-origin" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe></div>`;
}
