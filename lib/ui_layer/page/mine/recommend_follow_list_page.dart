import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/event/event_bus.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:g_link/utils/my_toast.dart';
import 'package:provider/provider.dart';

class RecommendFollowListPage extends StatefulWidget {
  const RecommendFollowListPage({super.key, this.limit = 10});

  final int limit;

  @override
  State<RecommendFollowListPage> createState() => _RecommendFollowListPageState();
}

class _RecommendFollowListPageState extends State<RecommendFollowListPage> {
  bool _loading = true;
  List<RecommendedUser> _users = const [];
  final Map<int, bool> _followOverride = <int, bool>{};
  final Set<int> _followInflight = <int>{};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final result = await context
        .read<ProfileDomain>()
        .getRecommendedUsers(limit: widget.limit);
    if (!mounted) return;

    if (result.status == 0 && result.data != null) {
      final users = result.data!;
      for (final u in users) {
        _followOverride[u.uid] = u.isFollowing;
      }
      setState(() {
        _users = users;
      });
    } else {
      MyToast.showText(text: result.msg ?? 'commonRetry'.tr());
      setState(() {
        _users = const [];
      });
    }
    setState(() => _loading = false);
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

    final domain = context.read<ProfileDomain>();
    final result = before
        ? await domain.unfollowUser(uid: user.uid)
        : await domain.followUser(uid: user.uid);

    if (!mounted) return;
    _followInflight.remove(user.uid);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'homeRecommendFollow'.tr(),
          style: TextStyle(
            color: const Color(0xFF1A1F2C),
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.chevron_left_rounded,
              size: 24.sp, color: const Color(0xFF1A1F2C)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 18.h),
              itemCount: _users.length,
              separatorBuilder: (_, __) => SizedBox(height: 14.h),
              itemBuilder: (context, index) {
                final user = _users[index];
                final following = _isFollowing(user);
                return Row(
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
                            user.nickname.isNotEmpty
                                ? user.nickname
                                : user.username,
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
                            'commonFollowerCount'.tr(namedArgs: {
                              'count': CommonUtils.renderEnFixedNumber(
                                user.followerCount,
                              )
                            }),
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
                              ? Border.all(
                                  color: const Color(0xFFD3D7E0), width: 1)
                              : null,
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Text(
                          following ? 'commonFollowed'.tr() : 'commonFollow'.tr(),
                          style: TextStyle(
                            color: following
                                ? const Color(0xFF5F6778)
                                : Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
