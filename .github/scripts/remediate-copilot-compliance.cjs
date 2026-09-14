const fs = require('fs');
const path = require('path');

const root = process.env.REPO_ROOT || process.cwd();
const write = (rel, content) => fs.writeFileSync(path.join(root, rel), content);

const localisation = {
  en: {
    adminCreateOrganisation: 'Create organisation',
    adminRetryLoadingOrganisations: 'Retry loading organisations',
    adminNoOrganisations: 'No organisations created yet.',
    adminOrganisationCauseCount: '{count} causes',
    adminOrganisationActions: 'Organisation actions',
    adminDeleteOrganisation: 'Delete organisation',
    adminDeleteOrganisationTitle: 'Delete organisation?',
    adminDeleteOrganisationConfirmation: 'Delete “{organisation}” permanently? This cannot be undone. If it has donation allocations or beneficiary records, deletion will be blocked and the organisation must be deactivated instead.',
    adminDeleteOrganisationSuccess: '“{organisation}” was deleted.',
  },
  hi: {
    adminCreateOrganisation: 'संस्था बनाएँ',
    adminRetryLoadingOrganisations: 'संस्थाओं को लोड करने के लिए पुनः प्रयास करें',
    adminNoOrganisations: 'अभी तक कोई संस्था नहीं बनाई गई है।',
    adminOrganisationCauseCount: '{count} सेवा क्षेत्र',
    adminOrganisationActions: 'संस्था के विकल्प',
    adminDeleteOrganisation: 'संस्था हटाएँ',
    adminDeleteOrganisationTitle: 'संस्था हटाएँ?',
    adminDeleteOrganisationConfirmation: 'क्या आप “{organisation}” को स्थायी रूप से हटाना चाहते हैं? इसे वापस नहीं किया जा सकता। यदि इसमें दान आवंटन या लाभार्थी रिकॉर्ड हैं, तो हटाना रोका जाएगा और संस्था को निष्क्रिय करना होगा।',
    adminDeleteOrganisationSuccess: '“{organisation}” हटा दी गई।',
  },
  mr: {
    adminCreateOrganisation: 'संस्था तयार करा',
    adminRetryLoadingOrganisations: 'संस्था लोड करण्यासाठी पुन्हा प्रयत्न करा',
    adminNoOrganisations: 'अद्याप कोणतीही संस्था तयार केलेली नाही.',
    adminOrganisationCauseCount: '{count} सेवा क्षेत्रे',
    adminOrganisationActions: 'संस्था कृती',
    adminDeleteOrganisation: 'संस्था हटवा',
    adminDeleteOrganisationTitle: 'संस्था हटवायची?',
    adminDeleteOrganisationConfirmation: '“{organisation}” कायमची हटवायची का? ही कृती पूर्ववत करता येणार नाही. दान वाटप किंवा लाभार्थी नोंदी असल्यास हटवणे रोखले जाईल आणि संस्था निष्क्रिय करावी लागेल.',
    adminDeleteOrganisationSuccess: '“{organisation}” हटवली.',
  },
  gu: {
    adminCreateOrganisation: 'સંસ્થા બનાવો',
    adminRetryLoadingOrganisations: 'સંસ્થાઓ લોડ કરવા માટે ફરી પ્રયાસ કરો',
    adminNoOrganisations: 'હજુ સુધી કોઈ સંસ્થા બનાવવામાં આવી નથી.',
    adminOrganisationCauseCount: '{count} કારણો',
    adminOrganisationActions: 'સંસ્થાની ક્રિયાઓ',
    adminDeleteOrganisation: 'સંસ્થા કાઢી નાખો',
    adminDeleteOrganisationTitle: 'સંસ્થા કાઢી નાખવી છે?',
    adminDeleteOrganisationConfirmation: 'શું તમે “{organisation}”ને કાયમ માટે કાઢી નાખવા માંગો છો? આ પાછું કરી શકાશે નહીં. જો તેમાં દાન ફાળવણી અથવા લાભાર્થી રેકોર્ડ હોય, તો કાઢી નાખવાનું અટકાવવામાં આવશે અને સંસ્થાને નિષ્ક્રિય કરવી પડશે.',
    adminDeleteOrganisationSuccess: '“{organisation}” કાઢી નાખવામાં આવી.',
  },
};

for (const [locale, values] of Object.entries(localisation)) {
  const file = path.join(root, `app/flutter/lib/l10n/app_${locale}.arb`);
  let text = fs.readFileSync(file, 'utf8');
  if (text.includes('"adminDeleteOrganisation"')) continue;
  const additions = Object.entries(values).map(([key, value]) => {
    const placeholder = value.includes('{')
      ? `,\n  "@${key}": {"placeholders": {"${key === 'adminOrganisationCauseCount' ? 'count' : 'organisation'}": {}}}`
      : '';
    return `  "${key}": ${JSON.stringify(value)}${placeholder}`;
  }).join(',\n');
  const marker = '\n}\n';
  const index = text.lastIndexOf(marker);
  if (index < 0) throw new Error(`Could not find ARB end marker in ${file}`);
  text = `${text.slice(0, index)},\n${additions}${text.slice(index)}`;
  fs.writeFileSync(file, text);
}

