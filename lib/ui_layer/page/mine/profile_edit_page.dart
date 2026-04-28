import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/notifier/edit_profile_notifier.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:g_link/utils/my_toast.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.nickname,
    required this.username,
    required this.bio,
    required this.location,
    required this.avatarUrl,
    required this.coverUrl,
  });

  final String nickname;
  final String username;
  final String bio;
  final String location;
  final String avatarUrl;
  final String coverUrl;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _locationCtrl;
  String _avatarUrl = '';
  String _coverUrl = '';
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.nickname);
    _usernameCtrl = TextEditingController(text: widget.username);
    _bioCtrl = TextEditingController(text: widget.bio);
    _locationCtrl = TextEditingController(text: widget.location);
    _avatarUrl = widget.avatarUrl;
    _coverUrl = widget.coverUrl;
    if (widget.location.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoFillLocation();
      });
    }
  }

  /// [manual]：true 表示用户主动点定位图标，需要弹 toast 反馈成功/失败原因，
  /// 并允许覆盖已有内容；false 表示进入页面时的静默自动回填，地址非空就跳过。
  ///
  /// 关键节点都打日志（tag=`edit-profile-loc`），失败时即便是自动模式也会
  /// 把权限/服务两类用户能修的问题用 toast 提示出来，避免"看似什么都没发生"。
  Future<void> _autoFillLocation({bool manual = false}) async {
    if (_locating) return;
    developer.log(
      '[edit-profile-loc] start manual=$manual current="${_locationCtrl.text}"',
      name: 'edit-profile-loc',
    );
    if (mounted) setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      developer.log(
        '[edit-profile-loc] serviceEnabled=$serviceEnabled',
        name: 'edit-profile-loc',
      );
      if (!serviceEnabled) {
        // 系统定位关掉了——无论自动还是手动都得告诉用户，否则只会觉得"没反应"。
        MyToast.showText(text: '请先开启系统定位服务');
        return;
      }
      var permission = await Geolocator.checkPermission();
      developer.log(
        '[edit-profile-loc] checkPermission=$permission',
        name: 'edit-profile-loc',
      );
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        developer.log(
          '[edit-profile-loc] requestPermission=$permission',
          name: 'edit-profile-loc',
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // 没权限同上，自动模式也提示，否则用户看不出是被系统拦了。
        MyToast.showText(text: '没有定位权限，请在系统设置中开启后重试');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      developer.log(
        '[edit-profile-loc] position=(${position.latitude}, ${position.longitude})',
        name: 'edit-profile-loc',
      );
      final addr = await _reverseGeocode(position.latitude, position.longitude);
      if (!mounted) return;
      if (addr == null) {
        if (manual) MyToast.showText(text: '未能解析到所在地，请稍后重试');
        return;
      }
      final composed = [
        if (addr.country.isNotEmpty) addr.country,
        if (addr.city.isNotEmpty) addr.city,
      ].join('·');
      developer.log(
        '[edit-profile-loc] composed="$composed" '
        '(country="${addr.country}", city="${addr.city}", source=${addr.source})',
        name: 'edit-profile-loc',
      );
      if (composed.isEmpty) {
        if (manual) MyToast.showText(text: '未能解析到所在地，请稍后重试');
        return;
      }
      // 自动模式只回填空字段；手动点击允许覆盖已有内容。
      if (!manual && _locationCtrl.text.trim().isNotEmpty) {
        developer.log(
          '[edit-profile-loc] skip fill: field already non-empty',
          name: 'edit-profile-loc',
        );
        return;
      }
      _locationCtrl.text = composed;
      developer.log(
        '[edit-profile-loc] filled: "$composed"',
        name: 'edit-profile-loc',
      );
    } on TimeoutException catch (e) {
      developer.log(
        '[edit-profile-loc] timeout: $e',
        name: 'edit-profile-loc',
      );
      if (manual) MyToast.showText(text: '定位超时，请检查网络或重试');
    } catch (e, stack) {
      developer.log(
        '[edit-profile-loc] failed: $e',
        name: 'edit-profile-loc',
        error: e,
        stackTrace: stack,
      );
      if (manual) MyToast.showText(text: '定位失败：${e.toString()}');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String _currentLocaleId() {
    Locale locale;
    try {
      locale = Localizations.localeOf(context);
    } catch (_) {
      locale = WidgetsBinding.instance.platformDispatcher.locale;
    }
    final lang = locale.languageCode;
    final country = locale.countryCode;
    if (country != null && country.isNotEmpty) {
      return '${lang}_$country';
    }
    return lang;
  }

  String _pickCity(gc.Placemark p) {
    // 不同国家/平台对 Placemark 字段语义差异较大：
    // - 美/英/日/韩/欧洲等：locality 即“城市”（New York / London / Tokyo），
    //   subAdministrativeArea 是 county/郡，不应作为城市；
    // - 中国大陆：locality 经常是“区/县”（天河区），
    //   subAdministrativeArea 才是“地级市”（广州市）。
    // 因此用 isoCountryCode 作为分支信号选择回退顺序。
    final iso = (p.isoCountryCode ?? '').toUpperCase();
    final locality = (p.locality ?? '').trim();
    final subAdmin = (p.subAdministrativeArea ?? '').trim();
    final admin = (p.administrativeArea ?? '').trim();

    final candidates = (iso == 'CN')
        ? <String>[subAdmin, locality, admin]
        : <String>[locality, subAdmin, admin];

    bool looksLikeSubCity(String v) {
      if (v.isEmpty) return false;
      if (iso == 'CN') {
        const districtSuffixes = ['区', '县', '旗', '镇', '乡', '街道'];
        return districtSuffixes.any(v.endsWith);
      }
      // 仅在国际场景中过滤明显的“非城市”字段，避免把 county/省 当成城市。
      final lower = v.toLowerCase();
      return lower.endsWith(' county') ||
          lower.endsWith(' province') ||
          lower.endsWith(' state');
    }

    for (final c in candidates) {
      if (c.isEmpty) continue;
      if (looksLikeSubCity(c)) continue;
      return c;
    }
    return candidates.firstWhere((c) => c.isNotEmpty, orElse: () => '');
  }

  /// 逆地理：先尝试系统 geocoder，失败 / 拿不到 country+city 就走 Nominatim
  /// 兜底。Android 系统的 geocoder 内部走 Google geocoding API，国行 / HMS /
  /// 境内网络下大概率 IO_ERROR；Nominatim 是 OpenStreetMap 的免费服务，
  /// 全球可用，对国际化场景必备。
  Future<_AddressResult?> _reverseGeocode(double lat, double lon) async {
    final localeId = _currentLocaleId();
    try {
      await gc.setLocaleIdentifier(localeId);
    } catch (e) {
      developer.log(
        '[edit-profile-loc] setLocaleIdentifier($localeId) failed: $e',
        name: 'edit-profile-loc',
      );
    }
    try {
      final placemarks = await gc.placemarkFromCoordinates(lat, lon);
      developer.log(
        '[edit-profile-loc] platform geocoder placemarks.length='
        '${placemarks.length}',
        name: 'edit-profile-loc',
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final country = (p.country ?? '').trim();
        final city = _pickCity(p);
        if (country.isNotEmpty || city.isNotEmpty) {
          return _AddressResult(
            country: country,
            city: city,
            source: 'platform',
          );
        }
      }
    } catch (e) {
      developer.log(
        '[edit-profile-loc] platform geocoder failed, falling back to '
        'nominatim: $e',
        name: 'edit-profile-loc',
      );
    }
    return _reverseGeocodeViaNominatim(lat, lon, localeId);
  }

  /// OpenStreetMap Nominatim 反查；遵守其使用条款必须设 User-Agent。
  /// `accept-language` 让结果跟着 app 当前语言走，国际化场景下保持一致。
  Future<_AddressResult?> _reverseGeocodeViaNominatim(
    double lat,
    double lon,
    String localeId,
  ) async {
    final acceptLanguage = localeId.replaceAll('_', '-');
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'format': 'json',
      'zoom': '10',
      'addressdetails': '1',
      'accept-language': acceptLanguage,
    });
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(uri);
      // Nominatim 的 Usage Policy 强制要求设 User-Agent，否则 403。
      req.headers.set('User-Agent', 'g_link/1.0 (profile-edit)');
      req.headers.set('Accept-Language', acceptLanguage);
      final resp = await req.close().timeout(const Duration(seconds: 12));
      if (resp.statusCode != HttpStatus.ok) {
        developer.log(
          '[edit-profile-loc] nominatim http ${resp.statusCode}',
          name: 'edit-profile-loc',
        );
        await resp.drain<void>();
        return null;
      }
      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      if (json is! Map) return null;
      final address = (json['address'] ?? const <String, dynamic>{});
      if (address is! Map) return null;
      final country = '${address['country'] ?? ''}'.trim();
      final iso = '${address['country_code'] ?? ''}'.toUpperCase();
      final city = _pickNominatimCity(Map<String, dynamic>.from(address), iso);
      developer.log(
        '[edit-profile-loc] nominatim country="$country" city="$city" iso=$iso',
        name: 'edit-profile-loc',
      );
      if (country.isEmpty && city.isEmpty) return null;
      return _AddressResult(
        country: country,
        city: city,
        source: 'nominatim',
      );
    } catch (e, stack) {
      developer.log(
        '[edit-profile-loc] nominatim failed: $e',
        name: 'edit-profile-loc',
        error: e,
        stackTrace: stack,
      );
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// 从 Nominatim 的 address 字段里挑"城市"。各国行政区划差异大，
  /// 选取顺序参考 Nominatim 文档对 zoom=10 时的字段优先级，并按地区微调。
  String _pickNominatimCity(Map<String, dynamic> address, String iso) {
    List<String> keys;
    if (iso == 'CN') {
      // 中国：city/town/municipality/province
      keys = ['city', 'town', 'municipality', 'state'];
    } else {
      // 其他地区按通用人口聚集度优先：city > town > municipality > village > county > state
      keys = [
        'city',
        'town',
        'municipality',
        'village',
        'county',
        'state',
      ];
    }
    for (final k in keys) {
      final v = '${address[k] ?? ''}'.trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CommonUtils.setStatusBar(isLight: true);
    return ChangeNotifierProvider(
      create: (ctx) => EditProfileNotifier(ctx.read<ProfileDomain>()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: Consumer<EditProfileNotifier>(
          builder: (context, notifier, _) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 110.w),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        _buildForm(context, notifier),
                      ],
                    ),
                  ),
                ),
                _buildSaveButton(context, notifier),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final notifier = context.read<EditProfileNotifier>();
    return SizedBox(
      height: 268.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 190.w,
            width: double.infinity,
            child: _coverUrl.isNotEmpty
                ? MyImage.network(_coverUrl, fit: BoxFit.cover)
                : MyImage.asset(MyImagePaths.userBackground, fit: BoxFit.cover),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.w,
            left: 12.w,
            child: _roundDarkButton(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 14.w,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.w,
            right: 12.w,
            child: _pillDarkButton(
              title: '更换封面',
              loading: context.select<EditProfileNotifier, bool>(
                (n) => n.uploadingCover,
              ),
              onTap: () => _onPickCover(notifier),
            ),
          ),
          Positioned(
            left: 12.w,
            bottom: 76.w / 2,
            child: GestureDetector(
              onTap: () => _onPickAvatar(notifier),
              child: Stack(
                children: [
                  Container(
                    width: 76.w,
                    height: 76.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEFF4),
                      borderRadius: BorderRadius.circular(38.w),
                      border: Border.all(color: Colors.white, width: 2.w),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _avatarUrl.isNotEmpty
                        ? MyImage.network(_avatarUrl, fit: BoxFit.cover)
                        : MyImage.asset(
                            MyImagePaths.defaultHeader,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    left: 2.w,
                    top: 2.w,
                    right: 2.w,
                    bottom: 2.w,
                    child: Container(
                      width: 72.w,
                      height: 72.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(35, 35, 35, 0.35),
                        borderRadius: BorderRadius.circular(36.w),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Selector<EditProfileNotifier, bool>(
                          selector: (_, notifier) => notifier.uploadingAvatar,
                          builder: (_, loading, __) {
                            return loading
                                ? SizedBox(
                                    width: 14.w,
                                    height: 14.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    '更换头像',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                          }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, EditProfileNotifier notifier) {
    return Container(
      color: const Color(0xFFF5F5F7),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        children: [
          _buildLabel('昵称(Name)'),
          _lineInput(
            controller: _nicknameCtrl,
            hintText: '请输入昵称',
            maxLength: 20,
          ),
          SizedBox(height: 16.w),
          Row(
            children: [
              Text(
                '用户名(Username)',
                style: TextStyle(
                  color: const Color(0xFF141A2A),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                '30天可编辑一次',
                style: TextStyle(
                  color: const Color(0xFF8E97A8),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.w),
          _lineInput(
            controller: _usernameCtrl,
            hintText: '请输入用户名',
            prefixText: '@ ',
            maxLength: 30,
          ),
          SizedBox(height: 18.w),
          _buildLabel('简介'),
          _bioInput(),
          SizedBox(height: 18.w),
          _buildLabel('地址'),
          _lineInput(
            controller: _locationCtrl,
            hintText: '请输入所在地',
            maxLength: 20,
            prefixIcon: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _locating ? null : () => _autoFillLocation(manual: true),
              child: Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: _locating
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: const Color(0xFF627189),
                        ),
                      )
                    : Icon(
                        Icons.location_on_rounded,
                        color: const Color(0xFF627189),
                        size: 18.w,
                      ),
              ),
            ),
          ),
          if (notifier.errorMessage != null) ...[
            SizedBox(height: 14.w),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                notifier.errorMessage!,
                style: TextStyle(
                  color: const Color(0xFFD94C4C),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.w),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: const Color(0xFF141A2A),
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _lineInput({
    required TextEditingController controller,
    required String hintText,
    String? prefixText,
    int? maxLength,
    Widget? prefixIcon,
  }) {
    return Container(
      padding: EdgeInsets.only(bottom: 10.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD8DEE9),
            width: 1.w,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        buildCounter: (_,
            {required currentLength, maxLength, required isFocused}) {
          return const SizedBox.shrink();
        },
        style: TextStyle(
          color: const Color(0xFF2A3343),
          fontSize: 18.sp,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: hintText,
          hintStyle: TextStyle(
            color: const Color(0xFF8A94A8),
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            color: const Color(0xFF2A3343),
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: prefixIcon,
          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  Widget _bioInput() {
    return Container(
      padding: EdgeInsets.only(bottom: 8.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD8DEE9),
            width: 1.w,
          ),
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _bioCtrl,
        builder: (_, value, __) {
          return Column(
            children: [
              TextField(
                controller: _bioCtrl,
                minLines: 3,
                maxLines: 3,
                maxLength: 100,
                buildCounter: (_,
                    {required currentLength, maxLength, required isFocused}) {
                  return const SizedBox.shrink();
                },
                style: TextStyle(
                  color: const Color(0xFF2A3343),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: '请输入个人简介',
                  hintStyle: TextStyle(
                    color: const Color(0xFF8A94A8),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${value.text.characters.length}/100',
                  style: TextStyle(
                    color: const Color(0xFF8E97A8),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, EditProfileNotifier notifier) {
    return Container(
      height: 54.w,
      width: ScreenUtil().screenWidth,
      margin: EdgeInsets.only(left: 20.w, right: 20.w, bottom: MediaQuery.of(context).padding.bottom + 12.w),
      child: ElevatedButton(
        onPressed: notifier.saving ? null : () => _onSave(context, notifier),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF121D33),
          disabledBackgroundColor: const Color(0xFF7E889A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.w),
          ),
          elevation: 0,
        ),
        child: notifier.saving
            ? SizedBox(
          width: 18.w,
          height: 18.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          '保存',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _roundDarkButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(9.w),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _pillDarkButton({
    required String title,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(6.w),
        ),
        child: loading
            ? SizedBox(
                width: 14.w,
                height: 14.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Colors.white,
                ),
              )
            : Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _onSave(
    BuildContext context,
    EditProfileNotifier notifier,
  ) async {
    final navigator = Navigator.of(context);
    final ok = await notifier.submit(
      nickname: _nicknameCtrl.text,
      username: _usernameCtrl.text,
      bio: _bioCtrl.text,
      location: _locationCtrl.text,
      avatarUrl: notifier.resolveAvatarSaveValue(_avatarUrl),
      coverUrl: notifier.resolveCoverSaveValue(_coverUrl),
    );
    if (!mounted) return;
    if (!ok) {
      // 校验/服务端错误已经写到 notifier.errorMessage，由表单底部红字展示；
      // 同时弹一条 toast 提醒，避免用户没注意到。
      final msg = notifier.errorMessage;
      if (msg != null && msg.isNotEmpty) {
        MyToast.showText(text: msg);
      }
      return;
    }
    MyToast.showText(text: '保存成功');
    navigator.pop(true);
  }

  Future<void> _onPickAvatar(EditProfileNotifier notifier) async {
    final xFile = await CommonUtils.pickImage();
    if (xFile == null || !mounted) return;
    final uploaded = await notifier.uploadAvatar(xFile);
    if (!mounted) return;
    if (uploaded == null || uploaded.downloadUrl.isEmpty) {
      MyToast.showText(text: notifier.errorMessage ?? '头像上传失败');
      return;
    }
    developer.log(
      '[edit-profile] avatar uploaded; old=$_avatarUrl new=${uploaded.downloadUrl}',
      name: 'edit-profile',
    );
    setState(() {
      _avatarUrl = uploaded.downloadUrl;
    });
  }

  Future<void> _onPickCover(EditProfileNotifier notifier) async {
    final xFile = await CommonUtils.pickImage();
    if (xFile == null || !mounted) return;
    final uploaded = await notifier.uploadCover(xFile);
    if (!mounted) return;
    if (uploaded == null || uploaded.downloadUrl.isEmpty) {
      MyToast.showText(text: notifier.errorMessage ?? '封面上传失败');
      return;
    }
    developer.log(
      '[edit-profile] cover uploaded; old=$_coverUrl new=${uploaded.downloadUrl}',
      name: 'edit-profile',
    );
    setState(() {
      _coverUrl = uploaded.downloadUrl;
    });
  }
}

class _AddressResult {
  const _AddressResult({
    required this.country,
    required this.city,
    required this.source,
  });
  final String country;
  final String city;
  final String source;
}
