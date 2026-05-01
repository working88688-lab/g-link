import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/router/routes.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _tabIndex = 0;

  static const _tabs = ['系统通知', '互动通知', '新增粉丝'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _buildTabContent(key: ValueKey(_tabIndex)),
            ),
          ),
        ],
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
        '通知',
        style: TextStyle(
          color: const Color(0xFF1D293D),
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () {},
          child: Text(
            '全部已读',
            style: TextStyle(
              color: const Color(0xFF3156A5),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 6.w),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEDF0F5)),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.w, 16.w, 10.w),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final selected = index == _tabIndex;
          return Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = index),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.w),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1D2433) : const Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF38475B),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      right: -2.w,
                      top: -4.w,
                      child: Container(
                        width: 16.w,
                        height: 16.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B6A),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '9',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent({Key? key}) {
    switch (_tabIndex) {
      case 0:
        return _SystemNotificationList(key: key);
      case 1:
        return _InteractionNotificationList(key: key);
      case 2:
        return _FanNotificationList(key: key);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SystemNotificationList extends StatelessWidget {
  const _SystemNotificationList({super.key});

  static const _items = [
    _SystemNotificationItem(
      iconColor: Color(0xFFFFD88D),
      icon: Icons.volume_up_rounded,
      title: '版本公告',
      desc: 'V2.0 版本更新啦！全新界面，更流畅的体验。我们新增了多种视频特效，快来试试... ',
      time: '10分钟前',
      unread: true,
    ),
    _SystemNotificationItem(
      iconColor: Color(0xFFB9F2D6),
      icon: Icons.notifications_active_rounded,
      title: '平台通知',
      desc: '您的账号在异地(北京)登录，如非本人操作，请立即修改密码并检查账号状态以保... ',
      time: '1小时前',
    ),
    _SystemNotificationItem(
      iconColor: Color(0xFFBFD0FF),
      icon: Icons.verified_user_rounded,
      title: '账号安全',
      desc: '这里是内容超出两行省略这里是内容超出两行省略这里是内容超出两行省略这里是内容超出两行... ',
      time: '1小时前',
    ),
    _SystemNotificationItem(
      iconColor: Color(0xFFD7F4B5),
      icon: Icons.emoji_events_rounded,
      title: '作品审核通知',
      desc: '这里是内容超出两行省略这里是内容超出两行省略这里是内容超出两行省略这里是内容超出两行... ',
      time: '1小时前',
    ),
    _SystemNotificationItem(
      iconColor: Color(0xFFFFD1BE),
      icon: Icons.inventory_2_rounded,
      title: '线上作品下架通知',
      desc: '这里是内容超出两行省略这里是内容超出两行省略这里是内容超出两行省略这里是内容超出两行... ',
      time: '1小时前',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: key,
      padding: EdgeInsets.fromLTRB(16.w, 6.w, 16.w, 16.w),
      itemBuilder: (context, index) => _SystemNotificationTile(item: _items[index]),
      separatorBuilder: (_, __) => SizedBox(height: 12.w),
      itemCount: _items.length,
    );
  }
}

class _InteractionNotificationList extends StatelessWidget {
  const _InteractionNotificationList({super.key});

  static const _items = [
    _InteractionNotificationItem(
      avatarColor: Color(0xFFEAB67B),
      title: '摄影阿木',
      action: '赞了你的视频',
      time: '2天前',
      message: '',
      thumbVisible: true,
      reaction: NotificationReaction.like,
    ),
    _InteractionNotificationItem(
      avatarColor: Color(0xFFEAB67B),
      title: '摄影阿木',
      action: '赞了你的帖子',
      time: '2天前',
      message: '',
      thumbVisible: true,
      reaction: NotificationReaction.like,
    ),
    _InteractionNotificationItem(
      avatarColor: Color(0xFFEB8E59),
      title: '摄影阿木',
      action: '评论了你的帖子',
      time: '2天前',
      message: '这套穿搭太好看了吧，求分享购买这套穿搭太好看了吧，求分享购买这套穿搭太好看了吧，求分享购买这套穿搭太好看了吧，求分享...',
      thumbVisible: true,
      reaction: NotificationReaction.comment,
    ),
    _InteractionNotificationItem(
      avatarColor: Color(0xFFAD7BFF),
      title: '摄影阿木',
      action: '回复了你的评论',
      time: '2天前',
      message: '英伦风，很不错，挺赞的穿搭',
      reaction: NotificationReaction.reply,
      quote: '英伦风，很不错，挺赞的穿搭',
    ),
    _InteractionNotificationItem(
      avatarColor: Color(0xFFDB6CA8),
      title: '摄影阿木',
      action: '赞了你的评论',
      time: '2天前',
      message: '英伦风，很不错，挺赞的穿搭',
      thumbVisible: true,
      reaction: NotificationReaction.like,
      quote: '英伦风，很不错，挺赞的穿搭',
    ),
    _InteractionNotificationItem(
      avatarColor: Color(0xFFF5B55E),
      title: '摄影阿木',
      action: '@提及了你',
      time: '2天前',
      message: '#拍照@婉儿这套穿搭太好看了吧，求分享购买这套穿搭太好看了吧，求分享...',
      thumbVisible: true,
      reaction: NotificationReaction.mention,
    ),
    _InteractionNotificationItem(
      avatarColor: Color(0xFFEB8E59),
      title: '摄影阿木',
      action: '在你的主页留言',
      time: '2天前',
      message: '这套穿搭太好看了吧，求分享购买这套穿搭太好看了吧，求分享购买这套穿搭太好看了吧，求分享购买这套穿搭太好看了吧，求分享...',
      reaction: NotificationReaction.comment,
      footerActions: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: key,
      padding: EdgeInsets.fromLTRB(16.w, 2.w, 16.w, 16.w),
      itemBuilder: (context, index) => _InteractionNotificationTile(item: _items[index]),
      separatorBuilder: (_, __) => SizedBox(height: 14.w),
      itemCount: _items.length,
    );
  }
}

class _FanNotificationList extends StatelessWidget {
  const _FanNotificationList({super.key});

  static const _items = [
    _FanNotificationItem(
      name: 'Sarah Jenks',
      time: '昨天',
      buttonText: '已互关',
    ),
    _FanNotificationItem(
      name: 'Sarah Jenks',
      time: '昨天',
      buttonText: '回关',
      selected: true,
    ),
    _FanNotificationItem(
      name: 'Sarah Jenks',
      time: '昨天',
      buttonText: '已互关',
    ),
    _FanNotificationItem(
      name: 'Sarah Jenks',
      time: '昨天',
      buttonText: '已互关',
    ),
    _FanNotificationItem(
      name: 'Sarah Jenks',
      time: '昨天',
      buttonText: '已互关',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: key,
      padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 16.w),
      itemBuilder: (context, index) => _FanNotificationTile(item: _items[index]),
      separatorBuilder: (_, __) => SizedBox(height: 14.w),
      itemCount: _items.length,
    );
  }
}

class _SystemNotificationItem {
  const _SystemNotificationItem({
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.desc,
    required this.time,
    this.unread = false,
  });

  final Color iconColor;
  final IconData icon;
  final String title;
  final String desc;
  final String time;
  final bool unread;
}

class _InteractionNotificationItem {
  const _InteractionNotificationItem({
    required this.avatarColor,
    required this.title,
    required this.action,
    required this.time,
    required this.message,
    required this.reaction,
    this.thumbVisible = false,
    this.quote,
    this.footerActions = false,
  });

  final Color avatarColor;
  final String title;
  final String action;
  final String time;
  final String message;
  final NotificationReaction reaction;
  final bool thumbVisible;
  final String? quote;
  final bool footerActions;
}

enum NotificationReaction { like, comment, reply, mention }

class _FanNotificationItem {
  const _FanNotificationItem({
    required this.name,
    required this.time,
    required this.buttonText,
    this.selected = false,
  });

  final String name;
  final String time;
  final String buttonText;
  final bool selected;
}

class _SystemNotificationTile extends StatelessWidget {
  const _SystemNotificationTile({required this.item});

  final _SystemNotificationItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () {
        SystemNotificationDetailRoute(title: item.desc).push(context);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.unread)
            Padding(
              padding: EdgeInsets.only(top: 18.w, right: 10.w),
              child: Container(
                width: 7.w,
                height: 7.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B6A),
                  shape: BoxShape.circle,
                ),
              ),
            )
          else
            SizedBox(width: 17.w),
          Container(
            width: 54.w,
            height: 54.w,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(item.icon, color: item.iconColor.withValues(alpha: 0.95), size: 28.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: const Color(0xFF1D293D),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        item.time,
                        style: TextStyle(
                          color: const Color(0xFF95A0B4),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.w),
                  Text(
                    item.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF647286),
                      fontSize: 12.sp,
                      height: 1.35,
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
}

class _InteractionNotificationTile extends StatelessWidget {
  const _InteractionNotificationTile({required this.item});

  final _InteractionNotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: item.avatarColor.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(Icons.person, color: item.avatarColor, size: 24.w),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: const Color(0xFF1D293D),
                          fontSize: 13.sp,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: item.title,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' ${item.action}'),
                        ],
                      ),
                    ),
                  ),
                  if (item.thumbVisible) ...[
                    SizedBox(width: 12.w),
                    _ThumbPreview(),
                  ],
                ],
              ),
              if (item.message.isNotEmpty) ...[
                SizedBox(height: 8.w),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    item.quote ?? item.message,
                    maxLines: item.quote == null ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF5A677A),
                      fontSize: 12.sp,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 6.w),
              Text(
                item.time,
                style: TextStyle(
                  color: const Color(0xFF95A0B4),
                  fontSize: 11.sp,
                ),
              ),
              if (item.footerActions) ...[
                SizedBox(height: 8.w),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionButton(label: '屏蔽', selected: true),
                    SizedBox(width: 8.w),
                    _ActionButton(label: '展示'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FanNotificationTile extends StatelessWidget {
  const _FanNotificationTile({required this.item});

  final _FanNotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E7D8),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(Icons.person, color: const Color(0xFFC2B091), size: 28.w),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  color: const Color(0xFF1D293D),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.w),
              Text(
                '${item.name} 关注了你',
                style: TextStyle(
                  color: const Color(0xFF1D293D),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.w),
              Text(
                item.time,
                style: TextStyle(
                  color: const Color(0xFF95A0B4),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        _FollowButton(selected: item.selected, label: item.buttonText),
      ],
    );
  }
}

class _ThumbPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58.w,
      height: 76.w,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Container(color: const Color(0xFFB8B8B8)),
          ),
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16.w),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF3B6A) : const Color(0xFF1D2433),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.selected, required this.label});

  final bool selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.w),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1D2433) : Colors.white,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: const Color(0xFFCCD3DD)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1D293D),
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
