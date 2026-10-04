import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { FirebaseService } from '../firebase/firebase.service';
import { HelpApplicationTypeDto } from './dto/create-help-application.dto';
import { CreateApplicationRuleDto, SUPPORTED_RULE_LANGUAGES, UpdateApplicationRuleDto, validateRuleTranslations } from './dto/application-rule.dto';

interface RuleDocument {
  id: string;
  type: HelpApplicationTypeDto;
  displayOrder: number;
  isActive: boolean;
  translations: Record<string, string>;
  createdAt?: Date;
  updatedAt?: Date;
}

@Injectable()
export class FirestoreApplicationRulesService {
  constructor(private readonly firebase: FirebaseService) {}

  async syncRule(document: RuleDocument) {
    await this.firebase.db.collection('applicationRules').doc(document.id).set(document, { merge: true });
  }

  async list(type: HelpApplicationTypeDto, language = 'en') {
    const requested = SUPPORTED_RULE_LANGUAGES.includes(language as any) ? language : 'en';
    const snapshot = await this.firebase.db
      .collection('applicationRules')
      .where('type', '==', type)
      .where('isActive', '==', true)
      .orderBy('displayOrder', 'asc')
      .get();

    return snapshot.docs
      .map((doc) => doc.data() as RuleDocument)
      .map((rule) => ({
        id: rule.id,
        type: rule.type,
        displayOrder: rule.displayOrder,
        text: rule.translations?.[requested] ?? rule.translations?.en ?? '',
      }));
  }

  async listAdmin(type: HelpApplicationTypeDto) {
    const snapshot = await this.firebase.db
      .collection('applicationRules')
      .where('type', '==', type)
      .orderBy('displayOrder', 'asc')
      .get();

    return snapshot.docs.map((doc) => {
      const rule = doc.data() as RuleDocument;
      return {
        id: rule.id,
        type: rule.type,
        displayOrder: rule.displayOrder,
        isActive: rule.isActive,
        translations: Object.entries(rule.translations ?? {}).map(([language, text]) => ({ language, text })),
      };
    });
  }

  async listForAcceptance(type: HelpApplicationTypeDto) {
    const rules = await this.list(type, 'en');
    return rules.map((rule) => ({ id: rule.id, text: rule.text }));
  }

  async create(dto: CreateApplicationRuleDto) {
    const translations = this.validate(dto.translations);
    const id = randomUUID();
    const document: RuleDocument = {
      id,
      type: dto.type,
      displayOrder: dto.displayOrder,
      isActive: dto.isActive ?? true,
      translations: Object.fromEntries(translations.map((item) => [item.language, item.text])),
    };
    await this.syncRule(document);
    return document;
  }

  async update(id: string, dto: UpdateApplicationRuleDto) {
    const ref = this.firebase.db.collection('applicationRules').doc(id);
    const snapshot = await ref.get();
    if (!snapshot.exists) throw new NotFoundException('Application rule not found.');

    const existing = snapshot.data() as RuleDocument;
    const translations = this.validate(dto.translations);
    const document: RuleDocument = {
      ...existing,
      id,
      displayOrder: dto.displayOrder ?? existing.displayOrder,
      isActive: dto.isActive ?? existing.isActive,
      translations: Object.fromEntries(translations.map((item) => [item.language, item.text])),
    };
    await ref.set(document, { merge: true });
    return document;
  }

  async remove(id: string) {
    const ref = this.firebase.db.collection('applicationRules').doc(id);
    const snapshot = await ref.get();
    if (!snapshot.exists) throw new NotFoundException('Application rule not found.');
    await ref.update({ isActive: false });
    return { id, deleted: true };
  }

  private validate(translations: CreateApplicationRuleDto['translations']) {
    try {
      return validateRuleTranslations(translations);
    } catch (error) {
      throw new BadRequestException((error as Error).message);
    }
  }
}
