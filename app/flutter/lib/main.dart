import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/health/client_health_reporter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final reporter = ClientHealthReporter();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reporter.report(type: 'APP_ERROR', error: details.exception, stack: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.report(type: 'APP_CRASH', error: error, stack: stack);
    return true;
  };

  runApp(const ProviderScope(child: AvijitSahyogApp()));
}
