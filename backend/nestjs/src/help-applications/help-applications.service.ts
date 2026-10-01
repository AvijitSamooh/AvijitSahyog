import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseIdentity } from '../auth/auth.types';
import { CreateHelpApplicationDto, HelpApplicationTypeDto } from './dto/create-help-application.dto';
import { ResubmitHelpApplicationDto } from './dto/resubmit-help-application.dto';
import { ReviewHelpApplicationDto, HelpApplicationDecisionDto } from './dto/review-help-application.dto';
import { VoteHelpApplicationDto } from './dto/vote-help-application.dto';
import { ApplicationWindowsService } from './application-windows.service';

@Injectable()
export class HelpApplicationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly applicationWindows: ApplicationWindowsService,
  ) {}

  async create(identity: FirebaseIdentity, dto: CreateHelpApplicationDto) {
    const user = await this.user(identity);
    await this.applicationWindows.ensureAccepting(dto.type);
    this.validateApplicantDetails(dto);
    this.validateSubmission(dto.type, dto.requestedAmount, dto.mediaIds);
    this.validatePratibhaDetails(dto.type, dto);
    const acceptedRules = await this.validateAcceptedRules(dto.type, dto.acceptedRuleIds);
    const media = await this.validateMedia(dto.mediaIds, user.id);
    const certificatePhotoMediaId = await this.validateCertificatePhoto(dto.type, dto.certificatePhotoMediaId, user.id);
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
        clarification: dto.clarification?.trim() || null,
        motherName: dto.motherName?.trim() || null,
        fatherName: dto.fatherName?.trim() || null,
        dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : null,
        classStandard: dto.classStandard?.trim() || null,
        schoolInstituteName: dto.schoolInstituteName?.trim() || null,
        accomplishments: dto.accomplishments?.trim() || null,
        certificatePhotoMediaId,
        media: { create: media.map((mediaId) => ({ mediaId })) },
        ruleAcceptances: { create: acceptedRules.map((rule) => ({ ruleId: rule.id, ruleText: rule.text })) },
      },
      include: { media: { include: { media: true } }, certificatePhotoMedia: true },
    });
    return this.toResponse(item);
  }

  async listMine(identity: FirebaseIdentity) {
    const user = await this.user(identity);
    const items = await this.prisma.helpApplication.findMany({
      where: { applicantId: user.id },
      orderBy: { createdAt: 'desc' },
      include: { media: { include: { media: true } }, certificatePhotoMedia: true, votes: { select: { score: true } } },
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
      await tx.helpApplicationMedia.deleteMany({ where: { applicationId: id } });
      await tx.helpApplicationRuleAcceptance.deleteMany({ where: { applicationId: id } });
      const updated = await tx.helpApplication.update({
        where: { id },
        data: {
          status: 'SUBMITTED',
          requestedAmount: dto.requestedAmount ?? existing.requestedAmount,
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
      orderBy: [{ status: 'asc' }, { createdAt: 'asc' }],
      include: {
        applicant: { select: { id: true, displayName: true, email: true } },
        media: { include: { media: true } },
        certificatePhotoMedia: true,
        votes: { include: { admin: { select: { id: true, displayName: true } } }, orderBy: { updatedAt: 'desc' } },
      },
    });
    const responses = items.map((item) => this.toAdminResponse(item));
    if (type === 'PRATIBHA_SAMMAN') {
      responses.sort((a, b) => (b.voteAverage ?? -1) - (a.voteAverage ?? -1));
    }
    return responses;
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
    return this.updateStatus(id, dto.decision === HelpApplicationDecisionDto.CONSIDER_FOR_SAMMAN ? 'CONSIDERED_FOR_SAMMAN' : 'NOT_SELECTED', null, dto.reason?.trim() || null, dto.note);
  }

  private async updateStatus(id: string, status: any, approvedAmount: number | null, reason: string | null, note?: string) {
    const item = await this.prisma.helpApplication.update({
      where: { id },
      data: { status, approvedAmount, rejectionReason: reason, adminNote: note?.trim() || null, reviewedAt: new Date() },
      include: {
        applicant: { select: { id: true, displayName: true, email: true } },
        media: { include: { media: true } },
        certificatePhotoMedia: true,
        votes: { include: { admin: { select: { id: true, displayName: true } } } },
      },
    });
    return this.toAdminResponse(item);
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

  private async validateCertificatePhoto(type: string, mediaId: string | undefined, uploadedById: string) {
    if (type !== HelpApplicationTypeDto.PRATIBHA_SAMMAN) return null;
    if (!mediaId) throw new BadRequestException('A clear certificate photo is required for Pratibha Samman.');
    const media = await this.prisma.media.findFirst({
      where: { id: mediaId, uploadedById },
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
    const item = await this.prisma.helpApplication.findUnique({ where: { id }, include: { media: { include: { media: true } } } });
    if (!item) throw new NotFoundException('Application not found.');
    return item;
  }

  private mediaResponse(item: any) {
    const base = process.env.R2_PUBLIC_BASE_URL?.replace(/\/$/, '');
    return { id: item.media.id, url: base ? base + '/' + item.media.storageKey : item.media.storageKey, mimeType: item.media.mimeType, width: item.media.width, height: item.media.height };
  }

  private toResponse(item: any) {
    return { id: item.id, type: item.type, status: item.status, applicantName: item.applicantName, mobileNumber: item.mobileNumber, email: item.email, address: item.address, city: item.city, state: item.state, pincode: item.pincode, requestedAmount: item.requestedAmount, approvedAmount: item.approvedAmount, rejectionReason: item.rejectionReason, clarification: item.clarification, motherName: item.motherName, fatherName: item.fatherName, dateOfBirth: item.dateOfBirth, classStandard: item.classStandard, schoolInstituteName: item.schoolInstituteName, accomplishments: item.accomplishments, certificatePhoto: item.certificatePhotoMedia ? this.mediaResponse({ media: item.certificatePhotoMedia }) : null, adminNote: item.adminNote, submittedAt: item.submittedAt, reviewedAt: item.reviewedAt, media: (item.media ?? []).map((m: any) => this.mediaResponse(m)) };
  }

  private toAdminResponse(item: any) {
    return { ...this.toResponse(item), applicant: item.applicant ?? null, votes: (item.votes ?? []).map((v: any) => ({ id: v.id, adminId: v.adminId, adminName: v.admin?.displayName ?? null, score: v.score, comment: v.comment, updatedAt: v.updatedAt })), voteAverage: item.votes?.length ? item.votes.reduce((sum: number, v: any) => sum + v.score, 0) / item.votes.length : null };
  }
}
