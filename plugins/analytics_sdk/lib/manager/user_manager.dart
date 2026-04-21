import 'package:analytics_sdk/enum/user_type_enum.dart';

/// 全局用户管理器
/// 负责管理用户类型信息，支持用户类型更新和登出操作
class UserManager {
  static final UserManager instance = UserManager._internal();

  factory UserManager() => instance;

  UserManager._internal();

  /// 当前用户类型：normal、vip  等
  String _userType = UserTypeEnum.normal.label;

  String get userType => _userType;

  /// 更新用户类型（登录、升级会员、切换账号时调用）
  void updateUserType(String newType) {
    if (_userType != newType) {
      _userType = newType;
    }
  }

  /// 登出
  void logout() {
    _userType = UserTypeEnum.normal.label; // 或 'guest'，根据业务决定
  }
}
