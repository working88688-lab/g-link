import 'package:analytics_sdk/entity/analytics_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsTab', () {
    test('key 赋值正确，name 默认为 null', () {
      const tab = AnalyticsTab('home');
      expect(tab.key, 'home');
      expect(tab.name, isNull);
    });

    test('显式传入 name', () {
      const tab = AnalyticsTab('home', '首页');
      expect(tab.key, 'home');
      expect(tab.name, '首页');
    });

    test('const 构造可用', () {
      const tabs = [AnalyticsTab('a'), AnalyticsTab('b', 'B')];
      expect(tabs.length, 2);
    });
  });
}
