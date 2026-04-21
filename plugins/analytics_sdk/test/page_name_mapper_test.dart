import 'package:analytics_sdk/manager/page_name_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageNameMapper.normalizeKey', () {
    test('普通字符串不变', () {
      expect(PageNameMapper.normalizeKey('home'), 'home');
    });

    test('去掉单个前导斜杠', () {
      expect(PageNameMapper.normalizeKey('/home'), 'home');
    });

    test('去掉前导斜杠后剩余部分保留', () {
      expect(PageNameMapper.normalizeKey('/video_detail'), 'video_detail');
    });

    test('纯 / 保留原值（避免 pageKey 变空字符串）', () {
      expect(PageNameMapper.normalizeKey('/'), '/');
    });

    test('空字符串不变', () {
      expect(PageNameMapper.normalizeKey(''), '');
    });

    test('双斜杠开头只去掉第一个', () {
      expect(PageNameMapper.normalizeKey('//home'), '/home');
    });

    test('斜杠在中间不受影响', () {
      expect(PageNameMapper.normalizeKey('a/b'), 'a/b');
    });

    test('斜杠在结尾不受影响', () {
      expect(PageNameMapper.normalizeKey('home/'), 'home/');
    });
  });

  group('PageNameMapper.getPageName', () {
    setUp(() {
      PageNameMapper.clearCustom();
    });

    tearDown(() {
      PageNameMapper.clearCustom();
    });

    test('无映射时返回归一化后的 key', () {
      expect(PageNameMapper.getPageName('/home'), 'home');
    });

    test('有映射时返回映射名称（带斜杠注册）', () {
      PageNameMapper.addMapping('/home', '首页');
      expect(PageNameMapper.getPageName('/home'), '首页');
      expect(PageNameMapper.getPageName('home'), '首页');
    });

    test('有映射时返回映射名称（不带斜杠注册）', () {
      PageNameMapper.addMapping('home', '首页');
      expect(PageNameMapper.getPageName('/home'), '首页');
      expect(PageNameMapper.getPageName('home'), '首页');
    });

    test('纯 / 时 getPageName 返回 /', () {
      expect(PageNameMapper.getPageName('/'), '/');
    });
  });
}
