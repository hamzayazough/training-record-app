export const CACHE_TTL_MS = 30_000;

export const CACHE_KEYS = {
  PROGRAMS: 'PROGRAMS',
  calendar: (type: string, from: string, days: number) =>
    `CALENDAR:${type}:${from}:${days}`,
  detail: (type: string) => `DETAIL:${type}`,
} as const;
