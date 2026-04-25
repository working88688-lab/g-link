import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/widgets/app_bottom_sheet.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

// ──────────────────────────────────────────
// Mock 数据
// ──────────────────────────────────────────
class _VideoItem {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String location;
  final String title;
  final List<String> tags;
  final String desc;
  final String music;
  final int likes;
  final int comments;
  final int favorites;
  final int shares;
  bool isFollowing = false;
  bool isLiked;
  bool isFavorited;
  bool isMuted = false;

  _VideoItem({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.location,
    required this.title,
    required this.tags,
    required this.desc,
    required this.music,
    required this.likes,
    required this.comments,
    required this.favorites,
    required this.shares,
    this.isLiked = false,
    this.isFavorited = false,
  });
}

final _mockVideos = List.generate(
  8,
  (i) => _VideoItem(
    id: '$i',
    authorName: 'creator_$i',
    authorAvatar: '',
    location: ['杭州·西湖', '上海·外滩', '北京·三里屯', '广州·珠江'][i % 4],
    title: ['一只穿云箭', '城市日记', '光与影', '流浪的风'][i % 4],
    tags: ['#打卡', '#日常', '#治愈系'],
    desc: '吹吹晚风，感受大自然的馈赠，舒舒服服的一天就从这里开始...',
    music: ['都是月亮惹的祸 | 章鱼', 'Summer | 久石让', '明天你好 | 牛奶咖啡'][i % 3],
    likes: 9837 + i * 123,
    comments: 637 + i * 31,
    favorites: 218 + i * 17,
    shares: 218 + i * 9,
    isLiked: i % 3 == 0,
    isFavorited: i % 5 == 0,
  ),
);

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class ShortVideoPage extends StatefulWidget {
  const ShortVideoPage({super.key});

  @override
  State<ShortVideoPage> createState() => _ShortVideoPageState();
}

class _ShortVideoPageState extends State<ShortVideoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final PageController _pageCtrl = PageController();
  final List<_VideoItem> _videos = List.of(_mockVideos);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 3,
      vsync: this,
      initialIndex: 1, // 默认"推荐"
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 沉浸式：状态栏白色图标
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── 全屏竖向滑动 ──
            PageView.builder(
              controller: _pageCtrl,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length,
              onPageChanged: (i) => setState(() {}),
              itemBuilder: (_, i) => _VideoCard(
                item: _videos[i],
                onToggleFollow: () => setState(() {
                  _videos[i].isFollowing = !_videos[i].isFollowing;
                }),
                onToggleLike: () => setState(() {
                  _videos[i].isLiked = !_videos[i].isLiked;
                }),
                onToggleFavorite: () => setState(() {
                  _videos[i].isFavorited = !_videos[i].isFavorited;
                }),
                onToggleMute: () => setState(() {
                  _videos[i].isMuted = !_videos[i].isMuted;
                }),
                onComment: () => _openComment(i),
              ),
            ),
            // ── 顶部 Tab 栏（全局叠加，不随 PageView 滚动）──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(tabCtrl: _tabCtrl),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openComment(int i) async {
    final item = _videos[i];
    await AppBottomSheet.show(
      context: context,
      child: _CommentContent(authorName: item.authorName),
    );
  }
}

