import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

// ──────────────────────────────────────────
// 数据模型（UI 骨架）
// ──────────────────────────────────────────
class _BlockedUser {
  final String id;
  final String name;
  final String avatarUrl;
  final String followersDisplay;

  const _BlockedUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.followersDisplay,
  });
}

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class BlocklistPage extends StatefulWidget {
  const BlocklistPage({super.key});

  @override
  State<BlocklistPage> createState() => _BlocklistPageState();
}

class _BlocklistPageState extends State<BlocklistPage> {
  final _users = <_BlockedUser>[
    const _BlockedUser(
        id: '1',
        name: 'Sarah Jenks',
        avatarUrl: '',
        followersDisplay: '5.4w粉丝'),
    const _BlockedUser(
        id: '2',
        name: 'Sarah Jenks',
        avatarUrl: '',
        followersDisplay: '5.4w粉丝'),
    const _BlockedUser(
        id: '3',
        name: 'Sarah Jenks',
        avatarUrl: '',
        followersDisplay: '5.4w粉丝'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: _users.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.w),
              itemCount: _users.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                color: const Color(0xFFEDF0F5),
              ),
              itemBuilder: (_, i) => _UserTile(
                user: _users[i],
                onUnblock: () => _unblock(_users[i].id),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20.w,
          color: const Color(0xFF1D293D),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'blocklistTitle'.tr(),
        style: TextStyle(
          color: const Color(0xFF1D293D),
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEDF0F5)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'messageEmpty'.tr(),
        style: TextStyle(color: const Color(0xFF8C95A4), fontSize: 14.sp),
      ),
    );
  }

  void _unblock(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('blocklistUnblock'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('commonCancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _users.removeWhere((u) => u.id == id));
            },
            child: Text('commonConfirm'.tr()),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// 用户列表项
// ──────────────────────────────────────────
class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onUnblock});

  final _BlockedUser user;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
      child: Row(
        children: [
          // 头像
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF4),
              borderRadius: BorderRadius.circular(22.w),
            ),
            clipBehavior: Clip.antiAlias,
            child: user.avatarUrl.isNotEmpty
                ? MyImage.network(user.avatarUrl, fit: BoxFit.cover)
                : const SizedBox.shrink(),
          ),
          SizedBox(width: 12.w),
          // 名字 + 粉丝
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    color: const Color(0xFF0F172B),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.w),
                Text(
                  user.followersDisplay,
                  style: TextStyle(
                    color: const Color(0xFF62748E),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          // 解除拉黑按钮
          GestureDetector(
            onTap: onUnblock,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.w),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD0D5DD)),
                borderRadius: BorderRadius.circular(20.w),
              ),
              child: Text(
                'blocklistUnblock'.tr(),
                style: TextStyle(
                  color: const Color(0xFF62748E),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
