import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum PublishType { post, video }

class PublishNotifier extends ChangeNotifier {
  PublishType publishType = PublishType.post;
  bool allowComment = true;
  bool syncToProfile = true;
  bool submitting = false;

  void updateType(PublishType type) {
    if (publishType == type) return;
    publishType = type;
    notifyListeners();
  }

  void toggleComment(bool value) {
    allowComment = value;
    notifyListeners();
  }

  void toggleSync(bool value) {
    syncToProfile = value;
    notifyListeners();
  }

  void setSubmitting(bool value) {
    if (submitting == value) return;
    submitting = value;
    notifyListeners();
  }

  Future<void> submit() async {
    submitting = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    submitting = false;
    notifyListeners();
  }
}
