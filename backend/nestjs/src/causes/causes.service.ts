import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CausesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(languageCode = 'en') {
    const causes = await this.prisma.cause.findMany({
      where: { isActive: true },
      orderBy: { displayOrder: 'asc' },
      include: {
        translations: {
          where: { language: { code: { in: [languageCode, 'en'] } } },
          include: { language: true },
        },
      },
    });

    return causes.map((cause) => this.toResponse(cause, languageCode));
  }

  async findOne(slug: string, languageCode = 'en') {
    const cause = await this.prisma.cause.findFirst({
      where: { slug, isActive: true },
      include: {
        translations: {
          where: { language: { code: { in: [languageCode, 'en'] } } },
          include: { language: true },
        },
        organisations: {
          where: {
            isActive: true,
            organisation: { isActive: true },
          },
          orderBy: { displayOrder: 'asc' },
          include: {
            organisation: {
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

    if (!cause) {
      throw new NotFoundException(`Cause '${slug}' not found`);
    }

    return {
      ...this.toResponse(cause, languageCode),
      organisations: cause.organisations.map(({ organisation }) => ({
        id: organisation.id,
        slug: organisation.slug,
        logoUrl: organisation.logoUrl,
        websiteUrl: organisation.websiteUrl,
        phone: organisation.phone,
        email: organisation.email,
        address: organisation.address,
        city: organisation.city,
        state: organisation.state,
        country: organisation.country,
        latitude: organisation.latitude,
        longitude: organisation.longitude,
        ...this.translation(organisation.translations, languageCode),
      })),
    };
  }

  private toResponse(entity: any, languageCode: string) {
    return {
      id: entity.id,
      slug: entity.slug,
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
