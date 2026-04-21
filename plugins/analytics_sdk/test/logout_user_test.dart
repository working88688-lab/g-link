import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/enum/user_type_enum.dart';
import 'package:analytics_sdk/manager/user_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    UserManager.instance.updateUserType(UserTypeEnum.normal.label);
  });

  group('logoutUser', () {
    test('logoutUser resets uid and userType to normal', () {
      AnalyticsSdk.setUserIdAndType(
        userId: 'user123',
        userTypeEnum: UserTypeEnum.vip,
      );
      expect(UserManager.instance.userType, UserTypeEnum.vip.label);

      AnalyticsSdk.logoutUser();

      expect(UserManager.instance.userType, UserTypeEnum.normal.label);
    });

    test('logoutUser is idempotent — calling twice has same result', () {
      AnalyticsSdk.setUserIdAndType(
        userId: 'user123',
        userTypeEnum: UserTypeEnum.vip,
      );

      AnalyticsSdk.logoutUser();
      AnalyticsSdk.logoutUser();

      expect(UserManager.instance.userType, UserTypeEnum.normal.label);
    });
  });
}
