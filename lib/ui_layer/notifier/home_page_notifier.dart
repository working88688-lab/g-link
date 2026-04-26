import 'dart:collection';

import 'package:flutter/material.dart';

class HomePageNotifier extends ChangeNotifier {
  int _selectedCategory = 0;
  bool _isSubmitting = false;
  final Set<int> _likedPostIds = <int>{};
  bool _disposed = false;

  int get selectedCategory => _selectedCategory;
  bool get isSubmitting => _isSubmitting;
  UnmodifiableSetView<int> get likedPostIds =>
      UnmodifiableSetView(_likedPostIds);

  void updateCategory(int index) {
    if (_selectedCategory == index) return;
    _selectedCategory = index;
    _safeNotify();
  }

  void toggleLike(int postId) {
    if (_likedPostIds.contains(postId)) {
      _likedPostIds.remove(postId);
    } else {
      _likedPostIds.add(postId);
    }
    _safeNotify();
  }

  Future<void> submitPost({
    required String title,
    required String content,
  }) async {
    if (title.isEmpty || content.isEmpty) return;
    _isSubmitting = true;
    _safeNotify();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _isSubmitting = false;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