// ──────────────────────────────────────────
// 顶部 Tab 栏
// ──────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final TabController tabCtrl;

  const _TopBar({required this.tabCtrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 62.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tab 居中
            TabBar(
              controller: tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicator: const BoxDecoration(),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Color(0xFF9D9D9D),
              labelStyle:
                  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
              tabs: [
                Tab(text: 'homeTabFollowing'.tr()),
                Tab(text: 'homeTabRecommend'.tr()),
                Tab(text: 'homeTabNearby'.tr()),
              ],
            ),
            // 搜索图标浮动在右侧，垂直居中
            Positioned(
              right: 12.w,
              child: GestureDetector(
                child: MyImage.asset(
                  MyImagePaths.iconShortVideoSearch,
                  width: 24.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// 单个视频卡片
// ──────────────────────────────────────────
class _VideoCard extends StatefulWidget {
  final _VideoItem item;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleMute;
  final VoidCallback onComment;

  const _VideoCard({
    required this.item,
    required this.onToggleFollow,
    required this.onToggleLike,
    required this.onToggleFavorite,
    required this.onToggleMute,
    required this.onComment,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 视频占位（灰色背景，后续接入播放器）──
        Container(
          color: Colors.white,
          child: Center(
            child: Icon(Icons.play_circle_outline,
                size: 72.sp, color: Colors.white24),
          ),
        ),

        // ── 全屏渐变遮罩（顶部 + 底部双向渐变）──
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.1, 0.2, 0.8, 0.9, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.403),
                  Colors.black.withValues(alpha: 0.259),
                  Colors.black.withValues(alpha: 0.0001),
                  Colors.black.withValues(alpha: 0.0001),
                  Colors.black.withValues(alpha: 0.261),
                  Colors.black.withValues(alpha: 0.699),
                ],
              ),
            ),
          ),
        ),

        // ── 右侧操作栏 ──
        Positioned(
          right: 8.w,
          bottom: 40.w,
          child: _ActionBar(
            item: item,
            onToggleFollow: widget.onToggleFollow,
            onToggleLike: widget.onToggleLike,
            onToggleFavorite: widget.onToggleFavorite,
            onToggleMute: widget.onToggleMute,
            onComment: widget.onComment,
          ),
        ),

        // ── 左下内容信息 ──
        Positioned(
          left: 8.w,
          right: 75.w,
          bottom: 40.w,
          child: _ContentInfo(
            item: item,
          ),
        ),

        // ── 底部进度条 ──
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _ProgressBar(),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// 右侧操作栏
// ──────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final _VideoItem item;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleMute;
  final VoidCallback onComment;

  const _ActionBar({
    required this.item,
    required this.onToggleFollow,
    required this.onToggleLike,
    required this.onToggleFavorite,
    required this.onToggleMute,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 头像 + 关注
        _AvatarWithFollow(
          item: item,
          onToggleFollow: onToggleFollow,
        ),
        SizedBox(height: 26.w),
        // 点赞
        _ActionBtn(
          icon: MyImage.asset(
            item.isLiked ? MyImagePaths.iconLiked : MyImagePaths.iconLike,
            width: 32.w,
          ),
          color: item.isLiked ? const Color(0xFFFF2D55) : Colors.white,
          count: item.isLiked ? item.likes + 1 : item.likes,
          onTap: onToggleLike,
        ),
        SizedBox(height: 20.w),
        // 评论
        _ActionBtn(
          icon: MyImage.asset(
            MyImagePaths.iconComment,
            width: 32.w,
          ),
          color: Colors.white,
          count: item.comments,
          onTap: onComment,
        ),
        SizedBox(height: 20.w),
        // 收藏
        _ActionBtn(
          icon: MyImage.asset(
            MyImagePaths.iconCollection,
            width: 32.w,
            // backgroundColor: item.isFavorited ? Color(0xFFFFD528) : Colors.white,
          ),
          color: item.isFavorited ? const Color(0xFFFFB800) : Colors.white,
          count: item.isFavorited ? item.favorites + 1 : item.favorites,
          onTap: onToggleFavorite,
        ),
        SizedBox(height: 20.w),
        // 分享
        _ActionBtn(
          icon: MyImage.asset(
            MyImagePaths.iconShare,
            width: 32.w,
          ),
          color: Colors.white,
          count: item.shares,
          onTap: () {},
          flipHorizontal: true,
        ),
        SizedBox(height: 20.w),
        // 更多
        _ActionBtn(
          icon: MyImage.asset(
            MyImagePaths.iconMore,
            width: 32.w,
          ),
          color: Colors.white,
          onTap: () {},
        ),
        SizedBox(height: 20.w),
        // 静音
        GestureDetector(
          onTap: onToggleMute,
          child: Container(
            width: 30.w,
            height: 30.w,
            child: MyImage.asset(
              MyImagePaths.iconMute,
              width: 30.w,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarWithFollow extends StatelessWidget {
  final _VideoItem item;
  final VoidCallback onToggleFollow;

  const _AvatarWithFollow({required this.item, required this.onToggleFollow});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // 头像
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF444444),
            border: Border.all(color: Colors.white, width: 2.w),
          ),
          child: item.authorAvatar.isNotEmpty
              ? ClipOval(
                  child: Image.network(item.authorAvatar, fit: BoxFit.cover))
              : Icon(Icons.person, color: Colors.white, size: 26.sp),
        ),
        // + 关注按钮
        if (!item.isFollowing)
          Positioned(
            bottom: -8.w,
            child: GestureDetector(
              onTap: onToggleFollow,
              child: MyImage.asset(
                MyImagePaths.iconShortVideoFollow,
                width: 16.w,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final Widget icon;
  final Color color;
  final int? count;
  final VoidCallback onTap;
  final bool flipHorizontal;

  const _ActionBtn({
    required this.icon,
    required this.color,
    this.count,
    required this.onTap,
    this.flipHorizontal = false,
  });

  String _formatCount(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if (count != null) ...[
            SizedBox(height: 2.w),
            Text(
              _formatCount(count!),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Color(0x43000000), blurRadius: 4.w)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// 左下内容信息
// ──────────────────────────────────────────
class _ContentInfo extends StatelessWidget {
  final _VideoItem item;

  const _ContentInfo({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 地址
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(30.w),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyImage.asset(
                MyImagePaths.iconLocate,
                width: 16.w,
              ),
              SizedBox(width: 3.w),
              Text(
                item.location,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                  shadows: [Shadow(color: Color(0x1F000000), blurRadius: 4.w)],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.w),
        // 标题
        Text(
          item.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Color(0x1F000000), blurRadius: 4.w)],
          ),
        ),
        SizedBox(height: 8.w),
        // 标签
        Wrap(
          spacing: 6.w,
          children: item.tags
              .map((t) => Text(
                    t,
                    style: TextStyle(
                      color: const Color(0xFFFAB200),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: Color(0x1F000000), blurRadius: 4.w)
                      ],
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: 2.w),
        // 描述（可展开）
        _ExpandableText(
          text: item.desc,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            shadows: [Shadow(color: Color(0x1F000000), blurRadius: 4.w)],
          ),
          moreStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            shadows: [Shadow(color: Color(0x1F000000), blurRadius: 4.w)],
          ),
          onExpandTap: () {
            // TODO: 处理展开事件（如弹窗/跳转）
          },
        ),
        SizedBox(height: 16.w),
        // 音乐
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6.w),
            boxShadow: [
              BoxShadow(
                  color: Colors.black45,
                  blurRadius: 4.w,
                  offset: Offset(0, 2.w))
            ],
          ),
          padding:
              EdgeInsets.only(left: 6.w, top: 7.w, bottom: 7.w, right: 17.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyImage.asset(
                MyImagePaths.iconMusical,
                width: 16.w,
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  item.music,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// 可展开文本（超出一行才显示展开按钮）
// ──────────────────────────────────────────
class _ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextStyle moreStyle;
  final VoidCallback? onExpandTap;

  const _ExpandableText({
    required this.text,
    required this.style,
    required this.moreStyle,
    this.onExpandTap,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final textDir = Directionality.of(ctx);
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: textDir,
        )..layout(maxWidth: constraints.maxWidth);

        final overflows = tp.didExceedMaxLines;

        // 文本未超出一行，直接显示
        if (!overflows) {
          return Text(widget.text, style: widget.style);
        }

        // 展开状态：直接显示全文，无收起按钮
        if (_expanded) {
          return Text(widget.text, style: widget.style);
        }

        // 收起状态：截断文本 + 仅展开部分可点击
        final moreText = '...  ${'shortVideoExpand'.tr()} ';
        final moreTp = TextPainter(
          text: TextSpan(text: moreText, style: widget.moreStyle),
          maxLines: 1,
          textDirection: textDir,
        )..layout();
        const iconWidth = 16.0; // 16.w 在 layout 阶段用逻辑像素近似

        final availableWidth = constraints.maxWidth - moreTp.width - iconWidth;
        final mainTp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: textDir,
        )..layout(maxWidth: availableWidth);

        final offset = mainTp
            .getPositionForOffset(Offset(availableWidth, mainTp.height / 2))
            .offset;
        final truncated = widget.text.substring(0, offset);

        return RichText(
          maxLines: 1,
          overflow: TextOverflow.clip,
          text: TextSpan(
            children: [
              TextSpan(text: truncated, style: widget.style),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _expanded = true);
                    widget.onExpandTap?.call();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(moreText, style: widget.moreStyle),
                      MyImage.asset(MyImagePaths.iconArrowDown, width: 16.w),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────
// 底部进度条（预留占位）
// ──────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: 0.35,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        minHeight: 3,
      ),
    );
  }
}

// ──────────────────────────────────────────
// 评论底部弹窗内容
// ──────────────────────────────────────────
class _CommentContent extends StatelessWidget {
  final String authorName;

  const _CommentContent({required this.authorName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65 - 40,
      child: Column(
        children: [
          SizedBox(height: 12.w),
          Text(
            'shortVideoCommentTitle'.tr(namedArgs: {'name': authorName}),
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
              children: [
                'shortVideoComment1'.tr(),
                'shortVideoComment2'.tr(),
                'shortVideoComment3'.tr(),
              ]
                  .map((c) => Padding(
                        padding: EdgeInsets.only(bottom: 16.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18.w,
                              backgroundColor: const Color(0xFFD1D1D6),
                              child: Icon(Icons.person,
                                  size: 20.sp, color: Colors.white),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(c, style: TextStyle(fontSize: 14.sp)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
