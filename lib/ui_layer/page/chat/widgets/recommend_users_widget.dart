import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/utils/common_utils.dart';
import 'package:provider/provider.dart';

// ──────────────────────────────────────────
// 为你推荐用户列表
// ──────────────────────────────────────────

class RecommendUsersWidget extends StatefulWidget {
  final Function? onClose;

  const RecommendUsersWidget({super.key, this.onClose});

  @override
  State<RecommendUsersWidget> createState() => _RecommendUsersWidgetState();
}

class _RecommendUsersWidgetState extends State<RecommendUsersWidget> {
  bool _closed = false;
  List<RecommendedUser> _users = [];

  // uid -> 本地关注状态覆盖
  final Map<int, bool> _followingOverride = {};

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final result = await context.read<ProfileDomain>().getRecommendedUsers(limit: 20);
    if (!mounted) return;
    setState(() {
      if (result.status == 0 && result.data != null) {
        _users = result.data!;
      }
    });
  }

  bool _isFollowing(RecommendedUser user) => _followingOverride[user.uid] ?? user.isFollowing;

  void _toggleFollow(RecommendedUser user) {
    setState(() {
      _followingOverride[user.uid] = !_isFollowing(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_closed || _users.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '为你推荐',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1F2C),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                widget.onClose?.call();
                setState(() => _closed = true);
              },
              child: Text(
                '关闭',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF62748E),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15.w),
        for (final user in _users)
          Container(
            margin: EdgeInsets.only(bottom: 20.w),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40.r),
                    color: const Color(0xFFD1D1D6),
                  ),
                  child: user.avatarUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(40.r),
                          child: Image.network(
                            user.avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person, size: 28.sp, color: Colors.white),
                          ),
                        )
                      : Icon(Icons.person, size: 28.sp, color: Colors.white),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.nickname.isNotEmpty ? user.nickname : user.username,
                        style: TextStyle(
                          color: const Color(0xFF0F172B),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${CommonUtils.renderEnFixedNumber(user.followerCount)}粉丝',
                        style: TextStyle(
                          color: const Color(0xFF62748E),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleFollow(user),
                  child: Container(
                    height: 33.5.w,
                    width: 60.w,
                    decoration: BoxDecoration(
                      color: _isFollowing(user) ? const Color(0xFF1A1F2C) : null,
                      border: _isFollowing(user) ? null : Border.all(color: const Color(0xFFCCCCCC), width: 1.w),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isFollowing(user) ? '已关注' : '关注',
                      style: TextStyle(
                        color: _isFollowing(user) ? const Color(0xFFF8F9FE) : const Color(0xFF1A1F2C),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
