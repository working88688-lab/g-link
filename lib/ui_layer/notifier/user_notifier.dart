import 'package:analytics_sdk/analytics_sdk.dart';
import 'package:analytics_sdk/enum/user_type_enum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:g_link/app_global.dart';
import 'package:g_link/domain/model/member_model.dart';
import 'package:g_link/domain/model/system_notice_model.dart';
import 'package:g_link/domain/remote_domain.dart';
import 'package:g_link/utils/my_toast.dart';
import '../../domain/type_def.dart';
import '../../domain/enum.dart';

class UserNotifier extends ChangeNotifier {
  UserNotifier(this._remoteDomain) {
    _remoteDomain.tokenStatusStream.listen(_tokenStatusListener);
  }

  final RemoteDomain _remoteDomain;

  bool get isInit => _isInit;
  bool _isInit = false;

  Member get member => _member;
  late Member _member;

  SystemNotice? _systemNotice;

  SystemNotice? get systemNotice => _systemNotice;

  MyTokenStatus? get tokenStatus => _tokenStatus;
  MyTokenStatus? _tokenStatus;

  void _tokenStatusListener(MyTokenStatus? status) async {
    if (_tokenStatus != status) {
      _tokenStatus = status;
      notifyListeners();
    }
  }

  Set<String> get userFollowingStatus => {..._userFollowingStatus};
  final Set<String> _userFollowingStatus = {};
  final Set<String> _isLoadingFollowUser = {};

  void patchUserFollowStatus(Iterable<String> ids) {
    _userFollowingStatus.addAll(ids);
    notifyListeners();
  }

  Future changeUserFollow(String id) async {
  //   if (_isLoadingFollowUser.contains(id)) return;
  //   _isLoadingFollowUser.add(id);
  //
  //   final res = await _remoteDomain.communityFollowUser(aff: id);
  //   if (res.isValid) {
  //     if (!_userFollowingStatus.remove(id)) {
  //       _userFollowingStatus.add(id);
  //     }
  //   } else {
  //     MyToast.showText(text: res.msg ?? '');
  //   }
  //
  //   _isLoadingFollowUser.remove(id);
  //   notifyListeners();
  // }
  //
  // Future<bool> init() async {
  //   final result = await _remoteDomain.getUserInfo();
  //   AppGlobal.aff = result.data?.aff ?? 0;
  //
  //   initSystemNotice();
  //
  //   AnalyticsSdk.setUid(result.data?.aff?.toString() ?? '');
  //   AnalyticsSdk.setChannel(
  //     (result.data?.channel == 'self' ? '' : result.data?.channel) ?? '',
  //   );
  //   AnalyticsSdk.setUserIdAndType(
  //     userId: (AppGlobal.aff > 0) ? AppGlobal.aff.toString() : '',
  //     userTypeEnum: ((result.data?.vipLevel ?? 0) > 0)
  //         ? UserTypeEnum.vip
  //         : UserTypeEnum.normal,
  //   );
  //
  //   if (result.data case final data?) {
  //     _member = data;
  //     _isInit = true;
  //     notifyListeners();
  //     return true;
  //   }
  //   return false;
  }

  Future initSystemNotice() async {
    // final res = await _remoteDomain.getSystemNotice();
    //
    // if (res.data case final data?) {
    //   _systemNotice = data;
    //   notifyListeners();
    // }
  }

  void readSystemNotice() {
    _systemNotice = _systemNotice?.copyWith(systemNoticeCount: 0);
    notifyListeners();
  }

  void readCustomerService() {
    _systemNotice = _systemNotice?.copyWith(feedCount: 0);
    notifyListeners();
  }

  /// 更新用户馀额
  void setMoney({required int money}) {
    _member = _member.copyWith(money: money);
    notifyListeners();
  }

  void setExp(int? newExp) {
    _member = _member.copyWith(exp: newExp);
    notifyListeners();
  }

  void setThumb({required String thumb}) {
    _member = _member.copyWith(thumb: thumb);
    notifyListeners();
  }

  void setNickName({required String nickName}) {
    _member = _member.copyWith(nickname: nickName);
    notifyListeners();
  }

  void setInviteBy({required dynamic inviteBy}) {
    _member = _member.copyWith(invitedBy: inviteBy);
    notifyListeners();
  }

  void setBindEmail({required dynamic inviteBy}) {
    _member = _member.copyWith(bindEmail: 1);
    notifyListeners();
  }

  void setDownNum({required int num}) {
    _member = _member.copyWith(videoDownloadValue: num);
    notifyListeners();
  }

  void setCartoonDownNum({required int num}) {
    _member = _member.copyWith(cartoonDownValue: num);
    notifyListeners();
  }

  void setStripValue({required int num}) {
    _member = _member.copyWith(stripValue: num);
    notifyListeners();
  }

  void setImgFaceValue({required int num}) {
    _member = _member.copyWith(imgFaceValue: num);
    notifyListeners();
  }

  void setAiNovelValue({required int num}) {
    _member = _member.copyWith(aiNovelValue: num);
    notifyListeners();
  }

  void setAiKissValue({required int num}) {
    _member = _member.copyWith(aiKissValue: num);
    notifyListeners();
  }

  void setAiAudioValue({required int num}) {
    _member = _member.copyWith(aiAudioValue: num);
    notifyListeners();
  }

  void setAiVideoFaceValue({required int num}) {
    _member = _member.copyWith(aiVideoFaceValue: num);
    notifyListeners();
  }

  void setIMValue({required int imValue}) {
    _member = _member.copyWith(imValue: imValue);
    notifyListeners();
  }

  void setMagicValue({required int num}) {
    _member = _member.copyWith(aiMagicValue: num);
    notifyListeners();
  }

  void setDrawValue({required int num}) {
    _member = _member.copyWith(aiDrawValue: num);
    notifyListeners();
  }

  Future logout() async {
    // _userFollowingStatus.clear();
    // await _remoteDomain.logout();
    // AnalyticsSdk.logoutUser();
    // await init();
  }
}
