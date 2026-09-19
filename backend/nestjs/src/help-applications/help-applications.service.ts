import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseIdentity } from '../auth/auth.types';
import { CreateHelpApplicationDto, HelpApplicationTypeDto } from './dto/create-help-application.dto';
import { ResubmitHelpApplicationDto } from './dto/resubmit-help-application.dto';
import { ReviewHelpApplicationDto, HelpApplicationDecisionDto } from './dto/review-help-application.dto';
import { VoteHelpApplicationDto } from './dto/vote-help-application.dto';

@Injectable()
export class HelpApplicationsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(identity: FirebaseIdentity, dto: CreateHelpApplicationDto) {
    const user = await this.user(identity);
    this.validateApplicantDetails(dto);
    this.validateSubmission(dto.type, dto.requestedAmount, dto.mediaIds);
    const media = await this.validateMedia(dto.mediaIds, user.id);
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
        media: { create: media.map((mediaId) => ({ mediaId })) },
      },
      include: { media: { include: { media: true } } },
    });
    return this.toResponse(item);
  }

  async listMine(identity: FirebaseIdentity) {
    const user = await this.user(identity);
    const items = await this.prisma.helpApplication.findMany({
      where: { applicantId: user.id },
      orderBy: { createdAt: 'desc' },
      include: { media: { include: { media: true } }, votes: { select: { score: true } } },
    });
    return items.map((item) => this.toResponse(item));
  }

  async findMine(identity: FirebaseIdentity, id: string) {
    const user = await this.user(identity);
    const item = await this.prisma.helpApplication.findFirst({
      where: { id, applicantId: user.id },
      include: { media: { include: { media: true } } },
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
    if (existing.status !== 'REJECTED' && existing.status !== 'CLARIFICATION_REQUIRED') {
      throw new BadRequestException('Only rejected or clarification-requested applications can be resubmitted.');
    }
    this.validateSubmission(existing.type, dto.requestedAmount ?? Number(existing.requestedAmount ?? 0), dto.mediaIds);
    const media = await this.validateMedia(dto.mediaIds, user.id);
    return this.prisma.$transaction(async (tx) => {
      await tx.helpApplicationMedia.deleteMany({ where: { applicationId: id } });
      const updated = await tx.helpApplication.update({
        where: { id },
        data: {
          status: 'SUBMITTED',
          requestedAmount: dto.requestedAmount ?? existing.requestedAmount,
          approvedAmount: null,
          rejectionReason: null,
          clarification: dto.clarification.trim(),
          adminNote: null,
          reviewedAt: null,
          media: { create: media.map((mediaId) => ({ mediaId })) },
        },
        include: { media: { include: { media: true } } },
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
    return { id: item.id, type: item.type, status: item.status, applicantName: item.applicantName, mobileNumber: item.mobileNumber, email: item.email, address: item.address, city: item.city, state: item.state, pincode: item.pincode, requestedAmount: item.requestedAmount, approvedAmount: item.approvedAmount, rejectionReason: item.rejectionReason, clarification: item.clarification, adminNote: item.adminNote, submittedAt: item.submittedAt, reviewedAt: item.reviewedAt, media: (item.media ?? []).map((m: any) => this.mediaResponse(m)) };
  }

  private toAdminResponse(item: any) {
    return { ...this.toResponse(item), applicant: item.applicant ?? null, votes: (item.votes ?? []).map((v: any) => ({ id: v.id, adminId: v.adminId, adminName: v.admin?.displayName ?? null, score: v.score, comment: v.comment, updatedAt: v.updatedAt })), voteAverage: item.votes?.length ? item.votes.reduce((sum: number, v: any) => sum + v.score, 0) / item.votes.length : null };
  }
}
