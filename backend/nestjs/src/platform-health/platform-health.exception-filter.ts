import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import { Request, Response } from 'express';
import { PlatformHealthService } from './platform-health.service';

@Catch()
export class PlatformHealthExceptionFilter implements ExceptionFilter {
  constructor(private readonly health: PlatformHealthService) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const request = http.getRequest<Request>();
    const response = http.getResponse<Response>();
    const status = exception instanceof HttpException
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;
    const route = request.originalUrl ?? request.url;
    const type = status === HttpStatus.UNAUTHORIZED
      ? 'AUTH_FAILURE'
      : route.split('?')[0].includes('/admin/media/upload')
        ? 'UPLOAD_FAILURE'
        : 'HTTP_ERROR';
    const exceptionResponse = exception instanceof HttpException ? exception.getResponse() : null;
    const message = typeof exceptionResponse === 'string'
      ? exceptionResponse
      : exception instanceof Error ? exception.message : 'Unhandled application error';

    void this.health.recordEvent({
      type,
      statusCode: status,
      route,
      method: request.method,
      message,
    });

    if (exception instanceof HttpException) {
      response.status(status).json(exceptionResponse);
      return;
    }

    response.status(status).json({ statusCode: status, message: 'Internal server error' });
  }
}
