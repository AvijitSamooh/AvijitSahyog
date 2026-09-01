import { TestingModule, Test } from '@nestjs/testing';
import { AppModule } from './../src/app.module';

describe('Application bootstrap dependency graph', () => {
  let moduleFixture: TestingModule;

  afterEach(async () => {
    await moduleFixture?.close();
  });

  it('compiles the complete Nest application module graph', async () => {
    moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    expect(moduleFixture).toBeDefined();
  });
});
