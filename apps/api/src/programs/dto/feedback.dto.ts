import { IsEnum, IsObject, IsOptional, IsString } from 'class-validator';
import { PERFORMANCE_STATUS } from '../../common/enums/performance-status.enum';

export class FeedbackDto {
  @IsEnum(PERFORMANCE_STATUS)
  status!: PERFORMANCE_STATUS;

  @IsOptional()
  @IsObject()
  adjustments?: {
    weight?: string;
    reps?: string;
    sets?: string;
    distance?: string;
    pace?: string;
    duration?: string;
    notes?: string;
  };

  @IsOptional()
  @IsString()
  notes?: string;
}
