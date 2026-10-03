import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseIdentity } from '../auth/auth.types';
import { CreateHelpApplicationDto, HelpApplicationTypeDto } from './dto/create-help-application.dto';
import { ResubmitHelpApplicationDto } from './dto/resubmit-help-application.dto';
import { ReviewHelpApplicationDto, HelpApplicationDecisionDto } from './dto/review-help-application.dto';
import { VoteHelpApplicationDto } from './dto/vote-help-application.dto';
import { ApplicationWindowsService } from './application-windows.service';
import { UpdateHelpApplicationDto } from './dto/update-help-application.dto';
import { MediaService } from '../media/media.service';
import { createZip } from './certificate-photo-export.util';
import sharp from 'sharp';

@Injectable()
export class HelpApplicationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly applicationWindows: ApplicationWindowsService,
    private readonly mediaService: MediaService,
  ) {}

  async create(identity: FirebaseIdentity, dto: CreateHelpApplicationDto) {
    const user = await this.user(identity);
    await this.applicationWindows.ensureAccepting(dto.type);
    this.validateApplicantDetails(dto);
    this.validateSubmission(dto.type, dto.requestedAmount, dto.mediaIds);
    this.validatePratibhaDetails(dto.type, dto);
    const acceptedRules = await this.validateAcceptedRules(dto.type, dto.acceptedRuleIds);
    const media = await this.validateMedia(dto.mediaIds, user.id);
    const facePhotoMediaId = await this.validateFacePhoto(dto.facePhotoMediaId, user.id);
    const certificatePhotoMediaId = await this.validateCertificatePhoto(dto.type, dto.certificatePhotoMediaId, user.id, facePhotoMediaId);
    const item = await this.prisma.helpApplication.create({
      data: {
        applicantId: user.id,
        applicantName: dto.applicantName.trim(),
        mobileNumber: dto.mobileNumber.trim(),
        email: dto.email?.trim() || null,
        address: dto.address.trim(),
        city: dto.city.trim(),
        state: dto.state.trim(),
        pincode: dto.pincode.trim(),
        type: dto.type,
        requestedAmount: dto.requestedAmount,
        overallPercentage: dto.overallPercentage,
        clarification: dto.clarification?.trim() || null,
        motherName: dto.motherName?.trim() || null,
        fatherName: dto.fatherName?.trim() || null,
        dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : null,
        classStandard: dto.classStandard?.trim() || null,
        schoolInstituteName: dto.schoolInstituteName?.trim() || null,
        accomplishments: dto.accomplishments?.trim() || null,
        certificatePhotoMediaId,
        facePhotoMediaId,
        media: { create: media.map((mediaId) => ({ mediaId })) },
        ruleAcceptances: { create: acceptedRules.map((rule) => ({ ruleId: rule.id, ruleText: rule.text })) },
      },
      include: { media: { include: { media: true } }, certificatePhotoMedia: true, facePhotoMedia: true },
    });
    return this.toResponse(item);
  }

  async listMine(identity: FirebaseIdentity) {
    const user = await this.user(identity);
    const items = await this.prisma.helpApplication.findMany({
      where: { applicantId: user.id },
      orderBy: { createdAt: 'desc' },
      include: { media: { include: { media: true } }, certificatePhotoMedia: true, facePhotoMedia: true, votes: { select: { score: true } } },
    });
    return items.map((item) => this.toResponse(item));
  }

  async findMine(identity: FirebaseIdentity, id: string) {
    const user = await this.user(identity);
    const item = await this.prisma.helpApplication.findFirst({
      where: { id, applicantId: user.id },
      include: { media: { include: { media: true } }, certificatePhotoMedia: true },
    });
    if (!item) throw new NotFoundException('Application not found.');
    return this.toResponse(item);
  }

  async updateMine(identity: FirebaseIdentity, id: string, dto: UpdateHelpApplicationDto) {
    const user = await this.user(identity);
    const existing = await this.prisma.helpApplication.findFirst({
      where: { id, applicantId: user.id },
      include: { media: { select: { mediaId: true } } },
    });
    if (!existing) throw new NotFoundException('Application not found.');
    if (['APPROVED_FOR_DONATION', 'CONSIDERED_FOR_SAMMAN', 'NOT_SELECTED'].includes(existing.status)) {
      throw new BadRequestException('This application can no longer be edited.');
    }

    await this.applicationWindows.ensureAccepting(existing.type);
    this.validateApplicantDetails(dto as any);
    this.validateSubmission(existing.type, dto.requestedAmount, dto.mediaIds);
    this.validatePratibhaDetails(existing.type, dto);
    const acceptedRules = await this.validateAcceptedRules(existing.type as HelpApplicationTypeDto, dto.acceptedRuleIds);
    const media = await this.validateMedia(dto.mediaIds, user.id);
    const facePhotoMediaId = await this.validateFacePhoto(dto.facePhotoMediaId, user.id);
    const certificatePhotoMediaId = await this.validateCertificatePhoto(existing.type, dto.certificatePhotoMediaId, user.id, facePhotoMediaId);
    const previousMediaIds = existing.media.map((item) => item.mediaId);
    const removedMediaIds = previousMediaIds.filter((mediaId) => !media.includes(mediaId));
    const updated = await this.prisma.$transaction(async (tx) => {
      // Any applicant edit creates a new review cycle. Clear reviewer votes and
      // review metadata atomically with the edited application.
      await tx.helpApplicationVote.deleteMany({ where: { applicationId: id } });
      await tx.helpApplicationMedia.deleteMany({ where: { applicationId: id } });
      await tx.helpApplicationRuleAcceptance.deleteMany({ where: { applicationId: id } });
      return tx.helpApplication.update({
        where: { id },
        data: {
          applicantName: dto.applicantName.trim(),
          mobileNumber: dto.mobileNumber.trim(),
          email: dto.email?.trim() || null,
          address: dto.address.trim(),
          city: dto.city.trim(),
          state: dto.state.trim(),
          pincode: dto.pincode.trim(),
          status: 'SUBMITTED',
          requestedAmount: dto.requestedAmount ?? null,
          overallPercentage: dto.overallPercentage,
          approvedAmount: null,
          rejectionReason: null,
          clarification: dto.clarification?.trim() || null,
          motherName: dto.motherName?.trim() || null,
          fatherName: dto.fatherName?.trim() || null,
          dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : null,
          classStandard: dto.classStandard?.trim() || null,
          schoolInstituteName: dto.schoolInstituteName?.trim() || null,
          accomplishments: dto.accomplishments?.trim() || null,
          certificatePhotoMediaId,
          facePhotoMediaId,
          adminNote: null,
          reviewedAt: null,
          media: { create: media.map((mediaId) => ({ mediaId })) },
          ruleAcceptances: { create: acceptedRules.map((rule) => ({ ruleId: rule.id, ruleText: rule.text })) },
        },
        include: { media: { include: { media: true } }, certificatePhotoMedia: true, facePhotoMedia: true },
      });
    });

    for (const mediaId of removedMediaIds) {
      try {
        await this.mediaService.deleteUserImage(mediaId, user.id);
      } catch (_) {
        // A media item may still be referenced by another domain record. Keep it
        // rather than failing an otherwise successful application update.
      }
    }
    return this.toResponse(updated);
  }

  async deleteMine(identity: FirebaseIdentity, id: string) {
    const user = await this.user(identity);
    const existing = await this.prisma.helpApplication.findFirst({
      where: { id, applicantId: user.id },
      select: { id: true, status: true },
    });
    if (!existing) throw new NotFoundException('Application not found.');
    if (existing.status === 'APPROVED_FOR_DONATION' || existing.status === 'CONSIDERED_FOR_SAMMAN') {
      throw new BadRequestException('This application can no longer be deleted.');
    }
    await this.prisma.helpApplication.delete({ where: { id } });
    return { id, deleted: true };
  }

  async resubmit(identity: FirebaseIdentity, id: string, dto: ResubmitHelpApplicationDto) {
    const user = await this.user(identity);
    const existing = await this.prisma.helpApplication.findFirst({ where: { id, applicantId: user.id } });
    if (!existing) throw new NotFoundException('Application not found.');
    await this.applicationWindows.ensureAccepting(existing.type);
    if (existing.status !== 'REJECTED' && existing.status !== 'CLARIFICATION_REQUIRED') {
      throw new BadRequestException('Only rejected or clarification-requested applications can be resubmitted.');
    }
    this.validateSubmission(existing.type, dto.requestedAmount ?? Number(existing.requestedAmount ?? 0), dto.mediaIds);
    const media = await this.validateMedia(dto.mediaIds, user.id);
    const certificatePhotoMediaId = await this.validateCertificatePhoto(existing.type, dto.certificatePhotoMediaId, user.id);
    const acceptedRules = await this.validateAcceptedRules(existing.type as HelpApplicationTypeDto, dto.acceptedRuleIds);
    return this.prisma.$transaction(async (tx) => {
      await tx.helpApplicationVote.deleteMany({ where: { applicationId: id } });
      await tx.helpApplicationMedia.deleteMany({ where: { applicationId: id } });
      await tx.helpApplicationRuleAcceptance.deleteMany({ where: { applicationId: id } });
      const updated = await tx.helpApplication.update({
        where: { id },
        data: {
          status: 'SUBMITTED',
          requestedAmount: dto.requestedAmount ?? existing.requestedAmount,
          overallPercentage: dto.overallPercentage,
          approvedAmount: null,
          rejectionReason: null,
          clarification: dto.clarification.trim(),
          motherName: dto.motherName?.trim() || existing.motherName,
          fatherName: dto.fatherName?.trim() || existing.fatherName,
          dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : existing.dateOfBirth,
          classStandard: dto.classStandard?.trim() || existing.classStandard,
          schoolInstituteName: dto.schoolInstituteName?.trim() || existing.schoolInstituteName,
          accomplishments: dto.accomplishments?.trim() || existing.accomplishments,
          certificatePhotoMediaId: certificatePhotoMediaId ?? existing.certificatePhotoMediaId,
          adminNote: null,
          reviewedAt: null,
          media: { create: media.map((mediaId) => ({ mediaId })) },
          ruleAcceptances: { create: acceptedRules.map((rule) => ({ ruleId: rule.id, ruleText: rule.text })) },
        },
        include: { media: { include: { media: true } }, certificatePhotoMedia: true },
      });
      return this.toResponse(updated);
    });
  }

  async listForAdmin(type?: string, status?: string) {
    const items = await this.prisma.helpApplication.findMany({
      where: { ...(type ? { type: type as any } : {}), ...(status ? { status: status as any } : {}) },
      orderBy: [{ createdAt: 'asc' }],
      include: {
        applicant: { select: { id: true, displayName: true, email: true } },
        media: { include: { media: true } },
        certificatePhotoMedia: true,
        facePhotoMedia: true,
        votes: { include: { admin: { select: { id: true, displayName: true } } }, orderBy: { updatedAt: 'desc' } },
      },
    });
    const responses = items.map((item) => this.toAdminResponse(item));
    responses.sort((a, b) =>
      (b.overallPercentage ?? -1) - (a.overallPercentage ?? -1) ||
      (type === 'PRATIBHA_SAMMAN' ? (b.voteAverage ?? -1) - (a.voteAverage ?? -1) : 0) ||
      new Date(a.submittedAt ?? 0).getTime() - new Date(b.submittedAt ?? 0).getTime(),
    );
    return responses;
  }

  async adminSummary(type?: string) {
    const where = type ? { type: type as any } : {};
    const groups = await this.prisma.helpApplication.groupBy({
      by: ['status'],
      where,
      _count: { _all: true },
    });
    const counts = Object.fromEntries(groups.map((group) => [group.status, group._count._all]));
    const selected = (counts.APPROVED_FOR_DONATION ?? 0) + (counts.CONSIDERED_FOR_SAMMAN ?? 0);
    const rejected = counts.REJECTED ?? 0;
    const notSelected = counts.NOT_SELECTED ?? 0;
    const needsReview =
      (counts.SUBMITTED ?? 0) +
      (counts.UNDER_REVIEW ?? 0) +
      (counts.CLARIFICATION_REQUIRED ?? 0);
    return {
      total: Object.values(counts).reduce((sum, value) => sum + value, 0),
      needsReview,
      selected,
      rejected,
      notSelected,
      clarificationRequired: counts.CLARIFICATION_REQUIRED ?? 0,
      byStatus: counts,
    };
  }

  async photoManifest(type?: string, status?: string) {
    const items = await this.prisma.helpApplication.findMany({
      where: { ...(type ? { type: type as any } : {}), ...(status ? { status: status as any } : {}) },
      orderBy: [{ applicantName: 'asc' }, { createdAt: 'asc' }],
      include: { facePhotoMedia: true, certificatePhotoMedia: true },
    });
    return items
      .filter((item) => item.facePhotoMedia || item.certificatePhotoMedia)
      .map((item) => ({
        id: item.id,
        name: item.applicantName ?? 'Applicant',
        type: item.type,
        status: item.status,
        facePhoto: item.facePhotoMedia ? this.mediaResponse({ media: item.facePhotoMedia }) : null,
        certificatePhoto: item.certificatePhotoMedia ? this.mediaResponse({ media: item.certificatePhotoMedia }) : null,
      }));
  }

  async certificatePhotoExportSummary(type = HelpApplicationTypeDto.PRATIBHA_SAMMAN, status = 'CONSIDERED_FOR_SAMMAN') {
    const items = await this.prisma.helpApplication.findMany({
      where: { type: type as any, status: status as any },
      orderBy: [{ applicantName: 'asc' }, { createdAt: 'asc' }],
      include: { certificatePhotoMedia: true },
    });
    const missing = items
      .filter((item) => !item.certificatePhotoMedia)
      .map((item) => ({ id: item.id, name: item.applicantName ?? 'Applicant' }));
    return {
      total: items.length,
      available: items.length - missing.length,
      missing,
      type,
      status,
    };
  }

  async buildCertificatePhotoExport(type = HelpApplicationTypeDto.PRATIBHA_SAMMAN, status = 'CONSIDERED_FOR_SAMMAN') {
    const items = await this.prisma.helpApplication.findMany({
      where: { type: type as any, status: status as any },
      orderBy: [{ applicantName: 'asc' }, { createdAt: 'asc' }],
      include: { certificatePhotoMedia: true },
    });

    const entries: Array<{ name: string; data: Buffer }> = [];
    const manifest: string[] = ['Serial,Application ID,Applicant Name,Status,Photo Filename'];
    let serial = 0;

    for (const item of items) {
      const name = item.applicantName ?? 'Applicant';
      if (!item.certificatePhotoMedia) {
        manifest.push([serial + 1, item.id, name, 'MISSING_PHOTO', ''].map(csv).join(','));
        continue;
      }

      serial += 1;
      const outputName = `${String(serial).padStart(3, '0')}_${safeFileName(name)}.jpg`;
      try {
        const source = await this.mediaService.downloadImage(item.certificatePhotoMedia.storageKey);
        const jpeg = await sharp(source)
          .rotate()
          .resize({ width: 1800, height: 1800, fit: 'inside', withoutEnlargement: true })
          .jpeg({ quality: 92, mozjpeg: true })
          .toBuffer();
        entries.push({ name: outputName, data: jpeg });
        manifest.push([serial, item.id, name, item.status, outputName].map(csv).join(','));
      } catch (_) {
        manifest.push([serial, item.id, name, 'PHOTO_READ_FAILED', ''].map(csv).join(','));
      }
    }

    entries.push({
      name: 'manifest.csv',
      data: Buffer.from('\ufeff' + manifest.join('\\n') + '\\n', 'utf8'),
    });
    return createZip(entries);
  }

  async vote(identity: FirebaseIdentity, id: string, dto: VoteHelpApplicationDto) {
    const admin = await this.admin(identity);
    const existing = await this.application(id);
    return this.prisma.$transaction(async (tx) => {
      const vote = await tx.helpApplicationVote.upsert({
        where: { applicationId_adminId: { applicationId: id, adminId: admin.id } },
        update: { score: dto.score, comment: dto.comment?.trim() || null },
        create: { applicationId: id, adminId: admin.id, score: dto.score, comment: dto.comment?.trim() || null },
      });
      if (existing.status === 'SUBMITTED') {
        await tx.helpApplication.update({ where: { id }, data: { status: 'UNDER_REVIEW' } });
      }
      return vote;
    });
  }

  async review(id: string, dto: ReviewHelpApplicationDto) {
    const existing = await this.application(id);
    if (dto.decision === HelpApplicationDecisionDto.APPROVE) {
      if (existing.type === 'PRATIBHA_SAMMAN') throw new BadRequestException('Pratibha Samman applications must use a Samman decision.');
      const amount = dto.approvedAmount ?? 0;
      if (amount <= 0 || amount > Number(existing.requestedAmount ?? 0)) {
        throw new BadRequestException('Approved amount must be greater than zero and no more than the requested amount.');
      }
      return this.updateStatus(id, 'APPROVED_FOR_DONATION', amount, null, dto.note);
    }
    if (dto.decision === HelpApplicationDecisionDto.REJECT) {
      if (!dto.reason?.trim()) throw new BadRequestException('A rejection reason is required.');
      return this.updateStatus(id, 'REJECTED', null, dto.reason.trim(), dto.note);
    }
    if (dto.decision === HelpApplicationDecisionDto.CLARIFICATION_REQUIRED) {
      if (!dto.reason?.trim()) throw new BadRequestException('Clarification details are required.');
      return this.updateStatus(id, 'CLARIFICATION_REQUIRED', null, dto.reason.trim(), dto.note);
    }
    if (existing.type !== 'PRATIBHA_SAMMAN') throw new BadRequestException('Samman decisions are only valid for Pratibha Samman applications.');
    return this.updateStatus(
      id,
      dto.decision === HelpApplicationDecisionDto.CONSIDER_FOR_SAMMAN ? 'CONSIDERED_FOR_SAMMAN' : 'NOT_SELECTED',
      null,
      dto.reason?.trim() || null,
      dto.note,
    );
  }

  private async updateStatus(id: string, status: any, approvedAmount: number | null, reason: string | null, note?: string) {
    const item = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.helpApplication.update({
        where: { id },
        data: { status, approvedAmount, rejectionReason: reason, adminNote: note?.trim() || null, reviewedAt: new Date() },
        include: {
          applicant: { select: { id: true, displayName: true, email: true } },
          media: { include: { media: true } },
          certificatePhotoMedia: true,
          facePhotoMedia: true,
          votes: { include: { admin: { select: { id: true, displayName: true } } } },
        },
      });

      if (status === 'CONSIDERED_FOR_SAMMAN' && updated.type === 'PRATIBHA_SAMMAN') {
        await this.publishPratibhaBeneficiary(tx, updated);
      }
      return updated;
    });
    return this.toAdminResponse(item);
  }

  private async publishPratibhaBeneficiary(tx: any, application: any) {
    const cause = await tx.cause.findUnique({
      where: { slug: 'pratibha-samman' },
      select: { id: true },
    });
    if (!cause) throw new BadRequestException('Pratibha Samman cause is not configured.');

    const achievementLines = [
      'Pratibha Samman — 2025-26 batch',
      application.classStandard ? `Class/Standard: ${application.classStandard}` : null,
      application.schoolInstituteName ? `School/Institute: ${application.schoolInstituteName}` : null,
      application.accomplishments ? `Achievements: ${application.accomplishments}` : null,
      application.adminNote ? `Recognition note: ${application.adminNote}` : null,
    ].filter(Boolean);

    const beneficiary = await tx.beneficiary.upsert({
      where: { sourceApplicationId: application.id },
      create: {
        sourceApplicationId: application.id,
        name: application.applicantName,
        story: achievementLines.join('\\n'),
        supportedYear: 2026,
        contributionAmount: 0,
        causeId: cause.id,
        displayOrder: 0,
      },
      update: {
        name: application.applicantName,
        story: achievementLines.join('\\n'),
        supportedYear: 2026,
        causeId: cause.id,
      },
    });

    const certificatePhotoId = application.certificatePhotoMediaId;
    if (certificatePhotoId) {
      const existingProfile = await tx.beneficiaryMedia.findFirst({
        where: { beneficiaryId: beneficiary.id, purpose: 'PROFILE' },
        select: { id: true },
      });
      if (!existingProfile) {
        await tx.beneficiaryMedia.create({
          data: {
            beneficiaryId: beneficiary.id,
            mediaId: certificatePhotoId,
            purpose: 'PROFILE',
            isPrimary: true,
            displayOrder: 0,
          },
        });
      }
    }

    const supportingMedia = (application.media ?? [])
      .map((item: any) => item.mediaId)
      .filter((mediaId: string) => mediaId && mediaId !== certificatePhotoId);
    if (supportingMedia.length) {
      const existingGallery = await tx.beneficiaryMedia.findMany({
        where: { beneficiaryId: beneficiary.id, mediaId: { in: supportingMedia } },
        select: { mediaId: true },
      });
      const existingIds = new Set(existingGallery.map((item: any) => item.mediaId));
      for (const mediaId of supportingMedia) {
        if (!existingIds.has(mediaId)) {
          await tx.beneficiaryMedia.create({
            data: {
              beneficiaryId: beneficiary.id,
              mediaId,
              purpose: 'GALLERY',
              displayOrder: 0,
              isPrimary: false,
            },
          });
        }
      }
    }
    return beneficiary;
  }

  private validateApplicantDetails(dto: CreateHelpApplicationDto) {
    const mobile = dto.mobileNumber.trim();
    const pincode = dto.pincode.trim();
    if (!dto.applicantName.trim() || !dto.address.trim() || !dto.city.trim() || !dto.state.trim()) {
      throw new BadRequestException('Name, address, city and state are required.');
    }
    if (!/^\+?[0-9]{10,13}$/.test(mobile)) {
      throw new BadRequestException('Enter a valid mobile number.');
    }
    if (!/^[0-9]{6}$/.test(pincode)) {
      throw new BadRequestException('Enter a valid 6-digit PIN code.');
    }
  }

  private validateSubmission(type: string, amount: number | undefined, mediaIds: string[]) {
    if (!mediaIds?.length || mediaIds.length > 10) throw new BadRequestException('Upload between 1 and 10 supporting images.');
    if (type === HelpApplicationTypeDto.PRATIBHA_SAMMAN) return;
    if (!amount || amount <= 0) throw new BadRequestException('Requested amount must be greater than zero.');
  }

  private validatePratibhaDetails(type: string, dto: any) {
    if (type !== HelpApplicationTypeDto.PRATIBHA_SAMMAN) return;
    const required = [
      ['motherName', dto.motherName],
      ['fatherName', dto.fatherName],
      ['dateOfBirth', dto.dateOfBirth],
      ['classStandard', dto.classStandard],
      ['schoolInstituteName', dto.schoolInstituteName],
      ['certificatePhotoMediaId', dto.certificatePhotoMediaId],
    ];
    const missing = required.filter(([, value]) => value == null || String(value).trim() === '').map(([name]) => name);
    if (missing.length) throw new BadRequestException('Pratibha Samman requires mother name, father name, date of birth, class/standard, school/institute and a clear certificate photo.');
    if (dto.dateOfBirth && Number.isNaN(new Date(dto.dateOfBirth).getTime())) {
      throw new BadRequestException('Date of birth is invalid.');
    }
  }

  private async validateFacePhoto(mediaId: string | undefined, uploadedById: string) {
    if (!mediaId) throw new BadRequestException('A clear face photo is required.');
    const media = await this.prisma.media.findFirst({
      where: { id: mediaId, uploadedById },
      select: { id: true },
    });
    if (!media) throw new BadRequestException('The face photo is unavailable.');
    return media.id;
  }

  private async validateCertificatePhoto(type: string, mediaId: string | undefined, uploadedById: string, facePhotoMediaId?: string) {
    if (type !== HelpApplicationTypeDto.PRATIBHA_SAMMAN) return null;
    const effectiveId = mediaId ?? facePhotoMediaId;
    if (!effectiveId) throw new BadRequestException('A clear certificate photo is required for Pratibha Samman.');
    const media = await this.prisma.media.findFirst({
      where: { id: effectiveId, uploadedById },
      select: { id: true },
    });
    if (!media) throw new BadRequestException('The certificate photo is unavailable.');
    return media.id;
  }

  private async validateMedia(ids: string[], uploadedById: string) {
    const unique = [...new Set(ids)];
    const media = await this.prisma.media.findMany({ where: { id: { in: unique }, uploadedById }, select: { id: true } });
    if (media.length !== unique.length) throw new BadRequestException('One or more supporting images are unavailable.');
    return unique;
  }

  private async user(identity: FirebaseIdentity) {
    return this.prisma.user.upsert({
      where: { firebaseUid: identity.uid },
      create: { firebaseUid: identity.uid, email: identity.email, displayName: identity.displayName, photoUrl: identity.photoUrl },
      update: { email: identity.email, displayName: identity.displayName, photoUrl: identity.photoUrl },
    });
  }

  private async admin(identity: FirebaseIdentity) {
    const user = await this.user(identity);
    if (user.role !== 'ADMIN' && user.role !== 'SUPER_ADMIN') throw new BadRequestException('Administrator access is required.');
    return user;
  }

  private async validateAcceptedRules(type: HelpApplicationTypeDto, acceptedRuleIds: string[]) {
    const rules = await this.prisma.applicationRule.findMany({
      where: { type, isActive: true },
      select: { id: true, translations: { where: { language: { code: 'en' } }, select: { text: true }, take: 1 } },
    });
    const expected = new Set(rules.map((rule) => rule.id));
    const accepted = new Set(acceptedRuleIds ?? []);
    if (accepted.size !== expected.size || [...expected].some((id) => !accepted.has(id))) {
      throw new BadRequestException('Please acknowledge every current application rule before submitting.');
    }
    return rules.map((rule) => ({ id: rule.id, text: rule.translations[0]?.text ?? '' }));
  }

  private async application(id: string) {
    const item = await this.prisma.helpApplication.findUnique({ where: { id }, include: { media: { include: { media: true } }, facePhotoMedia: true, certificatePhotoMedia: true } });
    if (!item) throw new NotFoundException('Application not found.');
    return item;
  }

  private mediaResponse(item: any) {
    const base = process.env.R2_PUBLIC_BASE_URL?.replace(/\/$/, '');
    return { id: item.media.id, url: base ? base + '/' + item.media.storageKey : item.media.storageKey, mimeType: item.media.mimeType, width: item.media.width, height: item.media.height };
  }

  private toResponse(item: any) {
    return { id: item.id, type: item.type, status: item.status, applicantName: item.applicantName, mobileNumber: item.mobileNumber, email: item.email, address: item.address, city: item.city, state: item.state, pincode: item.pincode, requestedAmount: item.requestedAmount, overallPercentage: item.overallPercentage, approvedAmount: item.approvedAmount, rejectionReason: item.rejectionReason, clarification: item.clarification, motherName: item.motherName, fatherName: item.fatherName, dateOfBirth: item.dateOfBirth, classStandard: item.classStandard, schoolInstituteName: item.schoolInstituteName, accomplishments: item.accomplishments, certificatePhotoMediaId: item.certificatePhotoMediaId, facePhotoMediaId: item.facePhotoMediaId, facePhoto: item.facePhotoMedia ? this.mediaResponse({ media: item.facePhotoMedia }) : null, certificatePhoto: item.certificatePhotoMedia ? this.mediaResponse({ media: item.certificatePhotoMedia }) : null, adminNote: item.adminNote, submittedAt: item.submittedAt, reviewedAt: item.reviewedAt, media: (item.media ?? []).map((m: any) => this.mediaResponse(m)) };
  }

  private toAdminResponse(item: any) {
    return { ...this.toResponse(item), applicant: item.applicant ?? null, votes: (item.votes ?? []).map((v: any) => ({ id: v.id, adminId: v.adminId, adminName: v.admin?.displayName ?? null, score: v.score, comment: v.comment, updatedAt: v.updatedAt })), voteAverage: item.votes?.length ? item.votes.reduce((sum: number, v: any) => sum + v.score, 0) / item.votes.length : null };
  }
}
\nfunction csv(value: string | number): string {
  const text = String(value).replace(/"/g, '""');
  return `"${text}"`;
}

function safeFileName(value: string): string {
  const cleaned = value.normalize('NFKC').replace(/[\\/:*?"<>|\r\n]+/g, ' ').trim().replace(/\s+/g, '_');
  return (cleaned || 'Applicant').slice(0, 80);
}

