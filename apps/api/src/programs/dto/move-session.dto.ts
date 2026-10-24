import { IsISO8601, IsOptional, IsString } from 'class-validator';

export class MoveSessionDto {
  @IsOptional()
  @IsISO8601()
  targetDate?: string;

  @IsOptional()
  @IsString()
  targetWeekday?: string;
}
