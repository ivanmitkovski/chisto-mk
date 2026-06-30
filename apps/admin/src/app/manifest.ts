import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Chisto.mk Admin',
    short_name: 'Chisto Admin',
    description: 'Admin console for Chisto.mk civic environmental platform',
    start_url: '/dashboard',
    display: 'standalone',
    background_color: '#f7f8fe',
    theme_color: '#25db86',
  };
}
