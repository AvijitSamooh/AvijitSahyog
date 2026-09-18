import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../causes/providers/causes_providers.dart';
import '../data/help_applications_repository.dart';
import '../models/help_application.dart';

final helpApplicationsRepositoryProvider = Provider<HelpApplicationsRepository>((ref) =>
    HelpApplicationsRepository(ref.watch(apiClientProvider)));

final myHelpApplicationsProvider =
    FutureProvider.autoDispose<List<HelpApplication>>((ref) =>
        ref.watch(helpApplicationsRepositoryProvider).mine());
