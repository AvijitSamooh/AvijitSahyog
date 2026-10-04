import { Injectable, NotFoundException } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';

interface MediaDocument {
  id: string;
  storageKey: string;
  mimeType: string;
  width: number | null;
  height: number | null;
}

interface RelatedDocument {
  id: string;
  slug: string;
  isActive: boolean;
}

interface BeneficiaryDocument {
  id: string;
  sourceApplicationId: string | null;
  name: string;
  photoUrl: string | null;
  story: string | null;
  supportedYear: number;
  contributionAmount: string;
  causeId: string;
  organisationId: string | null;
  isActive: boolean;
  displayOrder: number;
  media?: Array<{
    mediaId: string;
    purpose: string;
    displayOrder: number;
    isPrimary: boolean;
  }>;
}

@Injectable()
export class FirestoreBeneficiariesService {
  constructor(private readonly firebase: FirebaseService) {}

  async syncBeneficiary(document: {
    id: string;
    sourceApplicationId: string | null;
    name: string;
    photoUrl: string | null;
    story: string | null;
    supportedYear: number;
    contributionAmount: string;
    causeId: string;
    organisationId: string | null;
    isActive: boolean;
    displayOrder: number;
    media: Array<{
      mediaId: string;
      purpose: string;
      displayOrder: number;
      isPrimary: boolean;
    }>;
    createdAt: Date;
    updatedAt: Date;
  }) {
    await this.firebase.db.collection('beneficiaries').doc(document.id).set(document, { merge: true });
  }

  async removeBeneficiary(id: string) {
    await this.firebase.db.collection('beneficiaries').doc(id).delete();
  }

  async findAll(query: {
    causeId?: string;
    year?: number;
    search?: string;
    sort?: string;
  }) {
    const snapshot = await this.firebase.db
      .collection('beneficiaries')
      .where('isActive', '==', true)
      .orderBy('supportedYear', 'desc')
      .orderBy('displayOrder', 'asc')
      .get();

    let items = snapshot.docs.map((doc) => doc.data() as BeneficiaryDocument);
    if (query.causeId) items = items.filter((item) => item.causeId === query.causeId);
    if (query.year) items = items.filter((item) => item.supportedYear === query.year);
    if (query.search?.trim()) {
      const search = query.search.trim().toLocaleLowerCase();
      items = items.filter((item) => item.name.toLocaleLowerCase().includes(search));
    }

    items.sort((a, b) => this.compare(a, b, query.sort));
    return this.toResponses(items);
  }

  async findOne(id: string) {
    const snapshot = await this.firebase.db.collection('beneficiaries').doc(id).get();
    if (!snapshot.exists) {
      throw new NotFoundException(`Beneficiary '${id}' not found`);
    }

    const item = snapshot.data() as BeneficiaryDocument;
    if (!item.isActive) {
      throw new NotFoundException(`Beneficiary '${id}' not found`);
    }

    return (await this.toResponses([item]))[0];
  }

  private async toResponses(items: BeneficiaryDocument[]) {
    const causeIds = [...new Set(items.map((item) => item.causeId).filter(Boolean))];
    const organisationIds = [...new Set(items.map((item) => item.organisationId).filter(Boolean) as string[])];
    const mediaIds = [...new Set(
      items.flatMap((item) => (item.media ?? []).map((relation) => relation.mediaId)),
    )];

    const [causes, organisations, media] = await Promise.all([
      this.getByIds<RelatedDocument>('causes', causeIds),
      this.getByIds<RelatedDocument>('organisations', organisationIds),
      this.getByIds<MediaDocument>('media', mediaIds),
    ]);
    const causeById = new Map(causes.map((item) => [item.id, item]));
    const organisationById = new Map(organisations.map((item) => [item.id, item]));
    const mediaById = new Map(media.map((item) => [item.id, item]));

    return items.map((item) => {
      const relations = (item.media ?? [])
        .map((relation) => ({ ...relation, media: mediaById.get(relation.mediaId) }))
        .filter((relation) => relation.media);
      const profile = this.primaryMedia(relations, 'PROFILE');
      const gallery = this.galleryMedia(relations, 'GALLERY');

      return {
        id: item.id,
        name: item.name,
        photoUrl: profile?.url ?? item.photoUrl,
        profileImage: profile,
        gallery,
        story: item.story,
        supportedYear: item.supportedYear,
        contributionAmount: item.contributionAmount,
        cause: this.related(causeById.get(item.causeId)),
        organisation: item.organisationId ? this.related(organisationById.get(item.organisationId)) : null,
      };
    });
  }

  private related(item?: RelatedDocument) {
    return item ? { id: item.id, slug: item.slug } : null;
  }

  private compare(a: BeneficiaryDocument, b: BeneficiaryDocument, sort?: string) {
    switch (sort) {
      case 'name_asc':
        return a.name.localeCompare(b.name);
      case 'amount_desc':
        return Number(b.contributionAmount) - Number(a.contributionAmount);
      case 'amount_asc':
        return Number(a.contributionAmount) - Number(b.contributionAmount);
      case 'year_asc':
        return a.supportedYear - b.supportedYear || a.displayOrder - b.displayOrder;
      default:
        return b.supportedYear - a.supportedYear || a.displayOrder - b.displayOrder;
    }
  }

  private async getByIds<T extends RelatedDocument | MediaDocument>(
    collection: string,
    ids: string[],
  ): Promise<T[]> {
    if (!ids.length) return [];
    const uniqueIds = [...new Set(ids)];
    const snapshots = await Promise.all(
      Array.from({ length: Math.ceil(uniqueIds.length / 30) }, (_, index) =>
        this.firebase.db.getAll(
          ...uniqueIds.slice(index * 30, index * 30 + 30)
            .map((id) => this.firebase.db.collection(collection).doc(id)),
        ),
      ),
    );
    const byId = new Map<string, T>();
    snapshots.flatMap((items) => items).forEach((doc) => {
      if (doc.exists) byId.set(doc.id, doc.data() as T);
    });
    return uniqueIds.map((id) => byId.get(id)).filter((item): item is T => Boolean(item));
  }

  private mediaUrl(media: MediaDocument) {
    const base = process.env.R2_PUBLIC_BASE_URL?.replace(/\/$/, '');
    return base ? `${base}/${media.storageKey}` : media.storageKey;
  }

  private primaryMedia(relations: Array<{ purpose: string; isPrimary: boolean; media?: MediaDocument }>, purpose: string) {
    const relation = relations.find((item) => item.purpose === purpose && item.isPrimary)
      ?? relations.find((item) => item.purpose === purpose);
    if (!relation?.media) return null;
    return {
      id: relation.media.id,
      url: this.mediaUrl(relation.media),
      mimeType: relation.media.mimeType,
      width: relation.media.width,
      height: relation.media.height,
    };
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
