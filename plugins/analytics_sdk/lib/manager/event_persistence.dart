export 'event_persistence_native.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'event_persistence_web.dart';

// EventPersistenceImpl 由条件导入文件提供
// Native：lib/manager/event_persistence_native.dart
// Web   ：lib/manager/event_persistence_web.dart
