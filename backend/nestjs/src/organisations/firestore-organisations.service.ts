import { Injectable, NotFoundException } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';

interface Translation {
  name?: string | null;
  description?: string | null;
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
  isActive: boolean;
  displayOrder: number;
  translations?: Record<string, Translation>;
  causeIds?: string[];
  media?: Array<{
    mediaId: string;
    purpose: string;
    displayOrder: number;
    isPrimary: boolean;
  }>;
}

interface CauseDocument {
  id: string;
  slug: string;
  isActive: boolean;
  displayOrder: number;
  translations?: Record<string, Translation>;
}

interface MediaDocument {
  id: string;
  storageKey: string;
  mimeType: string;
  width: number | null;
  height: number | null;
}

@Injectable()
export class FirestoreOrganisationsService {
  constructor(private readonly firebase: FirebaseService) {}

  async syncOrganisation(document: {
    id: string;
    slug: string;
    logoUrl: string | null;
    websiteUrl: string | null;
    phone: string | null;
    mobileNumber: string | null;
    email: string | null;
    address: string | null;
    city: string | null;
    state: string | null;
    country: string;
    latitude: number | null;
    longitude: number | null;
    isActive: boolean;
    displayOrder: number;
    translations: Record<string, Translation>;
    causeIds: string[];
    media: Array<{
      mediaId: string;
      purpose: string;
      displayOrder: number;
      isPrimary: boolean;
    }>;
    createdAt: Date;
    updatedAt: Date;
  }) {
    await this.firebase.db.collection('organisations').doc(document.id).set(document, { merge: true });
  }

  async removeOrganisation(id: string) {
    await this.firebase.db.collection('organisations').doc(id).delete();
  }

  async findAll(languageCode = 'en') {
    const snapshot = await this.firebase.db
      .collection('organisations')
      .where('isActive', '==', true)
      .orderBy('displayOrder', 'asc')
      .get();

    const organisations = snapshot.docs.map((doc) => doc.data() as OrganisationDocument);
    return this.withCauses(organisations, languageCode);
  }

  async findOne(slug: string, languageCode = 'en') {
    const snapshot = await this.firebase.db
      .collection('organisations')
      .where('slug', '==', slug)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (snapshot.empty) {
      throw new NotFoundException(`Organisation '${slug}' not found`);
    }

    const results = await this.withCauses(
      [snapshot.docs[0].data() as OrganisationDocument],
      languageCode,
    );
    return results[0];
  }

  private async withCauses(
    organisations: OrganisationDocument[],
    languageCode: string,
  ) {
    const causeIds = [...new Set(organisations.flatMap((item) => item.causeIds ?? []))];
    const causes = await this.getByIds<CauseDocument>('causes', causeIds);
    const causesById = new Map(causes.map((cause) => [cause.id, cause]));

    const mediaIds = [...new Set(
      organisations.flatMap((item) => (item.media ?? []).map((media) => media.mediaId)),
    )];
    const media = await this.getByIds<MediaDocument>('media', mediaIds);
    const mediaById = new Map(media.map((item) => [item.id, item]));

    return organisations.map((organisation) => {
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
        displayOrder: organisation.displayOrder,
        ...this.translation(organisation.translations, languageCode),
        causes: (organisation.causeIds ?? [])
          .map((id) => causesById.get(id))
          .filter((cause): cause is CauseDocument => Boolean(cause?.isActive))
          .sort((a, b) => a.displayOrder - b.displayOrder)
          .map((cause) => ({
            id: cause.id,
            slug: cause.slug,
            displayOrder: cause.displayOrder,
            ...this.translation(cause.translations, languageCode),
          })),
      };
    });
  }

  private async getByIds<T extends CauseDocument | MediaDocument>(
    collection: string,
    ids: string[],
  ): Promise<T[]> {
    if (!ids.length) return [];
    const uniqueIds = [...new Set(ids)];
    const chunks = Array.from(
      { length: Math.ceil(uniqueIds.length / 30) },
      (_, index) => uniqueIds.slice(index * 30, index * 30 + 30),
    );
    const snapshots = await Promise.all(
      chunks.map((chunk) =>
        this.firebase.db.getAll(
          ...chunk.map((id) => this.firebase.db.collection(collection).doc(id)),
        ),
      ),
    );
    const byId = new Map<string, T>();
    snapshots.flatMap((items) => items).forEach((doc) => {
      if (doc.exists) byId.set(doc.id, doc.data() as T);
    });
    return uniqueIds
      .map((id) => byId.get(id))
      .filter((item): item is T => Boolean(item));
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

  private primaryMediaUrl(relations: Array<{
    purpose: string;
    isPrimary: boolean;
    media?: MediaDocument;
  }>, purpose: string) {
    const relation =
      relations.find((item) => item.purpose === purpose && item.isPrimary) ??
      relations.find((item) => item.purpose === purpose);
    return relation?.media ? this.mediaUrl(relation.media) : null;
  }

  private galleryMedia(relations: Array<{
    purpose: string;
    displayOrder: number;
    media?: MediaDocument;
  }>, purpose: string) {
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
