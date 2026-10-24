import { CacheModule } from '@nestjs/cache-manager';
import { Module } from '@nestjs/common';
import { ProgramsModule } from './programs/programs.module';

@Module({
  imports: [
    CacheModule.register({
      isGlobal: true,
      ttl: 30_000,
    }),
    ProgramsModule,
  ],
})
export class AppModule {}
