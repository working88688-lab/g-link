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