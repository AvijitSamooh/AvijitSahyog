import { validate } from 'class-validator';

import { CreateHelpApplicationDto } from './create-help-application.dto';
import { ResubmitHelpApplicationDto } from './resubmit-help-application.dto';

const seededRuleId = '00000000-0000-0000-0000-000000001007';
const generatedRuleId = '550e8400-e29b-41d4-a716-446655440000';

describe('help application rule ID validation', () => {
  it('accepts seeded rule UUIDs that are valid UUIDs but not version 4', async () => {
    const create = new CreateHelpApplicationDto();
    create.acceptedRuleIds = [seededRuleId];

    const resubmit = new ResubmitHelpApplicationDto();
    resubmit.acceptedRuleIds = [seededRuleId];

    await expect(validate(create)).resolves.toEqual([]);
    await expect(validate(resubmit)).resolves.toEqual([]);
  });

  it('accepts generated version 4 rule UUIDs', async () => {
    const create = new CreateHelpApplicationDto();
    create.acceptedRuleIds = [generatedRuleId];

    const resubmit = new ResubmitHelpApplicationDto();
    resubmit.acceptedRuleIds = [generatedRuleId];

    await expect(validate(create)).resolves.toEqual([]);
    await expect(validate(resubmit)).resolves.toEqual([]);
  });

  it('rejects non-UUID rule identifiers', async () => {
    const create = new CreateHelpApplicationDto();
    create.acceptedRuleIds = ['rule-1'];

    const errors = await validate(create);

    expect(errors).toHaveLength(1);
    expect(errors[0].property).toBe('acceptedRuleIds');
  });
});
