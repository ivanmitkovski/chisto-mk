import { Controller, Get } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { AppService } from './app.service';
import { ApiStandardHttpErrorResponses } from './common/openapi/standard-http-error-responses.decorator';

@ApiTags('system')
@ApiStandardHttpErrorResponses()
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @SkipThrottle()
  @ApiOperation({ summary: 'Root health / version probe' })
  getHello(): { message: string } {
    return this.appService.getHello();
  }
}
