import 'package:flutter/foundation.dart';

class ThemeState extends ChangeNotifier {
  bool isDark = false;
  void toggle() {
    isDark = !isDark;
    notifyListeners();
  }
}
