import { UnauthorizedException } from '@nestjs/common';
import { FirebaseAuthGuard } from './firebase-auth.guard';

describe('FirebaseAuthGuard', () => {
  const verifier = { verify: jest.fn() } as any;
  const guard = new FirebaseAuthGuard(verifier);

  beforeEach(() => jest.clearAllMocks());

  function context(headers: Record<string, string> = {}) {
    const request: any = { headers };
    return {
      switchToHttp: () => ({ getRequest: () => request }),
      request,
    } as any;
  }

  it('rejects requests without a bearer token', async () => {
    await expect(guard.canActivate(context())).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('attaches the verified identity to the request', async () => {
    verifier.verify.mockResolvedValue({ uid: 'firebase-user-1', email: 'user@example.com' });
    const execution = context({ authorization: 'Bearer token-123' });
    await expect(guard.canActivate(execution)).resolves.toBe(true);
    expect(verifier.verify).toHaveBeenCalledWith('token-123');
    expect(execution.request.user.uid).toBe('firebase-user-1');
  });
});
