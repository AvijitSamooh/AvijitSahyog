import { BadRequestException } from '@nestjs/common';
import type { Request } from 'express';
import { AdminUsersController } from './admin-users.controller';

describe('AdminUsersController', () => {
  const service = {
    listUsers: jest.fn(),
    changeRole: jest.fn(),
    getAuditHistory: jest.fn(),
  };

  beforeEach(() => jest.clearAllMocks());

  it('validates and normalizes admin user query input before the service call', async () => {
    service.listUsers.mockResolvedValue({ items: [] });
    const controller = new AdminUsersController(service as never);

    await controller.listUsers({
      query: { search: '  alice ', role: 'USER', page: '2', pageSize: '10' },
    } as unknown as Request);

    expect(service.listUsers).toHaveBeenCalledWith(expect.objectContaining({
      search: 'alice', role: 'USER', page: 2, pageSize: 10,
    }));
  });

  it('rejects invalid query input before the service call', async () => {
    const controller = new AdminUsersController(service as never);
    await expect(controller.listUsers({ query: { pageSize: '21' } } as unknown as Request))
      .rejects.toBeInstanceOf(BadRequestException);
    expect(service.listUsers).not.toHaveBeenCalled();
  });

  it('validates role changes before the service call', async () => {
    service.changeRole.mockResolvedValue({ id: 'user-1' });
    const controller = new AdminUsersController(service as never);

    await controller.changeRole(
      'user-1',
      { role: 'ADMIN' },
      { user: { uid: 'actor-1' } } as never,
    );

    expect(service.changeRole).toHaveBeenCalledWith('user-1', 'actor-1', 'ADMIN');
  });

  it('rejects invalid role changes before the service call', async () => {
    const controller = new AdminUsersController(service as never);
    await expect(controller.changeRole(
      'user-1',
      { role: 'SUPER_ADMIN' } as never,
      { user: { uid: 'actor-1' } } as never,
    )).rejects.toBeInstanceOf(BadRequestException);
    expect(service.changeRole).not.toHaveBeenCalled();
  });
});
