import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { FeedbackDto } from './dto/feedback.dto';
import { MoveSessionDto } from './dto/move-session.dto';
import { RearrangeDto } from './dto/rearrange.dto';
import { ProgramsService } from './programs.service';

@Controller()
export class ProgramsController {
  constructor(private readonly programsService: ProgramsService) {}

  @Get('health')
  health() {
    return { status: 'ok' };
  }

  @Get('programs')
  listPrograms() {
    return this.programsService.listPrograms();
  }

  @Get('programs/:type/calendar')
  getCalendar(
    @Param('type') type: string,
    @Query('from') from?: string,
    @Query('days') days?: string,
  ) {
    return this.programsService.getCalendar(
      type,
      from,
      days ? Number(days) : 5,
    );
  }

  @Get('programs/:type/detail')
  getDetail(@Param('type') type: string) {
    return this.programsService.getDetail(type);
  }

  @Get('programs/:type/rearrange')
  getRearrangeLayout(@Param('type') type: string) {
    return this.programsService.getRearrangeLayout(type);
  }

  @Post('programs/:type/rearrange')
  rearrangeSchedule(@Param('type') type: string, @Body() dto: RearrangeDto) {
    return this.programsService.rearrangeSchedule(type, dto);
  }

  @Patch('sessions/:id/move')
  moveSession(@Param('id') id: string, @Body() dto: MoveSessionDto) {
    return this.programsService.moveSession(id, dto);
  }

  @Post('exercises/:id/complete')
  completeExercise(@Param('id') id: string) {
    return this.programsService.completeExercise(id);
  }

  @Post('exercises/:id/feedback')
  submitFeedback(@Param('id') id: string, @Body() dto: FeedbackDto) {
    return this.programsService.submitFeedback(id, dto);
  }
}
