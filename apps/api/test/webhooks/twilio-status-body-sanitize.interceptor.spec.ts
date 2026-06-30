import { of } from 'rxjs';
import { TwilioStatusBodySanitizeInterceptor } from '../../src/webhooks/interceptors/twilio-status-body-sanitize.interceptor';

describe('TwilioStatusBodySanitizeInterceptor', () => {
  it('strips unknown form fields before validation', (done) => {
    const req = {
      body: {
        MessageSid: 'SM1',
        MessageStatus: 'delivered',
        ExtraField: 'drop-me',
      },
    };
    const interceptor = new TwilioStatusBodySanitizeInterceptor();
    interceptor
      .intercept(
        {
          switchToHttp: () => ({ getRequest: () => req }),
        } as never,
        { handle: () => of(null) },
      )
      .subscribe(() => {
        expect(req.body).toEqual({
          MessageSid: 'SM1',
          MessageStatus: 'delivered',
        });
        done();
      });
  });
});
