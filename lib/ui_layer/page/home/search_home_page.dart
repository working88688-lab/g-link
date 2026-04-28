import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/domains/search.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/domain/model/search_models.dart';
import 'package:g_link/ui_layer/event/event_bus.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:g_link/utils/my_toast.dart';
import 'package:provider/provider.dart';

class SearchHomePage extends StatefulWidget {
  const SearchHomePage({super.key});

  @override
  State<SearchHomePage> createState() => _SearchHomePageState();
}

class _SearchHomePageState extends State<SearchHomePage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _loading = true;
  List<String> _history = const [];
  List<SearchHotItem> _hot = const [];
  List<RecommendedUser> _users = const [];
  final Map<int, bool> _followOverride = <int, bool>{};
  final Set<int> _followInflight = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final searchDomain = context.read<SearchDomain>();

    try {
      final home = await searchDomain.getSearchHome();
      if (!mounted) return;
      final users = home.recommendUsers.take(3).toList();
      for (final u in users) {
        _followOverride[u.uid] = u.isFollowing;
      }
      setState(() {
        _history = home.history;
        _hot = home.hot;
        _users = users;
      });
    } catch (_) {
      if (mounted) {
        MyToast.showText(text: 'commonRetry'.tr());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isFollowing(RecommendedUser user) =>
      _followOverride[user.uid] ?? user.isFollowing;

  Future<void> _toggleFollow(RecommendedUser user) async {
    if (_followInflight.contains(user.uid)) return;

    final before = _isFollowing(user);
    _followInflight.add(user.uid);
    setState(() {
      _followOverride[user.uid] = !before;
    });

    final profileDomain = context.read<ProfileDomain>();
    final result = before
        ? await profileDomain.unfollowUser(uid: user.uid)
        : await profileDomain.followUser(uid: user.uid);

    _followInflight.remove(user.uid);
    if (!mounted) return;

    if (result.status != 0 || result.data == null) {
      setState(() {
        _followOverride[user.uid] = before;
      });
      MyToast.showText(text: result.msg ?? 'commonRetry'.tr());
      return;
    }

    setState(() {
      _followOverride[user.uid] = result.data!.isFollowing;
    });

    eventBus.fire(
      FollowStatusChangedEvent(
        uid: user.uid,
        isFollowing: result.data!.isFollowing,
      ),
    );
  }

  Future<void> _refreshRecommendUsers() async {
    await _load();
  }

  Future<void> _clearHistory() async {
    setState(() {
      _history = const [];
    });
  }

  void _removeHistoryAt(int index) {
    if (index < 0 || index >= _history.length) return;
    setState(() {
      final list = List<String>.from(_history);
      list.removeAt(index);
      _history = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    SizedBox(height: 18.h),
                    _buildHistory(),
                    SizedBox(height: 16.h),
                    _buildHotSearch(),
                    SizedBox(height: 18.h),
                    _buildRecommendUsers(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1F6),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: const Color(0xFF8190A8), size: 22.sp),
                SizedBox(width: 6.w),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'commonSearchHint'.tr(),
                      hintStyle: TextStyle(
                        color: const Color(0xFF9DA8BC),
                        fontSize: 14.sp,
                      ),
                    ),
                    style: TextStyle(
                      color: const Color(0xFF1A1F2C),
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'commonCancel'.tr(),
            style: TextStyle(
              color: const Color(0xFF5C667B),
              fontSize: 16.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'searchHistoryTitle'.tr(),
              style: TextStyle(
                fontSize: 30 / 2,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1F2C),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _clearHistory,
              child: Text(
                'searchHistoryClear'.tr(),
                style: TextStyle(
                  color: const Color(0xFF93A0B8),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _history.asMap().entries
              .map((entry) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF1F6),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.value,
                          style: TextStyle(
                            color: const Color(0xFF222B3C),
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        GestureDetector(
                          onTap: () => _removeHistoryAt(entry.key),
                          child: Icon(Icons.close,
                              size: 13.sp, color: const Color(0xFF8C95A8)),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildHotSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'searchHotTitle'.tr(),
          style: TextStyle(
            fontSize: 30 / 2,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1F2C),
          ),
        ),
        SizedBox(height: 10.h),
        ..._hot.take(8).map((item) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  _rankBadge(item.rank),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      item.keyword,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF1B2436),
                        fontSize: 29 / 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    CommonUtils.renderEnFixedNumber(item.score).toString(),
                    style: TextStyle(
                      color: const Color(0xFF8FA0B8),
                      fontSize: 30 / 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _rankBadge(int rank) {
    final color = switch (rank) {
      1 => const Color(0xFFF14A45),
      2 => const Color(0xFFF58A3A),
      3 => const Color(0xFFF2B228),
      _ => const Color(0xFFD4DBE7),
    };

    return Container(
      width: 20.w,
      height: 20.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRecommendUsers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'homeRecommendFollow'.tr(),
              style: TextStyle(
                fontSize: 30 / 2,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1F2C),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _refreshRecommendUsers,
              child: Row(
                children: [
                  Icon(Icons.refresh,
                      size: 16.sp, color: const Color(0xFF5C6D87)),
                  SizedBox(width: 4.w),
                  Text(
                    'homeRefreshRecommend'.tr(),
                    style: TextStyle(
                      color: const Color(0xFF5C6D87),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ..._users.map((user) {
          final following = _isFollowing(user);
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE4E7EE),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: user.avatarUrl.isNotEmpty
                      ? MyImage.network(user.avatarUrl, fit: BoxFit.cover)
                      : MyImage.asset(MyImagePaths.defaultHeader,
                          fit: BoxFit.cover),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname.isNotEmpty ? user.nickname : user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF1A1F2C),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${CommonUtils.renderEnFixedNumber(user.followerCount)}粉丝',
                        style: TextStyle(
                          color: const Color(0xFF8D96A8),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleFollow(user),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 68.w,
                    height: 30.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: following
                          ? const Color(0xFFF5F6F8)
                          : const Color(0xFF1A1F2C),
                      border: following
                          ? Border.all(color: const Color(0xFFD3D7E0), width: 1)
                          : null,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      following ? 'commonFollowed'.tr() : 'commonFollow'.tr(),
                      style: TextStyle(
                        color: following ? const Color(0xFF5F6778) : Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
