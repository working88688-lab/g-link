import 'dart:collection';

import 'package:flutter/material.dart';

class HomePageNotifier extends ChangeNotifier {
  int _selectedCategory = 0;
  bool _isSubmitting = false;
  final Set<int> _likedPostIds = <int>{};

  int get selectedCategory => _selectedCategory;
  bool get isSubmitting => _isSubmitting;
  UnmodifiableSetView<int> get likedPostIds =>
      UnmodifiableSetView(_likedPostIds);

  void updateCategory(int index) {
    if (_selectedCategory == index) return;
    _selectedCategory = index;
    notifyListeners();
  }

  void toggleLike(int postId) {
    if (_likedPostIds.contains(postId)) {
      _likedPostIds.remove(postId);
    } else {
      _likedPostIds.add(postId);
    }
    notifyListeners();
  }

  Future<void> submitPost({
    required String title,
    required String content,
  }) async {
    if (title.isEmpty || content.isEmpty) return;
    _isSubmitting = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _isSubmitting = false;
    notifyListeners();
  }
}
