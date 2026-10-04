import { AdminUsersService } from './admin-users.service';

describe('AdminUsersService', () => {
  const users = {
    listUsers: jest.fn(),
    changeRole: jest.fn(),
    getAuditHistory: jest.fn(),
  };
  const service = new AdminUsersService(users as never);

  beforeEach(() => jest.clearAllMocks());

  it('delegates user listing to the Firestore user service', async () => {
    users.listUsers.mockResolvedValue({ items: [], page: 1, pageSize: 10, total: 0 });

    await expect(service.listUsers({ role: 'ADMIN', page: 1, pageSize: 10 }))
      .resolves.toEqual({ items: [], page: 1, pageSize: 10, total: 0 });

    expect(users.listUsers).toHaveBeenCalledWith({ role: 'ADMIN', page: 1, pageSize: 10 });
  });

  it('delegates role changes to the Firestore user service', async () => {
    users.changeRole.mockResolvedValue({ id: 'target-1', role: 'ADMIN' });

    await expect(service.changeRole('target-1', 'firebase-actor', 'ADMIN'))
      .resolves.toEqual({ id: 'target-1', role: 'ADMIN' });

    expect(users.changeRole).toHaveBeenCalledWith('target-1', 'firebase-actor', 'ADMIN');
  });

  it('delegates audit history to the Firestore user service', async () => {
    users.getAuditHistory.mockResolvedValue([]);

    await expect(service.getAuditHistory()).resolves.toEqual([]);
    expect(users.getAuditHistory).toHaveBeenCalledTimes(1);
  });
});
