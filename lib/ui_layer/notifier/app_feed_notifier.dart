import 'package:flutter/material.dart';

class AppFeedPost {
  const AppFeedPost({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    required this.likes,
    required this.createdAt,
  });

  final int id;
  final String author;
  final String title;
  final String content;
  final int likes;
  final DateTime createdAt;
}

class AppFeedNotifier extends ChangeNotifier {
  final List<AppFeedPost> _posts = [
    AppFeedPost(
      id: 1001,
      author: 'G-Link 官方',
      title: 'Welcome to the new community',
      content:
          'This is the home skeleton based on the design draft, including tab, validation, animation and feedback.',
      likes: 126,
      createdAt: DateTime(2026, 4, 1, 9, 30),
    ),
    AppFeedPost(
      id: 1002,
      author: 'Product Reviewer',
      title: 'Which module should we refine first?',
      content:
          'We can first make a 1:1 home page, then complete search/message/publish flows.',
      likes: 84,
      createdAt: DateTime(2026, 4, 2, 10, 40),
    ),
    AppFeedPost(
      id: 1003,
      author: 'UI 设计师',
      title: 'Design handoff suggestion',
      content:
          'Provide node links for each page with spacing and radius specs for faster pixel-perfect implementation.',
      likes: 52,
      createdAt: DateTime(2026, 4, 3, 14, 12),
    ),
  ];

  List<AppFeedPost> get posts => List.unmodifiable(_posts);
  int? _latestCreatedPostId;
  int? get latestCreatedPostId => _latestCreatedPostId;

  void createPost({
    required String title,
    required String content,
    String author = 'Me',
  }) {
    final newPost = AppFeedPost(
      id: DateTime.now().millisecondsSinceEpoch,
      author: author,
      title: title,
      content: content,
      likes: 0,
      createdAt: DateTime.now(),
    );
    _posts.insert(0, newPost);
    _latestCreatedPostId = newPost.id;
    notifyListeners();
  }

  void consumeLatestCreatedPost() {
    if (_latestCreatedPostId == null) return;
    _latestCreatedPostId = null;
    notifyListeners();
  }
}
