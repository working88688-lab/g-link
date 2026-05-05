import 'dart:async';

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
    _tokenStatusSubscription =
        _remoteDomain.tokenStatusStream.listen(_tokenStatusListener);
  }

  final RemoteDomain _remoteDomain;
  late final StreamSubscription<MyTokenStatus?> _tokenStatusSubscription;
  bool _disposed = false;

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
      _safeNotify();
    }
  }

  Set<String> get userFollowingStatus => {..._userFollowingStatus};
  final Set<String> _userFollowingStatus = {};
  final Set<String> _isLoadingFollowUser = {};

  void patchUserFollowStatus(Iterable<String> ids) {
    _userFollowingStatus.addAll(ids);
    _safeNotify();
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
    _safeNotify();
  }

  void readCustomerService() {
    _systemNotice = _systemNotice?.copyWith(feedCount: 0);
    _safeNotify();
  }

  /// 更新用户馀额
  void setMoney({required int money}) {
    _member = _member.copyWith(money: money);
    _safeNotify();
  }

  void setExp(int? newExp) {
    _member = _member.copyWith(exp: newExp);
    _safeNotify();
  }

  void setThumb({required String thumb}) {
    _member = _member.copyWith(thumb: thumb);
    _safeNotify();
  }

  void setNickName({required String nickName}) {
    _member = _member.copyWith(nickname: nickName);
    _safeNotify();
  }

  void setInviteBy({required dynamic inviteBy}) {
    _member = _member.copyWith(invitedBy: inviteBy);
    _safeNotify();
  }

  void setBindEmail({required dynamic inviteBy}) {
    _member = _member.copyWith(bindEmail: 1);
    _safeNotify();
  }

  void setDownNum({required int num}) {
    _member = _member.copyWith(videoDownloadValue: num);
    _safeNotify();
  }

  void setCartoonDownNum({required int num}) {
    _member = _member.copyWith(cartoonDownValue: num);
    _safeNotify();
  }

  void setStripValue({required int num}) {
    _member = _member.copyWith(stripValue: num);
    _safeNotify();
  }

  void setImgFaceValue({required int num}) {
    _member = _member.copyWith(imgFaceValue: num);
    _safeNotify();
  }

  void setAiNovelValue({required int num}) {
    _member = _member.copyWith(aiNovelValue: num);
    _safeNotify();
  }

  void setAiKissValue({required int num}) {
    _member = _member.copyWith(aiKissValue: num);
    _safeNotify();
  }

  void setAiAudioValue({required int num}) {
    _member = _member.copyWith(aiAudioValue: num);
    _safeNotify();
  }

  void setAiVideoFaceValue({required int num}) {
    _member = _member.copyWith(aiVideoFaceValue: num);
    _safeNotify();
  }

  void setIMValue({required int imValue}) {
    _member = _member.copyWith(imValue: imValue);
    _safeNotify();
  }

  void setMagicValue({required int num}) {
    _member = _member.copyWith(aiMagicValue: num);
    _safeNotify();
  }

  void setDrawValue({required int num}) {
    _member = _member.copyWith(aiDrawValue: num);
    _safeNotify();
  }

  Future logout() async {
    // _userFollowingStatus.clear();
    // await _remoteDomain.logout();
    // await init();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _tokenStatusSubscription.cancel();
    super.dispose();
  }
}
