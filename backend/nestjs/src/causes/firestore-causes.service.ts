import { Injectable, NotFoundException } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';

interface Translation {
  name?: string | null;
  description?: string | null;
}

interface CauseDocument {
  id: string;
  slug: string;
  parentId: string | null;
  isActive: boolean;
  displayOrder: number;
  translations?: Record<string, Translation>;
  childIds?: string[];
  organisationIds?: string[];
}

interface OrganisationDocument {
  id: string;
  slug: string;
  logoUrl?: string | null;
  websiteUrl?: string | null;
  phone?: string | null;
  mobileNumber?: string | null;
  email?: string | null;
  address?: string | null;
  city?: string | null;
  state?: string | null;
  country?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  translations?: Record<string, Translation>;
  causeIds?: string[];
  media?: Array<{
    mediaId: string;
    purpose: string;
    displayOrder: number;
    isPrimary: boolean;
  }>;
}

interface MediaDocument {
  id: string;
  storageKey: string;
  mimeType: string;
  width: number | null;
  height: number | null;
}

@Injectable()
export class FirestoreCausesService {
  constructor(private readonly firebase: FirebaseService) {}

  async findAll(languageCode: string) {
    const snapshot = await this.firebase.db
      .collection('causes')
      .where('isActive', '==', true)
      .where('parentId', '==', null)
      .orderBy('displayOrder', 'asc')
      .get();

    const causes = snapshot.docs.map((doc) => doc.data() as CauseDocument);
    const childIds = causes.flatMap((cause) => cause.childIds ?? []);
    const children = await this.getByIds('causes', childIds);

    return causes.map((cause) => ({
      id: cause.id,
      slug: cause.slug,
      parentId: cause.parentId,
      displayOrder: cause.displayOrder,
      ...this.translation(cause.translations, languageCode),
      children: children
        .filter((child) => child.isActive && child.parentId === cause.id)
        .sort((a, b) => a.displayOrder - b.displayOrder)
        .map((child) => ({
          id: child.id,
          slug: child.slug,
          parentId: child.parentId ?? cause.id,
          displayOrder: child.displayOrder,
          ...this.translation(child.translations, languageCode),
        })),
    }));
  }

  async findOne(slug: string, languageCode: string) {
    const snapshot = await this.firebase.db
      .collection('causes')
      .where('slug', '==', slug)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (snapshot.empty) {
      throw new NotFoundException(`Cause '${slug}' not found`);
    }

    const cause = snapshot.docs[0].data() as CauseDocument;
    const [children, organisations] = await Promise.all([
      this.getByIds('causes', cause.childIds ?? []),
      this.getByIds('organisations', cause.organisationIds ?? []),
    ]);

    const activeChildren = children
      .filter((child) => child.isActive && child.parentId === cause.id)
      .sort((a, b) => a.displayOrder - b.displayOrder);

    const activeOrganisations = organisations
      .filter((organisation) => organisation.isActive && (organisation.causeIds ?? []).includes(cause.id))
      .sort((a, b) => this.displayOrderForOrganisation(organisations, a.id) - this.displayOrderForOrganisation(organisations, b.id));

    return {
      id: cause.id,
      slug: cause.slug,
      parentId: cause.parentId,
      displayOrder: cause.displayOrder,
      ...this.translation(cause.translations, languageCode),
      children: activeChildren.map((child) => ({
        id: child.id,
        slug: child.slug,
        parentId: child.parentId ?? cause.id,
        displayOrder: child.displayOrder,
        ...this.translation(child.translations, languageCode),
      })),
      organisations: await Promise.all(
        activeOrganisations.map((organisation) => this.organisationResponse(organisation, languageCode)),
      ),
    };
  }

