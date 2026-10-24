import { Module } from '@nestjs/common';
import { MemoryStore } from '../store/memory.store';
import { ProgramsController } from './programs.controller';
import { ProgramsService } from './programs.service';

@Module({
  controllers: [ProgramsController],
  providers: [ProgramsService, MemoryStore],
  exports: [ProgramsService, MemoryStore],
})
export class ProgramsModule {}
