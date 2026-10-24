#!/usr/bin/env node
import { randomUUID } from 'crypto';
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { MongoClient } from 'mongodb';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');

const WEEKDAY_INDEX = {
  SUNDAY: 0,
  MONDAY: 1,
  TUESDAY: 2,
  WEDNESDAY: 3,
  THURSDAY: 4,
  FRIDAY: 5,
  SATURDAY: 6,
};

function loadEnvUri() {
  if (process.env.MONGODB_URI?.trim()) return process.env.MONGODB_URI.trim();
  for (const rel of ['apps/mobile/.env', 'apps/api/.env']) {
    try {
      const text = readFileSync(join(root, rel), 'utf8');
      const match = text.match(/^MONGODB_URI=\s*(.+)$/m);
      if (match) return match[1].trim();
    } catch {
      // continue
    }
  }
  throw new Error('Set MONGODB_URI or add apps/mobile/.env');
}

function toIsoDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function parseIsoDate(iso) {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d);
}

function addDays(date, days) {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}

function startOfWeekMonday(date) {
  const d = new Date(date);
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

function dateForWeekdayInWeek(weekStartMonday, weekday) {
  const target = WEEKDAY_INDEX[weekday];
  let offset = target - 1;
  if (offset < 0) offset += 7;
  return addDays(weekStartMonday, offset);
}

function materialize(seed, startIso) {
  const programStart = startOfWeekMonday(parseIsoDate(startIso));
  const seedWeekdays = Object.fromEntries(
    Object.entries(seed.defaultWeekdayByDayNumber).map(([k, v]) => [Number(k), v]),
  );
  const sessions = [];

  for (const week of seed.weeks) {
    const weekStart = addDays(programStart, (week.weekNumber - 1) * 7);
    for (const template of week.sessions) {
      const weekday =
        seedWeekdays[template.dayNumber] ?? template.defaultWeekday;
      const date = dateForWeekdayInWeek(weekStart, weekday);
      const sessionId = randomUUID();
      const exercises = template.exercises.map((ex) => {
        const prescription =
          ex.prescription ??
          [ex.name, ex.distance, ex.pace, ex.duration, ex.intervals, ex.targetWeight, ex.setsReps, ex.rest]
            .filter(Boolean)
            .join(' — ');
        return {
          id: randomUUID(),
          name: ex.name,
          prescription,
          targetWeight: ex.targetWeight ?? null,
          setsReps: ex.setsReps ?? null,
          rest: ex.rest ?? null,
          distance: ex.distance ?? null,
          pace: ex.pace ?? null,
          duration: ex.duration ?? null,
          intervals: ex.intervals ?? null,
          metrics: ex.metrics ?? [],
          completed: false,
          status: 'PENDING',
        };
      });
      sessions.push({
        id: sessionId,
        programType: seed.programType,
        weekNumber: week.weekNumber,
        dayNumber: template.dayNumber,
        sessionLabel: template.sessionLabel,
        date: toIsoDate(date),
        weekday,
        exercises,
      });
    }
  }

  const program = {
    programType: seed.programType,
    title: seed.title,
    totalWeeks: seed.totalWeeks,
    startDate: startIso,
    weekdayByBlock: {},
  };

  return { program, sessions };
}

const uri = loadEnvUri()
  .replace(/\/[^/?]+(\?|$)/, '/training-record$1')
  .replace(/([?&])dnsServer=[^&]*/g, '$1')
  .replace(/\?&/, '?')
  .replace(/[?&]$/, '');

const startIso = toIsoDate(new Date());
const seeds = ['calisthenics.json', 'endurance.json'].map((name) =>
  JSON.parse(readFileSync(join(root, 'packages', 'programs', name), 'utf8')),
);

const client = new MongoClient(uri);
await client.connect();
const db = client.db('training-record');
const programsCol = db.collection('programs');
const sessionsCol = db.collection('sessions');

let sessionCount = 0;
for (const seed of seeds) {
  const { program, sessions } = materialize(seed, startIso);
  await sessionsCol.deleteMany({ programType: seed.programType });
  await programsCol.replaceOne(
    { programType: seed.programType },
    program,
    { upsert: true },
  );
  if (sessions.length) {
    await sessionsCol.insertMany(sessions);
  }
  sessionCount += sessions.length;
  console.log(
    `${seed.programType}: ${sessions.length} sessions, start ${program.startDate}, ${program.totalWeeks} weeks`,
  );
}

await db.collection('_meta').updateOne(
  { _id: 'setup' },
  {
    $set: {
      app: 'training-record',
      populatedAt: new Date(),
      startDate: startIso,
      programs: seeds.map((s) => s.programType),
    },
  },
  { upsert: true },
);

console.log(
  `Done. programs=${await programsCol.countDocuments()} sessions=${await sessionsCol.countDocuments()} (wrote ${sessionCount})`,
);
await client.close();
