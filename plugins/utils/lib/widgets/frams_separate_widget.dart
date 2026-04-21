import 'dart:async';
import 'dart:collection';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class FrameSeparateWidget extends StatefulWidget {
  const FrameSeparateWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  FrameSeparateWidgetState createState() => FrameSeparateWidgetState();
}

class FrameSeparateWidgetState extends State<FrameSeparateWidget> {
  Widget? result;

  @override
  void initState() {
    super.initState();
    result = const SizedBox.shrink();
    transformWidget();
  }

  @override
  void didUpdateWidget(FrameSeparateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    transformWidget();
  }

  @override
  Widget build(BuildContext context) {
    return result!;
  }

  void transformWidget() {
    SchedulerBinding.instance.addPostFrameCallback((Duration t) {
      FrameSeparateTaskQueue.instance!.scheduleTask(() {
        if (mounted) {
          setState(() {
            result = widget.child;
          });
        }
      }, Priority.animation, () => !mounted);
    });
  }
}

class FrameSeparateTaskQueue {
  FrameSeparateTaskQueue._();

  bool _hasRequestedAnEventLoopCallback = false;

  static FrameSeparateTaskQueue? _instance;

  static FrameSeparateTaskQueue? get instance {
    _instance ??= FrameSeparateTaskQueue._();
    return _instance;
  }

  SchedulingStrategy schedulingStrategy = defaultSchedulingStrategy;

  final Queue<TaskEntry<dynamic>> _taskQueue = ListQueue();

  int get taskLength => _taskQueue.length;

  Future<bool> handleEventLoopCallback() async {
    if (_taskQueue.isEmpty) return false;
    final TaskEntry<dynamic> entry = _taskQueue.first;
    if (schedulingStrategy(
        priority: entry.priority, scheduler: SchedulerBinding.instance)) {
      try {
        _taskQueue.removeFirst();
        entry.run();
      } catch (_, __) {}
      return _taskQueue.isNotEmpty;
    }
    return true;
  }

  Future<void> _ensureEventLoopCallback() async {
    assert(_taskQueue.isNotEmpty);
    if (_hasRequestedAnEventLoopCallback) return;
    _hasRequestedAnEventLoopCallback = true;
    Timer.run(() {
      _removeIgnoreTasks();
      _runTasks();
    });
  }

  Future<void> _runTasks() async {
    await SchedulerBinding.instance.endOfFrame;
    _hasRequestedAnEventLoopCallback = false;
    if (await handleEventLoopCallback()) {
      _ensureEventLoopCallback();
    }
  }

  void _removeIgnoreTasks() {
    while (_taskQueue.isNotEmpty) {
      if (!_taskQueue.first.canIgnore()) {
        break;
      }
      _taskQueue.removeFirst();
    }
  }

  Future<T> scheduleTask<T>(
      TaskCallback<T> task, Priority priority, ValueGetter<bool> canIgnore,
      {String? debugLabel, Flow? flow, int? id}) {
    final TaskEntry<T> entry = TaskEntry<T>(task, priority.value, canIgnore);
    _addTask(entry);
    _ensureEventLoopCallback();
    return entry.completer.future;
  }

  void _addTask(TaskEntry taskEntry) {
    _taskQueue.add(taskEntry);
  }
}

class TaskEntry<T> {
  TaskEntry(
    this.task,
    this.priority,
    this.canIgnore,
  ) {
    completer = Completer<T>();
  }

  final TaskCallback<T> task;
  final int priority;
  final ValueGetter<bool> canIgnore;
  late Completer<T> completer;

  void run() {
    completer.complete(task());
  }
}