write('app/flutter/lib/features/admin/presentation/admin_organisations_page.dart', `import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_settings_menu.dart';

import '../../../l10n/app_localizations.dart';
import '../models/admin_organisation.dart';
import '../providers/admin_organisations_providers.dart';
import 'admin_organisation_editor_page.dart';

class AdminOrganisationsPage extends ConsumerWidget {
  const AdminOrganisationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final organisations = ref.watch(adminOrganisationsProvider);
    return AppPageScaffold(
      title: Text(l10n.adminManageOrganisations),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('admin_create_organisation'),
        icon: const Icon(Icons.add),
        label: Text(l10n.adminCreateOrganisation),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AdminOrganisationEditorPage(),
            ),
          );
          ref.invalidate(adminOrganisationsProvider);
        },
      ),
      body: organisations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(adminOrganisationsProvider),
            child: Text(l10n.adminRetryLoadingOrganisations),
          ),
        ),
        data: (items) => items.isEmpty
            ? Center(child: Text(l10n.adminNoOrganisations))
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(adminOrganisationsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _OrganisationTile(organisation: items[index]),
                ),
              ),
      ),
    );
  }
}

class _OrganisationTile extends ConsumerWidget {
  const _OrganisationTile({required this.organisation});
  final AdminOrganisation organisation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        key: ValueKey('admin_organisation_${organisation.id}'),
        title: Text(organisation.displayName),
        subtitle: Text(
          '${organisation.slug} • ${l10n.adminOrganisationCauseCount(organisation.causeIds.length)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: organisation.isActive,
              onChanged: (value) async {
                try {
                  await ref
                      .read(adminOrganisationsRepositoryProvider)
                      .setActive(organisation.id, value);
                  ref.invalidate(adminOrganisationsProvider);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.toString())),
                    );
                  }
                }
              },
            ),
            PopupMenuButton<String>(
              tooltip: l10n.adminOrganisationActions,
              onSelected: (action) {
                if (action == 'delete') {
                  _deleteOrganisation(context, ref);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(l10n.adminDeleteOrganisation),
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  AdminOrganisationEditorPage(organisation: organisation),
            ),
          );
          ref.invalidate(adminOrganisationsProvider);
        },
      ),
    );
  }

  Future<void> _deleteOrganisation(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminDeleteOrganisationTitle),
        content: Text(
          l10n.adminDeleteOrganisationConfirmation(organisation.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.adminDeleteOrganisation),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(adminOrganisationsRepositoryProvider)
          .delete(organisation.id);
      ref.invalidate(adminOrganisationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.adminDeleteOrganisationSuccess(organisation.displayName),
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}
`);

write('backend/nestjs/src/admin-users/dto/admin-users-query.dto.ts', `import { Transform, Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class AdminUsersQueryDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  search?: string;

  @Transform(({ value }) => value ?? 'ADMIN')
  @IsIn(['USER', 'ADMIN'])
  role: 'USER' | 'ADMIN' = 'ADMIN';

  @Type(() => Number)
  @IsInt()
  @Min(1)
  page = 1;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(20)
  pageSize = 3;
}
`);

write('backend/nestjs/src/admin-users/dto/change-admin-user-role.dto.ts', `import { IsIn } from 'class-validator';

export class ChangeAdminUserRoleDto {
  @IsIn(['USER', 'ADMIN'])
  role!: 'USER' | 'ADMIN';
}
`);

write('backend/nestjs/src/admin-users/admin-users.controller.ts', `import { BadRequestException, Body, Controller, Get, Param, Patch, Req, UseGuards } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import type { Request } from 'express';
import { AdminGuard } from '../auth/admin.guard';
import { SuperAdminGuard } from '../auth/super-admin.guard';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { AdminUsersQueryDto } from './dto/admin-users-query.dto';
import { ChangeAdminUserRoleDto } from './dto/change-admin-user-role.dto';
import { AdminUsersService } from './admin-users.service';

@Controller('admin/users')
@UseGuards(AdminGuard)
export class AdminUsersController {
  constructor(private readonly service: AdminUsersService) {}

  @Get()
  @UseGuards(SuperAdminGuard)
  async listUsers(@Req() request: Request) {
    const dto = plainToInstance(AdminUsersQueryDto, request.query);
    const errors = await validate(dto, { whitelist: true, forbidNonWhitelisted: true });
    if (errors.length) {
      throw new BadRequestException('Invalid admin user query.');
    }
    return this.service.listUsers(dto);
  }

  @Patch(':id/role')
  @UseGuards(SuperAdminGuard)
  async changeRole(
    @Param('id') id: string,
    @Body() body: ChangeAdminUserRoleDto,
    @Req() request: Request & AuthenticatedRequest,
  ) {
    const dto = plainToInstance(ChangeAdminUserRoleDto, body);
    const errors = await validate(dto, { whitelist: true, forbidNonWhitelisted: true });
    if (errors.length) {
      throw new BadRequestException('Invalid administrator role.');
    }
    return this.service.changeRole(id, request.user.uid, dto.role);
  }

  @Get('audit-history')
  @UseGuards(SuperAdminGuard)
  getAuditHistory() {
    return this.service.getAuditHistory();
  }
}
`);

