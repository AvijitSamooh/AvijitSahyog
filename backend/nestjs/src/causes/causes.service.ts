import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CreateCauseDto } from './dto/create-cause.dto';
import { UpdateCauseDto } from './dto/update-cause.dto';
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
                media: {
                  orderBy: [{ purpose: 'asc' }, { isPrimary: 'desc' }, { displayOrder: 'asc' }],
                  include: { media: true },
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
        logoUrl: this.organisationLogoUrl(organisation) ?? organisation.logoUrl,
        gallery: this.organisationGallery(organisation),
        websiteUrl: organisation.websiteUrl,
        phone: organisation.phone,
        mobileNumber: organisation.mobileNumber,
        email: organisation.email,
        address: organisation.address,
        city: organisation.city,
        state: organisation.state,
        country: organisation.country,
        latitude: organisation.latitude == null ? null : Number(organisation.latitude),
        longitude: organisation.longitude == null ? null : Number(organisation.longitude),
        ...this.translation(organisation.translations, languageCode),
      })),
    };
  }

  async findAllForAdmin() {
    return this.prisma.cause.findMany({
      orderBy: { displayOrder: 'asc' },
      include: {
        translations: {
          include: { language: true },
          orderBy: { language: { code: 'asc' } },
        },
      },
    });
  }

  async findOneForAdmin(id: string) {
    const cause = await this.prisma.cause.findUnique({
      where: { id },
      include: {
        translations: {
          include: { language: true },
          orderBy: { language: { code: 'asc' } },
        },
      },
    });

    if (!cause) {
      throw new NotFoundException(`Cause '${id}' not found`);
    }

    return cause;
  }

  async create(dto: CreateCauseDto) {
    this.validateTranslations(dto.translations);

    const existing = await this.prisma.cause.findUnique({
      where: { slug: dto.slug },
      select: { id: true },
    });

    if (existing) {
      throw new ConflictException(`Cause slug '${dto.slug}' already exists`);
    }

    const languages = await this.resolveLanguages(dto.translations);

    return this.prisma.cause.create({
      data: {
        slug: dto.slug,
        displayOrder: dto.displayOrder ?? 0,
        translations: {
          create: dto.translations.map((translation) => ({
            languageId: languages.get(translation.languageCode)!,
            name: translation.name,
            description: translation.description,
          })),
        },
      },
      include: {
        translations: { include: { language: true } },
      },
    });
  }

  async update(id: string, dto: UpdateCauseDto) {
    await this.findOneForAdmin(id);

    if (dto.translations) {
      this.validateTranslations(dto.translations);
      await this.resolveLanguages(dto.translations);
    }

    if (dto.slug) {
      const existing = await this.prisma.cause.findUnique({
        where: { slug: dto.slug },
        select: { id: true },
      });
      if (existing && existing.id !== id) {
        throw new ConflictException(`Cause slug '${dto.slug}' already exists`);
      }
    }

    return this.prisma.$transaction(async (tx: any) => {
      if (dto.translations) {
        const languages = await tx.language.findMany({
          where: { code: { in: dto.translations.map((item) => item.languageCode) } },
          select: { id: true, code: true },
        });
        const languageIds = new Map(languages.map((language: any) => [language.code, language.id]));

        for (const translation of dto.translations) {
          await tx.causeTranslation.upsert({
            where: {
              causeId_languageId: {
                causeId: id,
                languageId: languageIds.get(translation.languageCode)!,
              },
            },
            update: {
              name: translation.name,
              description: translation.description,
            },
            create: {
              causeId: id,
              languageId: languageIds.get(translation.languageCode)!,
              name: translation.name,
              description: translation.description,
            },
          });
        }
      }

      return tx.cause.update({
        where: { id },
        data: {
          ...(dto.slug !== undefined ? { slug: dto.slug } : {}),
          ...(dto.displayOrder !== undefined
            ? { displayOrder: dto.displayOrder }
            : {}),
          ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
        },
        include: {
          translations: { include: { language: true } },
        },
      });
    });
  }

  async setActive(id: string, isActive: boolean) {
    await this.findOneForAdmin(id);

    return this.prisma.cause.update({
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

  private toResponse(entity: any, languageCode: string) {
    return {
      id: entity.id,
      slug: entity.slug,
      displayOrder: entity.displayOrder,
      ...this.translation(entity.translations, languageCode),
    };
  }

  private organisationLogoUrl(organisation: any) {
    const relation = organisation.media?.find(
      (item: any) => item.purpose === 'LOGO' && item.isPrimary,
    ) ?? organisation.media?.find((item: any) => item.purpose === 'LOGO');
    if (!relation?.media) return null;
    const base = process.env.R2_PUBLIC_BASE_URL?.replace(/\/$/, '');
    return base ? `${base}/${relation.media.storageKey}` : relation.media.storageKey;
  }

  private organisationGallery(organisation: any) {
    const base = process.env.R2_PUBLIC_BASE_URL?.replace(/\/$/, '');
    return (organisation.media ?? [])
      .filter((item: any) => item.purpose === 'GALLERY' && item.media)
      .sort((a: any, b: any) => a.displayOrder - b.displayOrder)
      .map((item: any) => ({
        id: item.media.id,
        url: base ? `${base}/${item.media.storageKey}` : item.media.storageKey,
        mimeType: item.media.mimeType,
        width: item.media.width,
        height: item.media.height,
      }));
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
