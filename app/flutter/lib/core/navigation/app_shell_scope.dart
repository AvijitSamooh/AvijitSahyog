import 'package:flutter/material.dart';

class AppNavigationController extends ChangeNotifier {
  AppNavigationController({this.index = 0});
  int index;
  void select(int value) {
    if (index == value) return;
    index = value;
    notifyListeners();
  }
}

class AppShellScope extends InheritedWidget {
  const AppShellScope({super.key, required this.onLocaleChanged, required this.navigation, required super.child});
  final ValueChanged<Locale> onLocaleChanged;
  final AppNavigationController navigation;

  static AppShellScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppShellScope>();
    assert(scope != null, 'AppShellScope is required above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      onLocaleChanged != oldWidget.onLocaleChanged || navigation != oldWidget.navigation;
}
