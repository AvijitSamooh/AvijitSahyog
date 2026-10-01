import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { HelpApplicationTypeDto } from './dto/create-help-application.dto';
import { CreateApplicationRuleDto, SUPPORTED_RULE_LANGUAGES, UpdateApplicationRuleDto, validateRuleTranslations } from './dto/application-rule.dto';
import { MemoryCache } from '../common/memory-cache';

@Injectable()
export class ApplicationRulesService {
  private readonly cache = new MemoryCache();
  private static readonly FRESH_MS = 10 * 60 * 1000;
  private static readonly STALE_MS = 24 * 60 * 60 * 1000;

  constructor(private readonly prisma: PrismaService) {}

  async list(type: HelpApplicationTypeDto, language = 'en') {
    const requested = SUPPORTED_RULE_LANGUAGES.includes(language as any) ? language : 'en';
    const rules = await this.cache.getOrLoad(
      `rules:${type}`,
      async () => this.prisma.applicationRule.findMany({
      where: { type, isActive: true },
      orderBy: { displayOrder: 'asc' },
      include: { translations: { include: { language: true } } },
      }),
      ApplicationRulesService.FRESH_MS,
      ApplicationRulesService.STALE_MS,
    );
    return rules.map((rule) => {
      const translation = rule.translations.find((item) => item.language.code === requested) ??
        rule.translations.find((item) => item.language.code === 'en');
      return { id: rule.id, type: rule.type, displayOrder: rule.displayOrder, text: translation?.text ?? '' };
    });
  }

  async listAdmin(type: HelpApplicationTypeDto) {
    const rules = await this.prisma.applicationRule.findMany({
      where: { type },
      orderBy: { displayOrder: 'asc' },
      include: { translations: { include: { language: true } } },
    });
    return rules.map((rule) => ({
      id: rule.id,
      type: rule.type,
      displayOrder: rule.displayOrder,
      isActive: rule.isActive,
      translations: rule.translations.map((translation) => ({ language: translation.language.code, text: translation.text })),
    }));
  }

  async create(dto: CreateApplicationRuleDto) {
    let translations;
    try { translations = validateRuleTranslations(dto.translations); }
    catch (error) { throw new BadRequestException((error as Error).message); }
    const result = await this.prisma.applicationRule.create({
      data: {
        type: dto.type,
        displayOrder: dto.displayOrder,
        isActive: dto.isActive ?? true,
        translations: { create: translations.map((item) => ({ text: item.text, language: { connect: { code: item.language } } })) },
      },
      include: { translations: { include: { language: true } } },
    });
    this.cache.invalidate('rules:');
    return result;
  }

  async update(id: string, dto: UpdateApplicationRuleDto) {
    const existing = await this.prisma.applicationRule.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Application rule not found.');
    let translations;
    try { translations = validateRuleTranslations(dto.translations); }
    catch (error) { throw new BadRequestException((error as Error).message); }
    const result = await this.prisma.applicationRule.update({
      where: { id },
      data: {
        ...(dto.displayOrder === undefined ? {} : { displayOrder: dto.displayOrder }),
        ...(dto.isActive === undefined ? {} : { isActive: dto.isActive }),
        translations: {
          deleteMany: {},
          create: translations.map((item) => ({ text: item.text, language: { connect: { code: item.language } } })),
        },
      },
      include: { translations: { include: { language: true } } },
    });
    this.cache.invalidate('rules:');
    return result;
  }

  async remove(id: string) {
    const existing = await this.prisma.applicationRule.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Application rule not found.');
    await this.prisma.applicationRule.update({ where: { id }, data: { isActive: false } });
    this.cache.invalidate('rules:');
    return { id, deleted: true };
  }
}
