import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart' as models;
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:provider/provider.dart';

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
          onPressed: _markAllRead,
          child: Text(
            '全部已读',
            style: TextStyle(
              color: const Color(0xFF45556C),
              fontSize: 14.sp,
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
      padding: EdgeInsets.fromLTRB(16.w, 18.w, 16.w, 10.w),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final selected = index == _tabIndex;
          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = index),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 30.w,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1A1F2C) : const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF38475B),
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      right: -8.w,
                      top: -7.w,
                      child: Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF2056),
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '9',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
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
        return const _SystemNotificationList();
      case 1:
        return const _InteractionNotificationList();
      case 2:
        return const _FanNotificationList();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _markAllRead() async {
    await context.read<ProfileDomain>().markAllNotificationsRead();
  }
}

_SystemNotificationItem _systemFromModel(models.NotificationItem item) {
  return _SystemNotificationItem(
    iconColor: const Color(0xFFFFD88D),
    icon: Icons.notifications_active_rounded,
    title: item.title,
    desc: item.detailContent ?? item.desc,
    time: item.detailTime ?? item.time,
    unread: item.unread,
  );
}

_InteractionNotificationItem _interactionFromModel(models.NotificationItem item) {
  return _InteractionNotificationItem(
    avatarColor: const Color(0xFFEAB67B),
    title: item.title,
    action: item.desc,
    time: item.time,
    message: item.desc,
    reaction: NotificationReaction.comment,
  );
}

_FanNotificationItem _fanFromModel(models.NotificationItem item) {
  return _FanNotificationItem(
    name: item.title,
    time: item.time,
    buttonText: '已互关',
    selected: false,
  );
}

class NotificationScrollList extends StatefulWidget {
  const NotificationScrollList({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.separator,
    required this.loadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.padding,
  });

  final ScrollController? controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget separator;
  final bool loadingMore;
  final bool hasMore;
  final Future<void> Function()? onLoadMore;
  final EdgeInsets padding;

  @override
  State<NotificationScrollList> createState() => _NotificationScrollListState();
}

class _NotificationScrollListState extends State<NotificationScrollList> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: widget.controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: widget.itemCount + (widget.loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => widget.separator,
      itemBuilder: (context, index) {
        if (index >= widget.itemCount) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.w),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return widget.itemBuilder(context, index);
      },
    );
  }
}

class _SystemNotificationList extends StatelessWidget {
  const _SystemNotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('系统通知'));
  }
}

class _InteractionNotificationList extends StatelessWidget {
  const _InteractionNotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('互动通知'));
  }
}

class _FanNotificationList extends StatelessWidget {
  const _FanNotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('新增粉丝'));
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

enum NotificationReaction { like, comment, mention }

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
    return GestureDetector(
      onTap: () {
        SystemNotificationDetailRoute(title: item.desc).push(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (item.unread)
                  Padding(
                    padding: EdgeInsets.only(right: 7.w),
                    child: Container(
                      width: 9.w,
                      height: 9.w,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF2056),
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.w)),
                      ),
                    ),
                  )
                else
                  SizedBox(width: 16.w),
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(item.icon, color: item.iconColor.withValues(alpha: 0.95), size: 28.w),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style:
                              TextStyle(color: const Color(0xFF1A1F2C), fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        item.time,
                        style: TextStyle(
                          color: const Color(0xFF71727A),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.w),
                  Text(
                    item.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF71727A),
                      fontSize: 12.sp,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionNotificationTile extends StatelessWidget {
  const _InteractionNotificationTile({required this.item});

  final _InteractionNotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 8.w, right: 6.w, bottom: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: item.avatarColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(Icons.person, color: item.avatarColor, size: 24.w),
              ),
              Positioned(
                  right: -5.w,
                  bottom: 0.w,
                  child: MyImage.asset(
                    item.reaction == NotificationReaction.like
                        ? MyImagePaths.iconNoticeLike
                        : item.reaction == NotificationReaction.comment
                            ? MyImagePaths.iconNoticeComment
                            : item.reaction == NotificationReaction.mention
                                ? MyImagePaths.iconNoticeMention
                                : "",
                    width: 17.w,
                  ))
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "${item.title}  ",
                                  style: TextStyle(
                                      color: const Color(0xFF1A1F2C), fontSize: 14.sp, fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: ' ${item.action}',
                                  style: TextStyle(
                                      color: const Color(0xFF314158), fontSize: 12.sp, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          if (item.message.isNotEmpty) ...[
                            SizedBox(height: 4.w),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                item.quote ?? item.message,
                                maxLines: item.quote == null ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF314158),
                                  fontSize: 12.sp,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 8.w,
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: double.infinity,
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1F2C).withAlpha(4),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        width: 2.w,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAEAEA),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                      ),
                                      SizedBox(width: 7.w),
                                      Flexible(
                                        child: Text(
                                          "英伦风，很不错，挺赞的穿搭英伦风，",
                                          style: TextStyle(color: Color(0xFF1A1F2C), fontSize: 12.sp),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                          SizedBox(height: 4.w),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.time,
                                style: TextStyle(
                                  color: const Color(0xFF314158),
                                  fontSize: 12.sp,
                                ),
                              ),
                              Spacer(),
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
                          )
                        ],
                      ),
                    ),
                    if (item.thumbVisible) ...[
                      SizedBox(width: 11.w),
                      _ThumbPreview(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E7D8),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(Icons.person, color: const Color(0xFFC2B091), size: 28.w),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: const Color(0xFF0F172B),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '关注了你',
                    style: TextStyle(color: const Color(0xFF314158), fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                item.time,
                style: TextStyle(
                  color: const Color(0xFF62748E),
                  fontSize: 12.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.w),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF2056) : const Color(0xFF0F172B),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Color(0xFFF8F9FE),
          fontSize: 10.sp,
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
      width: 60.w,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 7.w),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1A1F2C) : Colors.transparent,
        borderRadius: BorderRadius.circular(999.r),
        border: !selected? Border.all(color: const Color(0xFFCCCCCC)):null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1A1F2C),
          fontSize: 13.sp,
          height: 0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
