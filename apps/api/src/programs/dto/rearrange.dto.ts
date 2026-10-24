import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsInt,
  IsString,
  ValidateNested,
} from 'class-validator';

export class RearrangeAssignmentDto {
  @IsInt()
  dayNumber!: number;

  @IsString()
  weekday!: string;
}

export class RearrangeDto {
  @IsString()
  blockId!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => RearrangeAssignmentDto)
  assignments!: RearrangeAssignmentDto[];
}
