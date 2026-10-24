export enum WEEKDAY {
  MONDAY = 'MONDAY',
  TUESDAY = 'TUESDAY',
  WEDNESDAY = 'WEDNESDAY',
  THURSDAY = 'THURSDAY',
  FRIDAY = 'FRIDAY',
  SATURDAY = 'SATURDAY',
  SUNDAY = 'SUNDAY',
}

export const WEEKDAY_INDEX: Record<WEEKDAY, number> = {
  [WEEKDAY.SUNDAY]: 0,
  [WEEKDAY.MONDAY]: 1,
  [WEEKDAY.TUESDAY]: 2,
  [WEEKDAY.WEDNESDAY]: 3,
  [WEEKDAY.THURSDAY]: 4,
  [WEEKDAY.FRIDAY]: 5,
  [WEEKDAY.SATURDAY]: 6,
};

export function weekdayFromDate(date: Date): WEEKDAY {
  const values = Object.values(WEEKDAY);
  const index = date.getDay();
  const entry = Object.entries(WEEKDAY_INDEX).find(([, v]) => v === index);
  return (entry?.[0] as WEEKDAY) ?? values[0];
}