  private async getByIds<T extends CauseDocument | OrganisationDocument>(
    collection: string,
    ids: string[],
  ): Promise<T[]> {
    if (!ids.length) return [];

    const uniqueIds = [...new Set(ids)];
    const chunks = Array.from({ length: Math.ceil(uniqueIds.length / 30) }, (_, index) =>
      uniqueIds.slice(index * 30, index * 30 + 30),
    );

    const snapshots = await Promise.all(
      chunks.map((chunk) =>
        this.firebase.db.collection(collection).where('__name__', 'in', chunk).get(),
      ),
    );

    const byId = new Map<string, T>();
    snapshots.flatMap((snapshot) => snapshot.docs).forEach((doc) => {
      byId.set(doc.id, doc.data() as T);
    });

    return uniqueIds.map((id) => byId.get(id)).filter((item): item is T => Boolean(item));
  }

  private async organisationResponse(
    organisation: OrganisationDocument,
    languageCode: string,
  ) {
    const mediaIds = (organisation.media ?? []).map((media) => media.mediaId);
    const media = await this.getMediaByIds(mediaIds);
    const mediaById = new Map(media.map((item) => [item.id, item]));

    const relations = (organisation.media ?? [])
      .map((relation) => ({ ...relation, media: mediaById.get(relation.mediaId) }))
      .filter((relation) => relation.media);

    return {
      id: organisation.id,
      slug: organisation.slug,
      logoUrl: this.primaryMediaUrl(relations, 'LOGO') ?? organisation.logoUrl ?? null,
      gallery: this.galleryMedia(relations, 'GALLERY'),
      websiteUrl: organisation.websiteUrl ?? null,
      phone: organisation.phone ?? null,
      mobileNumber: organisation.mobileNumber ?? null,
      email: organisation.email ?? null,
      address: organisation.address ?? null,
      city: organisation.city ?? null,
      state: organisation.state ?? null,
      country: organisation.country ?? null,
      latitude: organisation.latitude ?? null,
      longitude: organisation.longitude ?? null,
      ...this.translation(organisation.translations, languageCode),
    };
  }

  private async getMediaByIds(ids: string[]): Promise<MediaDocument[]> {
    if (!ids.length) return [];
    const uniqueIds = [...new Set(ids)];
    const chunks = Array.from({ length: Math.ceil(uniqueIds.length / 30) }, (_, index) =>
      uniqueIds.slice(index * 30, index * 30 + 30),
    );
    const snapshots = await Promise.all(
      chunks.map((chunk) =>
        this.firebase.db.collection('media').where('__name__', 'in', chunk).get(),
      ),
    );
    return snapshots.flatMap((snapshot) =>
      snapshot.docs.map((doc) => doc.data() as MediaDocument),
    );
  }

  private displayOrderForOrganisation(organisations: OrganisationDocument[], id: string) {
    const organisation = organisations.find((item) => item.id === id);
    return organisation?.displayOrder ?? Number.MAX_SAFE_INTEGER;
  }

  private translation(
    translations: Record<string, Translation> | undefined,
    languageCode: string,
  ) {
    const translation = translations?.[languageCode] ?? translations?.en;
    return {
      name: translation?.name ?? null,
      description: translation?.description ?? null,
    };
  }

  private mediaUrl(media: MediaDocument) {
    const base = process.env.R2_PUBLIC_BASE_URL?.replace(/\/$/, '');
    return base ? `${base}/${media.storageKey}` : media.storageKey;
  }

  private primaryMediaUrl(relations: Array<{ purpose: string; isPrimary: boolean; media?: MediaDocument }>, purpose: string) {
    const relation = relations.find((item) => item.purpose === purpose && item.isPrimary)
      ?? relations.find((item) => item.purpose === purpose);
    return relation?.media ? this.mediaUrl(relation.media) : null;
  }

  private galleryMedia(relations: Array<{ purpose: string; displayOrder: number; media?: MediaDocument }>, purpose: string) {
    return relations
      .filter((item) => item.purpose === purpose && item.media)
      .sort((a, b) => a.displayOrder - b.displayOrder)
      .map((item) => ({
        id: item.media!.id,
        url: this.mediaUrl(item.media!),
        mimeType: item.media!.mimeType,
        width: item.media!.width,
        height: item.media!.height,
      }));
  }
}
