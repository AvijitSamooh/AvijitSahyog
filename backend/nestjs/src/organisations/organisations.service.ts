import { Injectable, NotFoundException } from '@nestjs/common';
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
