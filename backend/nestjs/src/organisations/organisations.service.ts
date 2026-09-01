import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CreateOrganisationDto } from './dto/create-organisation.dto';
import { UpdateOrganisationDto } from './dto/update-organisation.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class OrganisationsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(languageCode = 'en') {
    const organisations = await this.prisma.organisation.findMany({
      where: { isActive: true },
      orderBy: { displayOrder: 'asc' },
      include: {
        translations: {
          where: { language: { code: { in: [languageCode, 'en'] } } },
          include: { language: true },
        },
        causes: {
          where: {
            isActive: true,
            cause: { isActive: true },
          },
          orderBy: { displayOrder: 'asc' },
          include: {
            cause: {
              include: {
                translations: {
                  where: { language: { code: { in: [languageCode, 'en'] } } },
                  include: { language: true },
                },
              },
            },
          },
        },
      },
    });

    return organisations.map((organisation) => ({
      ...this.baseResponse(organisation, languageCode),
      causes: organisation.causes.map(({ cause }) => ({
        id: cause.id,
        slug: cause.slug,
        displayOrder: cause.displayOrder,
        ...this.translation(cause.translations, languageCode),
      })),
    }));
  }

  async findOne(slug: string, languageCode = 'en') {
    const organisation = await this.prisma.organisation.findFirst({
      where: { slug, isActive: true },
      include: {
        translations: {
          where: { language: { code: { in: [languageCode, 'en'] } } },
          include: { language: true },
        },
        causes: {
          where: {
            isActive: true,
            cause: { isActive: true },
          },
          orderBy: { displayOrder: 'asc' },
          include: {
            cause: {
              include: {
                translations: {
                  where: { language: { code: { in: [languageCode, 'en'] } } },
                  include: { language: true },
                },
              },
            },
          },
        },
      },
    });

    if (!organisation) {
      throw new NotFoundException(`Organisation '${slug}' not found`);
    }

    return {
      ...this.baseResponse(organisation, languageCode),
      causes: organisation.causes.map(({ cause }) => ({
        id: cause.id,
        slug: cause.slug,
        displayOrder: cause.displayOrder,
        ...this.translation(cause.translations, languageCode),
      })),
    };
  }

  async findAllForAdmin() {
    return this.prisma.organisation.findMany({
      orderBy: { displayOrder: 'asc' },
      include: {
        translations: {
          include: { language: true },
          orderBy: { language: { code: 'asc' } },
        },
        causes: {
          orderBy: { displayOrder: 'asc' },
          include: { cause: { select: { id: true, slug: true } } },
        },
      },
    });
  }

  async findOneForAdmin(id: string) {
    const organisation = await this.prisma.organisation.findUnique({
      where: { id },
      include: {
        translations: { include: { language: true } },
        causes: {
          orderBy: { displayOrder: 'asc' },
          include: { cause: { select: { id: true, slug: true } } },
        },
      },
    });

    if (!organisation) {
      throw new NotFoundException(`Organisation '${id}' not found`);
    }
    return organisation;
  }

  async create(dto: CreateOrganisationDto) {
    this.validateTranslations(dto.translations);
    const existing = await this.prisma.organisation.findUnique({
      where: { slug: dto.slug },
      select: { id: true },
    });
    if (existing) {
      throw new ConflictException(`Organisation slug '${dto.slug}' already exists`);
    }

    const languages = await this.resolveLanguages(dto.translations);
    return this.prisma.organisation.create({
      data: {
        slug: dto.slug,
        logoUrl: dto.logoUrl,
        websiteUrl: dto.websiteUrl,
        phone: dto.phone,
        email: dto.email,
        address: dto.address,
        city: dto.city,
        state: dto.state,
        country: dto.country ?? 'IN',
        displayOrder: dto.displayOrder ?? 0,
        translations: {
          create: dto.translations.map((translation) => ({
            languageId: languages.get(translation.languageCode)!,
            name: translation.name,
            description: translation.description,
          })),
        },
      },
      include: { translations: { include: { language: true } } },
    });
  }

  async update(id: string, dto: UpdateOrganisationDto) {
    await this.findOneForAdmin(id);

    if (dto.translations) {
      this.validateTranslations(dto.translations);
      await this.resolveLanguages(dto.translations);
    }

    if (dto.slug) {
      const existing = await this.prisma.organisation.findUnique({
        where: { slug: dto.slug },
        select: { id: true },
      });
      if (existing && existing.id !== id) {
        throw new ConflictException(`Organisation slug '${dto.slug}' already exists`);
      }
    }

    return this.prisma.$transaction(async (tx: any) => {
      if (dto.translations) {
        const languages = await tx.language.findMany({
          where: { code: { in: dto.translations.map((item) => item.languageCode) } },
          select: { id: true, code: true },
        });
        const ids = new Map(languages.map((language: any) => [language.code, language.id]));

        for (const translation of dto.translations) {
          await tx.organisationTranslation.upsert({
            where: {
              organisationId_languageId: {
                organisationId: id,
                languageId: ids.get(translation.languageCode)!,
              },
            },
            update: {
              name: translation.name,
              description: translation.description,
            },
            create: {
              organisationId: id,
              languageId: ids.get(translation.languageCode)!,
              name: translation.name,
              description: translation.description,
            },
          });
        }
      }

      return tx.organisation.update({
        where: { id },
        data: {
          ...(dto.slug !== undefined ? { slug: dto.slug } : {}),
          ...(dto.logoUrl !== undefined ? { logoUrl: dto.logoUrl } : {}),
          ...(dto.websiteUrl !== undefined ? { websiteUrl: dto.websiteUrl } : {}),
          ...(dto.phone !== undefined ? { phone: dto.phone } : {}),
          ...(dto.email !== undefined ? { email: dto.email } : {}),
          ...(dto.address !== undefined ? { address: dto.address } : {}),
          ...(dto.city !== undefined ? { city: dto.city } : {}),
          ...(dto.state !== undefined ? { state: dto.state } : {}),
          ...(dto.country !== undefined ? { country: dto.country } : {}),
          ...(dto.displayOrder !== undefined ? { displayOrder: dto.displayOrder } : {}),
          ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
        },
        include: { translations: { include: { language: true } } },
      });
    });
  }

  async setActive(id: string, isActive: boolean) {
    await this.findOneForAdmin(id);
    return this.prisma.organisation.update({
      where: { id },
      data: { isActive },
    });
  }

  private validateTranslations(
    translations: { languageCode: string; name: string }[],
  ) {
    if (!translations?.length) {
      throw new BadRequestException('At least one translation is required.');
    }
    const codes = translations.map((translation) => translation.languageCode);
    if (new Set(codes).size !== codes.length) {
      throw new BadRequestException('Each language may only appear once.');
    }
    if (translations.some((translation) => !translation.name?.trim())) {
      throw new BadRequestException('Translation names are required.');
    }
  }

  private async resolveLanguages(
    translations: { languageCode: string }[],
  ): Promise<Map<string, string>> {
    const codes = translations.map((translation) => translation.languageCode);
    const languages = await this.prisma.language.findMany({
      where: { code: { in: codes }, isActive: true },
      select: { id: true, code: true },
    });
    if (languages.length !== codes.length) {
      throw new BadRequestException('One or more translation languages are unavailable.');
    }
    return new Map(languages.map((language) => [language.code, language.id]));
  }

  private baseResponse(entity: any, languageCode: string) {
    return {
      id: entity.id,
      slug: entity.slug,
      logoUrl: entity.logoUrl,
      websiteUrl: entity.websiteUrl,
      phone: entity.phone,
      email: entity.email,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      country: entity.country,
      latitude: entity.latitude,
      longitude: entity.longitude,
      displayOrder: entity.displayOrder,
      ...this.translation(entity.translations, languageCode),
    };
  }

  private translation(translations: any[], languageCode: string) {
    const translation =
      translations.find((item) => item.language.code === languageCode) ??
      translations.find((item) => item.language.code === 'en');

    return {
      name: translation?.name ?? null,
      description: translation?.description ?? null,
    };
  }
}
