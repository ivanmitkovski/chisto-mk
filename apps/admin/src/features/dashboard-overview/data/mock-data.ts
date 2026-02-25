import { StatCard } from '../types';

export const stats: ReadonlyArray<StatCard> = [
  { id: 'approved', label: 'Approved Reports', value: 120, tone: 'green', icon: 'document-forward' },
  { id: 'new', label: 'New Reports', value: 20, tone: 'yellow', icon: 'document-text' },
  { id: 'deleted', label: 'Deleted Reports', value: 20, tone: 'red', icon: 'clipboard-close' },
  { id: 'in-review', label: 'In Review', value: 16, tone: 'mint', icon: 'document-forward' },
];
