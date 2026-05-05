import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum PublishType { post, video }

class PublishNotifier extends ChangeNotifier {
  PublishType publishType = PublishType.post;
  bool allowComment = true;
  bool syncToProfile = true;

  /// 「发布」按钮 loading：仅在调用发布接口（图文 / 视频）期间为 true。
  bool submitting = false;

  /// 「保存草稿」按钮 loading：仅在调用 `POST /drafts` 期间为 true。
  /// 与 [submitting] 互斥——任一为 true 时两条按钮都禁用，但 spinner 只出现在
  /// 实际触发的那一边，避免出现"点保存草稿但发布按钮转圈"的错觉。
  bool savingDraft = false;

  /// 任一发布动作或保存草稿动作进行中：用于禁用其它入口。
  bool get busy => submitting || savingDraft;

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

  void setSavingDraft(bool value) {
    if (savingDraft == value) return;
    savingDraft = value;
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