write('backend/nestjs/src/admin-users/dto/admin-users-query.dto.spec.ts', `import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AdminUsersQueryDto } from './admin-users-query.dto';

describe('AdminUsersQueryDto', () => {
  it('uses safe defaults for an empty query', async () => {
    const dto = plainToInstance(AdminUsersQueryDto, {});
    expect(await validate(dto)).toHaveLength(0);
    expect(dto).toEqual(expect.objectContaining({ role: 'ADMIN', page: 1, pageSize: 3 }));
  });

  it('trims search and transforms valid pagination values', async () => {
    const dto = plainToInstance(AdminUsersQueryDto, {
      search: '  nikita  ',
      role: 'USER',
      page: '2',
      pageSize: '10',
    });
    expect(await validate(dto)).toHaveLength(0);
    expect(dto).toEqual(expect.objectContaining({
      search: 'nikita',
      role: 'USER',
      page: 2,
      pageSize: 10,
    }));
  });

  it.each([
    ['role', { role: 'SUPER_ADMIN' }],
    ['page', { page: '0' }],
    ['pageSize', { pageSize: '21' }],
    ['pageSize type', { pageSize: [] }],
  ])('rejects invalid %s', async (_, query) => {
    const dto = plainToInstance(AdminUsersQueryDto, query);
    expect(await validate(dto)).not.toHaveLength(0);
  });
});
`);

write('backend/nestjs/src/admin-users/dto/change-admin-user-role.dto.spec.ts', `import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { ChangeAdminUserRoleDto } from './change-admin-user-role.dto';

describe('ChangeAdminUserRoleDto', () => {
  it.each(['USER', 'ADMIN'])('accepts %s', async (role) => {
    const dto = plainToInstance(ChangeAdminUserRoleDto, { role });
    expect(await validate(dto)).toHaveLength(0);
  });

  it('rejects Super Admin and missing roles', async () => {
    for (const role of ['SUPER_ADMIN', undefined]) {
      const dto = plainToInstance(ChangeAdminUserRoleDto, { role });
      expect(await validate(dto)).not.toHaveLength(0);
    }
  });
});
`);

write('backend/nestjs/src/admin-users/admin-users.controller.spec.ts', `import { BadRequestException } from '@nestjs/common';
import type { Request } from 'express';
import { AdminUsersController } from './admin-users.controller';

describe('AdminUsersController', () => {
  const service = {
    listUsers: jest.fn(),
    changeRole: jest.fn(),
    getAuditHistory: jest.fn(),
  };

  beforeEach(() => jest.clearAllMocks());

  it('validates and normalizes admin user query input before the service call', async () => {
    service.listUsers.mockResolvedValue({ items: [] });
    const controller = new AdminUsersController(service as never);

    await controller.listUsers({
      query: { search: '  alice ', role: 'USER', page: '2', pageSize: '10' },
    } as unknown as Request);

    expect(service.listUsers).toHaveBeenCalledWith(expect.objectContaining({
      search: 'alice', role: 'USER', page: 2, pageSize: 10,
    }));
  });

  it('rejects invalid query input before the service call', async () => {
    const controller = new AdminUsersController(service as never);
    await expect(controller.listUsers({ query: { pageSize: '21' } } as unknown as Request))
      .rejects.toBeInstanceOf(BadRequestException);
    expect(service.listUsers).not.toHaveBeenCalled();
  });

  it('validates role changes before the service call', async () => {
    service.changeRole.mockResolvedValue({ id: 'user-1' });
    const controller = new AdminUsersController(service as never);

    await controller.changeRole(
      'user-1',
      { role: 'ADMIN' },
      { user: { uid: 'actor-1' } } as never,
    );

    expect(service.changeRole).toHaveBeenCalledWith('user-1', 'actor-1', 'ADMIN');
  });

  it('rejects invalid role changes before the service call', async () => {
    const controller = new AdminUsersController(service as never);
    await expect(controller.changeRole(
      'user-1',
      { role: 'SUPER_ADMIN' } as never,
      { user: { uid: 'actor-1' } } as never,
    )).rejects.toBeInstanceOf(BadRequestException);
    expect(service.changeRole).not.toHaveBeenCalled();
  });
});
`);

fs.mkdirSync(path.join(root, 'app/flutter/test/l10n'), { recursive: true });
write('app/flutter/test/l10n/admin_organisation_localization_test.dart', `import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

describe('admin organisation localization', () {
  test('deletion and organisation management strings exist in every supported locale', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(l10n.adminCreateOrganisation, isNotEmpty);
      expect(l10n.adminOrganisationActions, isNotEmpty);
      expect(l10n.adminDeleteOrganisation, isNotEmpty);
      expect(l10n.adminDeleteOrganisationTitle, isNotEmpty);
      expect(l10n.adminDeleteOrganisationConfirmation('Test Organisation'), isNotEmpty);
      expect(l10n.adminDeleteOrganisationSuccess('Test Organisation'), isNotEmpty);
    }
  });
});
`);
