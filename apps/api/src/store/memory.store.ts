import { Injectable, OnModuleInit } from '@nestjs/common';
import { readFileSync } from 'fs';
import { join } from 'path';
import { randomUUID } from 'crypto';
import { PERFORMANCE_STATUS } from '../common/enums/performance-status.enum';
import { PROGRAM_TYPE } from '../common/enums/program-type.enum';
import {
  WEEKDAY,
  WEEKDAY_INDEX,
  weekdayFromDate,
} from '../common/enums/weekday.enum';
import {
  DayRecord,
  ExerciseAdjustment,
  ProgramBlock,
  ProgramSeed,
  ProgramSummary,
  RearrangeAssignment,
  RearrangeLayout,
  ScheduledExercise,
  ScheduledSession,
  SessionTemplate,
} from '../common/interfaces/program.interfaces';

function toIsoDate(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function parseIsoDate(iso: string): Date {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d);
}

function addDays(date: Date, days: number): Date {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}

function startOfWeekMonday(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

function dateForWeekdayInWeek(weekStartMonday: Date, weekday: WEEKDAY): Date {
  const target = WEEKDAY_INDEX[weekday];
  const mondayIndex = 1;
  let offset = target - mondayIndex;
  if (offset < 0) offset += 7;
  return addDays(weekStartMonday, offset);
}

function deriveDayStatus(
  sessions: ScheduledSession[],
  dateIso: string,
): PERFORMANCE_STATUS {
  if (sessions.length === 0) return PERFORMANCE_STATUS.REST;
  const today = toIsoDate(new Date());
  const exercises = sessions.flatMap((s) => s.exercises);
  const isPast = dateIso < today;
  if (
    isPast &&
    exercises.some(
      (e) => !e.completed || e.status === PERFORMANCE_STATUS.PENDING,
    )
  ) {
    return PERFORMANCE_STATUS.BAD;
  }
  const actionable = exercises
    .map((e) => e.status)
    .filter((s) => s !== PERFORMANCE_STATUS.PENDING);
  if (actionable.length === 0) return PERFORMANCE_STATUS.PENDING;
  if (actionable.every((s) => s === PERFORMANCE_STATUS.GOOD)) {
    return PERFORMANCE_STATUS.GOOD;
  }
  if (actionable.some((s) => s === PERFORMANCE_STATUS.BAD)) {
    return PERFORMANCE_STATUS.BAD;
  }
  if (actionable.some((s) => s === PERFORMANCE_STATUS.SO_SO)) {
    return PERFORMANCE_STATUS.SO_SO;
  }
  return PERFORMANCE_STATUS.PENDING;
}

function sessionSummary(sessions: ScheduledSession[]): string {
  if (sessions.length === 0) return 'Rest';
  return sessions.map((s) => s.sessionLabel).join(' · ');
}

function trainingLabel(template: SessionTemplate): string {
  return template.sessionLabel
    .toLowerCase()
    .split(/\s+/)
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

function shortWeekdayLabel(weekday: WEEKDAY): string {
  return weekday.slice(0, 3).charAt(0) + weekday.slice(1, 3).toLowerCase();
}

function blocksForSeed(seed: ProgramSeed): ProgramBlock[] {
  if (seed.blocks?.length) return seed.blocks;
  return [
    {
      id: 'FULL_PROGRAM',
      name: 'Full program',
      weekStart: 1,
      weekEnd: seed.totalWeeks,
    },
  ];
}

function blockContainingWeek(
  blocks: ProgramBlock[],
  weekNumber: number,
): ProgramBlock | undefined {
  return blocks.find(
    (block) => weekNumber >= block.weekStart && weekNumber <= block.weekEnd,
  );
}

@Injectable()
export class MemoryStore implements OnModuleInit {
  private seeds = new Map<PROGRAM_TYPE, ProgramSeed>();
  private startDates = new Map<PROGRAM_TYPE, string>();
  private sessions = new Map<string, ScheduledSession>();
  private exerciseIndex = new Map<string, string>();
  private weekdayByBlock = new Map<
    PROGRAM_TYPE,
    Map<string, Map<number, WEEKDAY>>
  >();

  onModuleInit(): void {
    this.loadSeeds();
    const today = toIsoDate(new Date());
    this.startDates.set(PROGRAM_TYPE.CALISTHENICS, today);
    this.startDates.set(PROGRAM_TYPE.ENDURANCE, today);
    this.materializeProgram(PROGRAM_TYPE.CALISTHENICS);
    this.materializeProgram(PROGRAM_TYPE.ENDURANCE);
  }

  private programsRoot(): string {
    const fromCwd = join(process.cwd(), '..', '..', 'packages', 'programs');
    const fromDist = join(__dirname, '..', '..', '..', '..', 'packages', 'programs');
    try {
      readFileSync(join(fromCwd, 'calisthenics.json'));
      return fromCwd;
    } catch {
      return fromDist;
    }
  }

  private loadSeeds(): void {
    const cali = JSON.parse(
      readFileSync(join(this.programsRoot(), 'calisthenics.json'), 'utf8'),
    ) as ProgramSeed;
    const endu = JSON.parse(
      readFileSync(join(this.programsRoot(), 'endurance.json'), 'utf8'),
    ) as ProgramSeed;
    this.seeds.set(PROGRAM_TYPE.CALISTHENICS, cali);
    this.seeds.set(PROGRAM_TYPE.ENDURANCE, endu);
  }

  private seedWeekdayMap(seed: ProgramSeed): Map<number, WEEKDAY> {
    const weekdayMap = new Map<number, WEEKDAY>();
    for (const [day, weekday] of Object.entries(seed.defaultWeekdayByDayNumber)) {
      weekdayMap.set(Number(day), weekday);
    }
    return weekdayMap;
  }

  private blockWeekdayMap(
    type: PROGRAM_TYPE,
    blockId: string,
  ): Map<number, WEEKDAY> {
    return this.weekdayByBlock.get(type)?.get(blockId) ?? new Map();
  }

  private materializeProgram(type: PROGRAM_TYPE): void {
    const seed = this.seeds.get(type);
    const startIso = this.startDates.get(type);
    if (!seed || !startIso) return;

    this.weekdayByBlock.set(type, new Map());
    const seedWeekdays = this.seedWeekdayMap(seed);
    const programStart = startOfWeekMonday(parseIsoDate(startIso));

    for (const week of seed.weeks) {
      const weekStart = addDays(programStart, (week.weekNumber - 1) * 7);
      for (const template of week.sessions) {
        const weekday =
          seedWeekdays.get(template.dayNumber) ?? template.defaultWeekday;
        const date = dateForWeekdayInWeek(weekStart, weekday);
        const sessionId = randomUUID();
        const exercises: ScheduledExercise[] = template.exercises.map((ex) => {
          const id = randomUUID();
          this.exerciseIndex.set(id, sessionId);
          return {
            id,
            name: ex.name,
            prescription:
              ex.prescription ??
              [
                ex.name,
                ex.distance,
                ex.pace,
                ex.duration,
                ex.intervals,
                ex.targetWeight,
                ex.setsReps,
                ex.rest,
              ]
                .filter(Boolean)
                .join(' — '),
            targetWeight: ex.targetWeight,
            setsReps: ex.setsReps,
            rest: ex.rest,
            distance: ex.distance ?? null,
            pace: ex.pace ?? null,
            duration: ex.duration ?? null,
            intervals: ex.intervals ?? null,
            metrics: ex.metrics ?? [],
            completed: false,
            status: PERFORMANCE_STATUS.PENDING,
          };
        });
        const session: ScheduledSession = {
          id: sessionId,
          programType: type,
          weekNumber: week.weekNumber,
          dayNumber: template.dayNumber,
          sessionLabel: template.sessionLabel,
          date: toIsoDate(date),
          weekday,
          exercises,
        };
        this.sessions.set(sessionId, session);
      }
    }
  }

  listPrograms(): ProgramSummary[] {
    return [PROGRAM_TYPE.ENDURANCE, PROGRAM_TYPE.CALISTHENICS].map((type) => {
      const seed = this.seeds.get(type)!;
      const start = this.startDates.get(type)!;
      const weeksElapsed = Math.floor(
        (parseIsoDate(toIsoDate(new Date())).getTime() -
          startOfWeekMonday(parseIsoDate(start)).getTime()) /
          (7 * 24 * 60 * 60 * 1000),
      );
      const currentWeek = Math.min(
        seed.totalWeeks,
        Math.max(1, weeksElapsed + 1),
      );
      return {
        programType: type,
        title: seed.title,
        totalWeeks: seed.totalWeeks,
        currentWeek,
        startDate: start,
      };
    });
  }

  getCalendar(type: PROGRAM_TYPE, from: string, days: number): DayRecord[] {
    const start = parseIsoDate(from);
    const byDate = new Map<string, ScheduledSession[]>();
    for (const session of this.sessions.values()) {
      if (session.programType !== type) continue;
      const list = byDate.get(session.date) ?? [];
      list.push(session);
      byDate.set(session.date, list);
    }

    const records: DayRecord[] = [];
    for (let i = 0; i < days; i++) {
      const date = addDays(start, i);
      const iso = toIsoDate(date);
      const sessions = (byDate.get(iso) ?? []).sort((a, b) =>
        a.sessionLabel.localeCompare(b.sessionLabel),
      );
      records.push({
        date: iso,
        weekday: weekdayFromDate(date),
        sessions,
        overallStatus: deriveDayStatus(sessions, iso),
        summary: sessionSummary(sessions),
      });
    }
    return records;
  }

  getDetail(type: PROGRAM_TYPE, pastDays = 7, futureDays = 21): DayRecord[] {
    const from = toIsoDate(addDays(new Date(), -pastDays));
    return this.getCalendar(type, from, pastDays + futureDays + 1);
  }

  getSession(id: string): ScheduledSession | undefined {
    return this.sessions.get(id);
  }

  getExercise(
    exerciseId: string,
  ): { session: ScheduledSession; exercise: ScheduledExercise } | undefined {
    const sessionId = this.exerciseIndex.get(exerciseId);
    if (!sessionId) return undefined;
    const session = this.sessions.get(sessionId);
    if (!session) return undefined;
    const exercise = session.exercises.find((e) => e.id === exerciseId);
    if (!exercise) return undefined;
    return { session, exercise };
  }

  completeExercise(exerciseId: string): ScheduledExercise {
    const found = this.getExercise(exerciseId);
    if (!found) throw new Error('EXERCISE_NOT_FOUND');
    found.exercise.completed = true;
    return found.exercise;
  }

  submitFeedback(
    exerciseId: string,
    status: PERFORMANCE_STATUS,
    adjustments?: ExerciseAdjustment,
  ): ScheduledExercise {
    const found = this.getExercise(exerciseId);
    if (!found) throw new Error('EXERCISE_NOT_FOUND');
    found.exercise.completed = true;
    found.exercise.status = status;
    if (adjustments) found.exercise.adjustments = adjustments;
    return found.exercise;
  }

  moveSession(sessionId: string, targetDate: string): ScheduledSession {
    const session = this.sessions.get(sessionId);
    if (!session) throw new Error('SESSION_NOT_FOUND');
    session.date = targetDate;
    session.weekday = weekdayFromDate(parseIsoDate(targetDate));
    return session;
  }

  getRearrangeLayout(type: PROGRAM_TYPE, blockId?: string): RearrangeLayout {
    const seed = this.seeds.get(type);
    const startIso = this.startDates.get(type);
    if (!seed || !startIso) throw new Error('PROGRAM_NOT_FOUND');

    const summary = this.listPrograms().find((p) => p.programType === type)!;
    const blocks = blocksForSeed(seed);
    const currentBlock =
      blockContainingWeek(blocks, summary.currentWeek) ?? blocks[0];
    const selected =
      (blockId ? blocks.find((block) => block.id === blockId) : undefined) ??
      currentBlock;

    const templateWeekNumber = Math.min(
      Math.max(summary.currentWeek, selected.weekStart),
      selected.weekEnd,
    );
    const week =
      seed.weeks.find((w) => w.weekNumber === templateWeekNumber) ??
      seed.weeks.find((w) => w.weekNumber === selected.weekStart) ??
      seed.weeks[0];

    const seedWeekdays = this.seedWeekdayMap(seed);
    const blockWeekdays = this.blockWeekdayMap(type, selected.id);

    const trainings = week.sessions.map((template) => ({
      dayNumber: template.dayNumber,
      label: trainingLabel(template),
      currentWeekday:
        blockWeekdays.get(template.dayNumber) ??
        seedWeekdays.get(template.dayNumber) ??
        template.defaultWeekday,
    }));

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const weekDays = Array.from({ length: 7 }, (_, index) => {
      const date = addDays(today, index);
      const weekday = weekdayFromDate(date);
      return {
        date: toIsoDate(date),
        weekday,
        shortLabel: shortWeekdayLabel(weekday),
      };
    });

    return {
      blocks: blocks.map((block) => ({
        id: block.id,
        name: block.name,
        weekStart: block.weekStart,
        weekEnd: block.weekEnd,
        isCurrent:
          summary.currentWeek >= block.weekStart &&
          summary.currentWeek <= block.weekEnd,
        isPast: block.weekEnd < summary.currentWeek,
      })),
      selectedBlockId: selected.id,
      trainings,
      weekDays,
    };
  }

  rearrangeSchedule(
    type: PROGRAM_TYPE,
    blockId: string,
    assignments: RearrangeAssignment[],
  ): void {
    const seed = this.seeds.get(type);
    const startIso = this.startDates.get(type);
    if (!seed || !startIso) throw new Error('PROGRAM_NOT_FOUND');

    const blocks = blocksForSeed(seed);
    const block = blocks.find((item) => item.id === blockId);
    if (!block) throw new Error('BLOCK_NOT_FOUND');

    const programMaps =
      this.weekdayByBlock.get(type) ?? new Map<string, Map<number, WEEKDAY>>();
    const weekdayMap = new Map<number, WEEKDAY>();
    for (const assignment of assignments) {
      weekdayMap.set(assignment.dayNumber, assignment.weekday);
    }
    programMaps.set(blockId, weekdayMap);
    this.weekdayByBlock.set(type, programMaps);

    const todayIso = toIsoDate(new Date());
    const programStart = startOfWeekMonday(parseIsoDate(startIso));
    const currentWeek =
      this.listPrograms().find((p) => p.programType === type)?.currentWeek ?? 1;
    const yesterdayIso = toIsoDate(addDays(parseIsoDate(todayIso), -1));
    const applyFromWeek = Math.max(currentWeek, block.weekStart);

    for (const session of this.sessions.values()) {
      if (session.programType !== type) continue;
      if (session.weekNumber < applyFromWeek) continue;
      if (session.weekNumber > block.weekEnd) continue;

      const mappedWeekday = weekdayMap.get(session.dayNumber);
      if (!mappedWeekday) continue;

      const weekStart = addDays(programStart, (session.weekNumber - 1) * 7);
      const nextDate = dateForWeekdayInWeek(weekStart, mappedWeekday);
      const nextIso = toIsoDate(nextDate);

      if (nextIso < todayIso) {
        session.date = yesterdayIso;
        session.weekday = mappedWeekday;
        continue;
      }

      session.date = nextIso;
      session.weekday = mappedWeekday;
    }
  }
}
