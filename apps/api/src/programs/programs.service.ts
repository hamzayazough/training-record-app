import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { CACHE_KEYS, CACHE_TTL_MS } from '../common/constants/cache-keys';
import { PERFORMANCE_STATUS } from '../common/enums/performance-status.enum';
import { PROGRAM_TYPE } from '../common/enums/program-type.enum';
import {
  WEEKDAY,
  WEEKDAY_INDEX,
} from '../common/enums/weekday.enum';
import { FeedbackDto } from './dto/feedback.dto';
import { MoveSessionDto } from './dto/move-session.dto';
import { MemoryStore } from '../store/memory.store';

function parseProgramType(type: string): PROGRAM_TYPE {
  const upper = type.toUpperCase();
  if (upper === PROGRAM_TYPE.ENDURANCE || upper === PROGRAM_TYPE.CALISTHENICS) {
    return upper;
  }
  throw new BadRequestException('INVALID_PROGRAM_TYPE');
}

function toIsoDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

@Injectable()
export class ProgramsService {
  constructor(
    private readonly store: MemoryStore,
    @Inject(CACHE_MANAGER) private readonly cache: Cache,
  ) {}

  listPrograms() {
    return this.store.listPrograms();
  }

  async getCalendar(type: string, from?: string, days = 5) {
    const programType = parseProgramType(type);
    const fromDate = from ?? toIsoDate(new Date());
    const key = CACHE_KEYS.calendar(programType, fromDate, days);
    const cached = await this.cache.get(key);
    if (cached) return cached;
    const result = this.store.getCalendar(programType, fromDate, days);
    await this.cache.set(key, result, CACHE_TTL_MS);
    return result;
  }

  async getDetail(type: string) {
    const programType = parseProgramType(type);
    const key = CACHE_KEYS.detail(programType);
    const cached = await this.cache.get(key);
    if (cached) return cached;
    const result = this.store.getDetail(programType);
    await this.cache.set(key, result, CACHE_TTL_MS);
    return result;
  }

  async moveSession(sessionId: string, dto: MoveSessionDto) {
    const session = this.store.getSession(sessionId);
    if (!session) throw new NotFoundException('SESSION_NOT_FOUND');

    let targetDate = dto.targetDate;
    if (!targetDate && dto.targetWeekday) {
      const weekday = dto.targetWeekday.toUpperCase() as WEEKDAY;
      if (!(weekday in WEEKDAY_INDEX)) {
        throw new BadRequestException('INVALID_WEEKDAY');
      }
      const current = new Date(session.date + 'T12:00:00');
      const currentIdx = current.getDay();
      const targetIdx = WEEKDAY_INDEX[weekday];
      let delta = targetIdx - currentIdx;
      if (delta < -3) delta += 7;
      if (delta > 3) delta -= 7;
      current.setDate(current.getDate() + delta);
      targetDate = toIsoDate(current);
    }
    if (!targetDate) {
      throw new BadRequestException('TARGET_DATE_OR_WEEKDAY_REQUIRED');
    }

    const updated = this.store.moveSession(sessionId, targetDate);
    await this.invalidateCache();
    return updated;
  }

  async completeExercise(exerciseId: string) {
    try {
      const exercise = this.store.completeExercise(exerciseId);
      await this.invalidateCache();
      return {
        exercise,
        promptFeedback: true,
        message: 'Confirm how the exercise went',
      };
    } catch {
      throw new NotFoundException('EXERCISE_NOT_FOUND');
    }
  }

  async submitFeedback(exerciseId: string, dto: FeedbackDto) {
    if (
      ![
        PERFORMANCE_STATUS.GOOD,
        PERFORMANCE_STATUS.SO_SO,
        PERFORMANCE_STATUS.BAD,
      ].includes(dto.status)
    ) {
      throw new BadRequestException('INVALID_STATUS');
    }
    try {
      const adjustments = dto.adjustments ?? {};
      if (dto.notes) adjustments.notes = dto.notes;
      const exercise = this.store.submitFeedback(
        exerciseId,
        dto.status,
        adjustments,
      );
      await this.invalidateCache();
      return exercise;
    } catch {
      throw new NotFoundException('EXERCISE_NOT_FOUND');
    }
  }

  private async invalidateCache(): Promise<void> {
    const store = this.cache as Cache & {
      stores?: Array<{ clear?: () => Promise<void> }>;
      clear?: () => Promise<void>;
    };
    if (typeof store.clear === 'function') {
      await store.clear();
      return;
    }
    const nestedClear = store.stores?.[0]?.clear;
    if (typeof nestedClear === 'function') {
      await nestedClear.call(store.stores![0]);
    }
  }
}
