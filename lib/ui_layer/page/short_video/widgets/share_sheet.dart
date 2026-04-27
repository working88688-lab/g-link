import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

// 好友数据模型（后续对接真实接口时替换）
class _Friend {
  final String name;
  final String avatar; // 网络图片 URL，空则显示占位
  const _Friend({required this.name, this.avatar = ''});
}

final _mockFriends = [
  const _Friend(name: 'Alice'),
  const _Friend(name: 'Bob'),
  const _Friend(name: 'Carol'),
  const _Friend(name: 'Dave'),
  const _Friend(name: 'Eve'),
  const _Friend(name: 'Frank'),
];

// 第三方分享选项
class _ShareOption {
  final String iconPath;
  final String labelKey;

  const _ShareOption({required this.iconPath, required this.labelKey});
}

const _shareOptions = [
  _ShareOption(iconPath: MyImagePaths.iconShareAlbum, labelKey: 'shortVideoShareAlbum'),
  _ShareOption(iconPath: MyImagePaths.iconShareLink, labelKey: 'shortVideoShareLink'),
  _ShareOption(iconPath: MyImagePaths.iconShareFacebook, labelKey: 'shortVideoShareFacebook'),
  _ShareOption(iconPath: MyImagePaths.iconShareX, labelKey: 'shortVideoShareX'),
  _ShareOption(iconPath: MyImagePaths.iconShareReddit, labelKey: 'shortVideoShareReddit'),
  _ShareOption(iconPath: MyImagePaths.iconShareWhatsapp, labelKey: 'shortVideoShareWhatsapp'),
];

class ShareSheet extends StatelessWidget {
  const ShareSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 标题 ───────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'shortVideoShareTitle'.tr(),
              style: TextStyle(
                color: const Color(0xFF1A1F2C),
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 16.w),
          // ── 好友列表（最多5个 + 更多） ───────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
              childAspectRatio: 48 / 64,
            ),
            itemCount: (_mockFriends.length > 5 ? 5 : _mockFriends.length) + 1,
            itemBuilder: (_, i) {
              if (i < (_mockFriends.length > 5 ? 5 : _mockFriends.length)) {
                return _FriendItem(friend: _mockFriends[i]);
              }
              return _MoreItem();
            },
          ),
          SizedBox(height: 24.w),
          // ── 第三方分享 ─────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 0,
              mainAxisSpacing: 10.w,
              childAspectRatio: 48 / 55,
            ),
            itemCount: _shareOptions.length,
            itemBuilder: (_, i) => _ShareOptionItem(option: _shareOptions[i]),
          ),
          SizedBox(height: 8.w),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 48.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Color(0xFFE3E7ED), width: 1)),
              clipBehavior: Clip.antiAlias,
              child: Align(
                child: MyImage.asset(MyImagePaths.iconShareMore, width: 24.w, height: 24.w),
              ),
            ),
            SizedBox(height: 6.w),
            Text(
              'shortVideoShareMore'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF0F0F0F),
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendItem extends StatelessWidget {
  final _Friend friend;

  const _FriendItem({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 48.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头像
            Container(
              width: 48.w,
              height: 48.w,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: friend.avatar.isNotEmpty
                  ? Image.network(friend.avatar, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFE3E7ED),
                      alignment: Alignment.center,
                      child: Icon(Icons.person, color: const Color(0xFF90A1B9), size: 24.sp),
                    ),
            ),
            SizedBox(height: 6.w),
            // 名称
            Text(
              friend.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF0F0F0F),
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionItem extends StatelessWidget {
  final _ShareOption option;

  const _ShareOptionItem({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE3E7ED), width: 1.w),
              borderRadius: BorderRadius.circular(48.w),
            ),
            alignment: Alignment.center,
            child: Align(
              child: MyImage.asset(option.iconPath, width: 24.w, height: 24.w),
            ),
          ),
          Spacer(),
          Text(
            option.labelKey.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF0F0F0F),
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}
