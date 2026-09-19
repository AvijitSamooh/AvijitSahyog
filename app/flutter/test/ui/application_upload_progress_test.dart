import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/features/applications/presentation/applications_page.dart';

void main() {
  testWidgets('shows animated upload progress while images are uploading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ApplicationUploadProgress(
            label: 'Uploading image...',
            completed: 2,
            total: 5,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('application_upload_progress')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Uploading image... 2/5'), findsOneWidget);

    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 0.4);
  });
}
