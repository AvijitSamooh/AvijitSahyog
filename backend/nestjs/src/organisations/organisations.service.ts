import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CreateOrganisationDto } from './dto/create-organisation.dto';
import { UpdateOrganisationDto } from './dto/update-organisation.dto';
import { PrismaService } from '../prisma/prisma.service';
import type { AttachOrganisationMediaDto } from './dto/attach-organisation-media.dto';
import type { UpdateOrganisationMediaDto } from './dto/update-organisation-media.dto';

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
        media: { orderBy: [{ purpose: 'asc' }, { isPrimary: 'desc' }, { displayOrder: 'asc' }], include: { media: true } },
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
        media: { orderBy: [{ purpose: 'asc' }, { isPrimary: 'desc' }, { displayOrder: 'asc' }], include: { media: true } },
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
    const slug = await this.generateUniqueSlug(dto.slug, dto.translations);
    const languages = await this.resolveLanguages(dto.translations);
    const mobileNumber = this.normalizeMobileNumber(dto.mobileNumber);
    return this.prisma.organisation.create({
      data: {
        slug,
        logoUrl: dto.logoUrl,
        websiteUrl: dto.websiteUrl,
        phone: dto.phone,
        mobileNumber,
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
          ...(dto.mobileNumber !== undefined
            ? { mobileNumber: this.normalizeMobileNumber(dto.mobileNumber) }
            : {}),
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
  async updateCauses(id: string, causeIds: string[]) {
    await this.findOneForAdmin(id);
    if (new Set(causeIds).size !== causeIds.length) {
      throw new BadRequestException('Each cause may only appear once.');
    }

    const causes = await this.prisma.cause.findMany({
      where: { id: { in: causeIds } },
      select: { id: true },
    });
    if (causes.length !== causeIds.length) {
      throw new BadRequestException('One or more causes do not exist.');
    }

    return this.prisma.$transaction(async (tx: any) => {
      await tx.organisationCause.deleteMany({ where: { organisationId: id } });
      if (causeIds.length) {
        await tx.organisationCause.createMany({
          data: causeIds.map((causeId, index) => ({
            organisationId: id,
            causeId,
            displayOrder: index,
          })),
        });
      }
      return tx.organisation.findUnique({
        where: { id },
        include: {
          causes: {
            orderBy: { displayOrder: 'asc' },
            include: { cause: { select: { id: true, slug: true } } },
          },
        },
      });
    });
  }


  async listMedia(id: string) {
    await this.findOneForAdmin(id);
    return this.prisma.organisationMedia.findMany({
      where: { organisationId: id },
      orderBy: [{ purpose: 'asc' }, { displayOrder: 'asc' }, { createdAt: 'asc' }],
      include: { media: true },
    });
  }

  async attachMedia(id: string, dto: AttachOrganisationMediaDto) {
    await this.findOneForAdmin(id);
    if (!dto.mediaId) throw new BadRequestException('Media id is required.');

    const media = await this.prisma.media.findUnique({
      where: { id: dto.mediaId },
      select: { id: true },
    });
    if (!media) throw new NotFoundException(`Media '${dto.mediaId}' not found`);

    const existing = await this.prisma.organisationMedia.findUnique({
      where: { organisationId_mediaId: { organisationId: id, mediaId: dto.mediaId } },
      select: { id: true },
    });
    if (existing) throw new ConflictException('Media is already attached to this organisation.');

    const purpose = dto.purpose ?? 'GALLERY';
    const displayOrder = dto.displayOrder ?? 0;
    const isPrimary = dto.isPrimary ?? false;

    return this.prisma.$transaction(async (tx: any) => {
      if (isPrimary) {
        await tx.organisationMedia.updateMany({
          where: { organisationId: id, purpose, isPrimary: true },
          data: { isPrimary: false },
        });
      }
      return tx.organisationMedia.create({
        data: { organisationId: id, mediaId: dto.mediaId, purpose, displayOrder, isPrimary },
        include: { media: true },
      });
    });
  }

  async updateMedia(id: string, mediaId: string, dto: UpdateOrganisationMediaDto) {
    await this.findOneForAdmin(id);
    const existing = await this.prisma.organisationMedia.findUnique({
      where: { organisationId_mediaId: { organisationId: id, mediaId } },
      select: { id: true, purpose: true },
    });
    if (!existing) throw new NotFoundException('Media is not attached to this organisation.');

    const purpose = dto.purpose ?? existing.purpose;
    return this.prisma.$transaction(async (tx: any) => {
      if (dto.isPrimary === true) {
        await tx.organisationMedia.updateMany({
          where: { organisationId: id, purpose, isPrimary: true, NOT: { mediaId } },
          data: { isPrimary: false },
        });
      }
      return tx.organisationMedia.update({
        where: { organisationId_mediaId: { organisationId: id, mediaId } },
        data: {
          ...(dto.purpose !== undefined ? { purpose: dto.purpose } : {}),
          ...(dto.displayOrder !== undefined ? { displayOrder: dto.displayOrder } : {}),
          ...(dto.isPrimary !== undefined ? { isPrimary: dto.isPrimary } : {}),
        },
        include: { media: true },
      });
    });
  }

  async removeMedia(id: string, mediaId: string) {
    await this.findOneForAdmin(id);
    const existing = await this.prisma.organisationMedia.findUnique({
      where: { organisationId_mediaId: { organisationId: id, mediaId } },
      select: { id: true },
    });
    if (!existing) throw new NotFoundException('Media is not attached to this organisation.');
    return this.prisma.organisationMedia.delete({
      where: { organisationId_mediaId: { organisationId: id, mediaId } },
    });
  }

  async setActive(id: string, isActive: boolean) {
    await this.findOneForAdmin(id);
    return this.prisma.organisation.update({
      where: { id },
      data: { isActive },
    });
  }

  private normalizeMobileNumber(value: string | undefined): string | null {
    if (value === undefined || value.trim() === '') return null;

    const digits = value.replace(/\D/g, '');
    const indianMobile = /^[6-9]\d{9}$/;
    const indianWithCountryCode = /^91[6-9]\d{9}$/;

    if (indianMobile.test(digits)) return `+91${digits}`;
    if (indianWithCountryCode.test(digits)) return `+${digits}`;

    throw new BadRequestException(
      'Mobile number must be a valid 10-digit Indian mobile number.',
    );
  }

  private async generateUniqueSlug(
    requestedSlug: string | undefined,
    translations: { languageCode: string; name: string }[],
  ) {
    const source =
      requestedSlug?.trim() ??
      translations.find((translation) => translation.languageCode === 'en')?.name ??
      translations[0]?.name;

    const base = source
      ?.trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');

    if (!base) {
      throw new BadRequestException('Organisation name must contain letters or numbers.');
    }

    for (let suffix = 1; ; suffix += 1) {
      const slug = suffix === 1 ? base : `${base}-${suffix}`;
      const existing = await this.prisma.organisation.findUnique({
        where: { slug },
        select: { id: true },
      });
      if (!existing) return slug;
    }
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
      logoUrl: this.primaryMediaUrl(entity.media, 'LOGO') ?? entity.logoUrl,
      gallery: this.galleryMedia(entity.media, 'GALLERY'),
      websiteUrl: entity.websiteUrl,
      phone: entity.phone,
      mobileNumber: entity.mobileNumber,
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

  private mediaResponse(media: any) {
    const base = process.env.R2_PUBLIC_BASE_URL?.replace(/\/$/, '');
    return {
      id: media.id,
      url: base ? `${base}/${media.storageKey}` : media.storageKey,
      mimeType: media.mimeType,
      width: media.width,
      height: media.height,
    };
  }

  private primaryMediaUrl(relations: any[] | undefined, purpose: string) {
    const relation = relations?.find((item) => item.purpose === purpose && item.isPrimary)
      ?? relations?.find((item) => item.purpose === purpose);
    return relation ? this.mediaResponse(relation.media).url : null;
  }

  private galleryMedia(relations: any[] | undefined, purpose: string) {
    return (relations ?? [])
      .filter((item) => item.purpose === purpose)
      .sort((a, b) => a.displayOrder - b.displayOrder)
      .map((item) => this.mediaResponse(item.media));
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
