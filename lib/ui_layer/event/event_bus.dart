import 'package:event_bus/event_bus.dart';

final EventBus eventBus = EventBus();

class MyEvent {
  final String message;

  MyEvent(this.message);
}