import L from 'leaflet';
import styles from '../components/sites-map.module.css';

export function createCountClusterIcon(count: number) {
  const size = count >= 100 ? 52 : count >= 25 ? 46 : 40;
  const tierClass =
    count >= 100 ? styles.clusterIconLarge : count >= 25 ? styles.clusterIconMedium : styles.clusterIconSmall;
  const safeCount = String(count).replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  return L.divIcon({
    html: `<span class="${styles.clusterIcon} ${tierClass}" style="width:${size}px;height:${size}px;">${safeCount}</span>`,
    className: styles.clusterIconWrap,
    iconSize: [size, size],
  });
}
