import { MOCK_DELAY_MS } from '@/features/shared/constants/mock';
import { delay } from '@/features/shared/utils/delay';
import { StatCard } from '../../types';
import { stats } from '../mock-data';

export async function getDashboardStats(): Promise<StatCard[]> {
  await delay(MOCK_DELAY_MS);
  return stats.map((card) => ({ ...card }));
}
