import { PERFORMANCE_STATUS } from '../enums/performance-status.enum';
import { PROGRAM_TYPE } from '../enums/program-type.enum';
import { WEEKDAY } from '../enums/weekday.enum';

export interface ExerciseTemplate {
  name: string;
  prescription?: string;
  targetWeight?: string | null;
  setsReps?: string | null;
  rest?: string | null;
  distance?: string | null;
  pace?: string | null;
  duration?: string | null;
  intervals?: string | null;
  metrics: string[];
}

export interface SessionTemplate {
  dayNumber: number;
  defaultWeekday: WEEKDAY;
  sessionLabel: string;
  exercises: ExerciseTemplate[];
}

export interface WeekTemplate {
  weekNumber: number;
  sessions: SessionTemplate[];
}

export interface ProgramBlock {
  id: string;
  name: string;
  weekStart: number;
  weekEnd: number;
}

export interface ProgramSeed {
  programType: PROGRAM_TYPE;
  title: string;
  totalWeeks: number;
  defaultWeekdayByDayNumber: Record<string, WEEKDAY>;
  blocks?: ProgramBlock[];
  weeks: WeekTemplate[];
}

export interface ExerciseAdjustment {
  weight?: string;
  reps?: string;
  sets?: string;
  distance?: string;
  pace?: string;
  duration?: string;
  notes?: string;
}

export interface ScheduledExercise {
  id: string;
  name: string;
  prescription: string;
  targetWeight?: string | null;
  setsReps?: string | null;
  rest?: string | null;
  distance?: string | null;
  pace?: string | null;
  duration?: string | null;
  intervals?: string | null;
  metrics: string[];
  completed: boolean;
  status: PERFORMANCE_STATUS;
  adjustments?: ExerciseAdjustment;
}

export interface ScheduledSession {
  id: string;
  programType: PROGRAM_TYPE;
  weekNumber: number;
  dayNumber: number;
  sessionLabel: string;
  date: string;
  weekday: WEEKDAY;
  exercises: ScheduledExercise[];
}

export interface DayRecord {
  date: string;
  weekday: WEEKDAY;
  sessions: ScheduledSession[];
  overallStatus: PERFORMANCE_STATUS;
  summary: string;
}

export interface ProgramSummary {
  programType: PROGRAM_TYPE;
  title: string;
  totalWeeks: number;
  currentWeek: number;
  startDate: string;
}

export interface RearrangeTraining {
  dayNumber: number;
  label: string;
  currentWeekday: WEEKDAY;
}

export interface RearrangeWeekDay {
  date: string;
  weekday: WEEKDAY;
  shortLabel: string;
}

export interface RearrangeBlockSummary {
  id: string;
  name: string;
  weekStart: number;
  weekEnd: number;
  isCurrent: boolean;
  isPast: boolean;
}

export interface RearrangeLayout {
  blocks: RearrangeBlockSummary[];
  selectedBlockId: string;
  trainings: RearrangeTraining[];
  weekDays: RearrangeWeekDay[];
}

export interface RearrangeAssignment {
  dayNumber: number;
  weekday: WEEKDAY;
}
