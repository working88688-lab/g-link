import 'package:analytics_sdk/entity/analytics_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsUtils.configure field semantics', () {
    setUp(() {
      AnalyticsUtils.configure(
        appId: 'app1',
        channel: 'ch1',
        uid: 'user1',
        device: 'Android',
        deviceId: 'dev1',
      );
    });

    test('configure with null does NOT clear existing value', () {
      AnalyticsUtils.configure(uid: null);
      expect(AnalyticsUtils.uid, 'user1');
    });

    test('configure with empty string DOES clear existing value', () {
      AnalyticsUtils.configure(uid: '');
      expect(AnalyticsUtils.uid, '');
    });

    test('setUid clears uid to empty string', () {
      AnalyticsUtils.setUid('');
      expect(AnalyticsUtils.uid, '');
    });

    test('reset clears all fields to null', () {
      AnalyticsUtils.reset();
      expect(AnalyticsUtils.appId, isNull);
      expect(AnalyticsUtils.uid, isNull);
      expect(AnalyticsUtils.channel, isNull);
      expect(AnalyticsUtils.deviceId, isNull);
    });
  });
}
