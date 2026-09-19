import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/core/widgets/app_navigation_bar.dart';

void main() {
  test('primary navigation has exactly three destinations', () {
    expect(AppNavigationBar.destinationCount, 3);
  });
}
