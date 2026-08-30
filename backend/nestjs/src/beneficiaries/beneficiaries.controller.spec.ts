import { BeneficiariesController } from './beneficiaries.controller';

describe('BeneficiariesController', () => {
  const service = {
    findAll: jest.fn(),
    findOne: jest.fn(),
  };

  const controller = new BeneficiariesController(service as any);

  beforeEach(() => jest.clearAllMocks());

  it('converts year query parameter to a number and forwards filters', () => {
    controller.findAll('cause-1', '2025', 'rahul', 'name_asc');

    expect(service.findAll).toHaveBeenCalledWith({
      causeId: 'cause-1',
      year: 2025,
      search: 'rahul',
      sort: 'name_asc',
    });
  });

  it('forwards beneficiary id for detail lookup', () => {
    controller.findOne('beneficiary-1');

    expect(service.findOne).toHaveBeenCalledWith('beneficiary-1');
  });
});
