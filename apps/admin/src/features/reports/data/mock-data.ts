import { ReportDetail, ReportRow } from '../types';

export const reports: ReadonlyArray<ReportRow> = [
  {
    id: 'r-1',
    reportNumber: '01.',
    name: 'Illegal waste dump',
    location: 'Skopje',
    dateReportedAt: '2025-10-23T09:15:00.000Z',
    status: 'NEW',
  },
  {
    id: 'r-2',
    reportNumber: '02.',
    name: 'Riverbank plastic pollution',
    location: 'Tetovo',
    dateReportedAt: '2025-10-22T10:45:00.000Z',
    status: 'IN_REVIEW',
  },
  {
    id: 'r-3',
    reportNumber: '03.',
    name: 'Burned tire residue',
    location: 'Bitola',
    dateReportedAt: '2025-10-21T11:30:00.000Z',
    status: 'APPROVED',
  },
  {
    id: 'r-4',
    reportNumber: '04.',
    name: 'Blocked drainage point',
    location: 'Kumanovo',
    dateReportedAt: '2025-10-20T12:05:00.000Z',
    status: 'NEW',
  },
  {
    id: 'r-5',
    reportNumber: '05.',
    name: 'Overflowing trash zone',
    location: 'Ohrid',
    dateReportedAt: '2025-10-19T13:10:00.000Z',
    status: 'DELETED',
  },
  {
    id: 'r-6',
    reportNumber: '06.',
    name: 'Forest edge dumping',
    location: 'Prilep',
    dateReportedAt: '2025-10-18T14:25:00.000Z',
    status: 'IN_REVIEW',
  },
  {
    id: 'r-7',
    reportNumber: '07.',
    name: 'Construction debris pile',
    location: 'Veles',
    dateReportedAt: '2025-10-17T15:30:00.000Z',
    status: 'NEW',
  },
  {
    id: 'r-8',
    reportNumber: '08.',
    name: 'Public park litter hotspot',
    location: 'Strumica',
    dateReportedAt: '2025-10-16T16:10:00.000Z',
    status: 'APPROVED',
  },
];

export const reportDetail: ReportDetail = {
  id: 'r-1',
  status: 'NEW',
  title: 'Illegal waste dump next to neighborhood park',
  description:
    'Residents reported recurring illegal dumping of mixed waste near a public park. The area requires urgent triage and municipal coordination.',
  location: 'Skopje',
};
