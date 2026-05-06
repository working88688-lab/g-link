import 'package:event_bus/event_bus.dart';

final EventBus eventBus = EventBus();

class MyEvent {
  final String message;

  MyEvent(this.message);
}

class FollowStatusChangedEvent {
  const FollowStatusChangedEvent({
    required this.uid,
    required this.isFollowing,
  });

  final int uid;
  final bool isFollowing;
}

/// 图文帖子已通过 `POST /api/v1/posts` 发布成功，用于首页 Feed 刷新等。
class PostPublishedEvent {
  const PostPublishedEvent({required this.postId});

  final int postId;
}

/// 短视频已通过 `POST /api/v1/videos/{id}/publish` 发布成功。
class VideoPublishedEvent {
  const VideoPublishedEvent({required this.videoId});

  final int videoId;
}