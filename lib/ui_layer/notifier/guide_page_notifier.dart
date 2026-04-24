import 'package:flutter/material.dart';

class GuidePageNotifier extends ChangeNotifier {
  bool _showLeftWidget = false;

  bool get showLeftWidget => _showLeftWidget;

  void setShowLeftWidget(bool val) {
    _showLeftWidget = val;
    notifyListeners();
  }

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int val) {
    if (_currentIndex == val) return;
    _currentIndex = val;
    _showLeftWidget = _currentIndex > 0;
    notifyListeners();
  }

  void toPreviousStep() {
    if (_currentIndex == 0) return;
    setCurrentIndex(_currentIndex - 1);
  }

  void toNextStep() {
    if (_currentIndex >= 1) return;
    setCurrentIndex(_currentIndex + 1);
  }

  int _languageType = 0;

  int get languageType => _languageType;

  void setLanguageType(int val) {
    if (_languageType == val) return;
    _languageType = val;
    notifyListeners();
  }
}
