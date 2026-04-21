import 'package:analytics_sdk/utils/event_validator.dart';
import 'package:analytics_sdk/manager/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    SessionManager.instance.reset();
    SessionManager.instance.initialize();
  });

  tearDown(() {
    SessionManager.instance.reset();
  });

  group('EventValidator type coercion', () {
    Map<String, dynamic> makeEvent({dynamic uid, dynamic channel}) {
      return {
        'event': 'test_event',
        'event_id': 'abc123',
        'app_id': 'app1',
        'sid': SessionManager.instance.getSessionId(),
        'client_ts': 1711929600,
        'device_id': 'dev1',
        if (uid != null) 'uid': uid,
        if (channel != null) 'channel': channel,
      };
    }

    test('int uid is coerced to string', () {
      final result = EventValidator.validate(makeEvent(uid: 12345));
      expect(result, isNotNull);
      expect(result!['uid'], '12345');
    });

    test('double uid is coerced to string', () {
      final result = EventValidator.validate(makeEvent(uid: 123.0));
      expect(result, isNotNull);
      expect(result!['uid'], '123.0');
    });

    test('int channel is coerced to string', () {
      final result = EventValidator.validate(makeEvent(channel: 100));
      expect(result, isNotNull);
      expect(result!['channel'], '100');
    });

    test('string uid is preserved', () {
      final result = EventValidator.validate(makeEvent(uid: 'user_abc'));
      expect(result, isNotNull);
      expect(result!['uid'], 'user_abc');
    });

    test('bool uid is coerced to string', () {
      final result = EventValidator.validate(makeEvent(uid: true));
      expect(result, isNotNull);
      expect(result!['uid'], 'true');
    });
  });
}
