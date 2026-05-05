import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:g_link/domain/domains/feed.dart';
import 'package:g_link/domain/model/feed_models.dart';
import 'package:g_link/domain/type_def.dart';
import 'package:g_link/ui_layer/event/event_bus.dart';
import 'package:g_link/ui_layer/notifier/app_feed_notifier.dart';
import 'package:g_link/ui_layer/notifier/publish_notifier.dart';
import 'package:g_link/ui_layer/page/publish_hashtag_delete_formatter.dart';
import 'package:g_link/ui_layer/page/publish_hashtag_span_builder.dart';
import 'package:g_link/ui_layer/page/publish_nearby_locations.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/publish_video_preview_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_thumbnail_video/index.dart' show ImageFormat;
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

/// 拍摄/相册选择后的编辑与发布页（图文为设计稿样式；短视频为「封面 + 描述 + 话题 + 发布设置 + 底栏」与稿一致）。
class PublishComposePage extends StatefulWidget {
  PublishComposePage({
    super.key,
    required this.media,
    required this.isVideo,
    this.videoDurationMs,
    this.videoWidth,
    this.videoHeight,
  })  : assert(media.isNotEmpty),
        assert(!isVideo || media.length == 1);

  final List<XFile> media;
  final bool isVideo;

  /// 调用方（如视频编辑页）若已经初始化过 `VideoPlayerController`，
  /// 可把元数据透传过来，发布时省去再次创建控制器探测的耗时。
  final int? videoDurationMs;
  final int? videoWidth;
  final int? videoHeight;

  @override
  State<PublishComposePage> createState() => _PublishComposePageState();
}

class _PublishComposePageState extends State<PublishComposePage> {
  static const int _descMax = 200;
  /// `POST /api/v1/posts`：`cover_image_index` 最大为 8。
  static const int _apiMaxCoverImageIndex = 8;
  static const Color _chipBg = Color(0xFFE8EEF5);
  static const Color _publishBg = Color(0xFF1A1D26);
  static const Color _hintColor = Color(0xFFBDBDBD);
  static const Color _douyinAccent = Color(0xFFFE2C55);
  /// 发布设置：图标、右侧摘要（设计稿灰）
  static const Color _publishSettingsSecondary = Color(0xFF8C95A8);
  static const Color _publishSettingsChevron = Color(0xFFCCCCCC);

  static final List<PublishLocationInput> _mockPois = [
    const PublishLocationInput(
      name: '上海 · 外滩',
      address: '上海市黄浦区中山东一路',
      latitude: 31.2397,
      longitude: 121.4903,
    ),
    const PublishLocationInput(
      name: '杭州 · 西湖',
      address: '浙江省杭州市西湖区',
      latitude: 30.2435,
      longitude: 120.1551,
    ),
    const PublishLocationInput(
      name: '北京 · 三里屯',
      address: '工体北路与三里屯路交叉口',
      latitude: 39.9375,
      longitude: 116.4516,
    ),
    const PublishLocationInput(
      name: '成都 · 春熙路',
      address: '四川省成都市锦江区',
      latitude: 30.6599,
      longitude: 104.0815,
    ),
    const PublishLocationInput(
      name: '广州 · 天河城',
      address: '广东省广州市天河区天河路',
      latitude: 23.1353,
      longitude: 113.3268,
    ),
  ];

  final _descController = TextEditingController();

  List<Uint8List>? _multiPreviewBytes;

  PublishLocationInput? _location;
  /// 0 所有人 / 1 仅粉丝 / 2 仅互相关注 / 3 仅自己（与 UI 设计一致；后两项在接口中的映射见 [_visibilityForApi]）。
  int _visibilityChoice = 0;
  /// 与 [_visibilityChoice] 档位一致；接口仅 0/1，见 [_allowCommentForApi]。
  int _allowComment = 0;
  /// 多图时由轮播「设为封面」写入；单图恒为 0。
  int _coverImageIndex = 0;

  final _descFocus = FocusNode();
  final _hashtagSpanBuilder = PublishHashtagSpanBuilder();
  final List<TextInputFormatter> _descInputFormatters = [
    PublishHashtagDeleteFormatter(),
  ];
  Timer? _topicDebounce;
  int _topicReq = 0;
  List<PublishTopicRow> _topicRows = const [];
  bool _topicLoading = false;
  bool _videoComposeDefaultsSeeded = false;

  /// 视频元数据预探测：进入页面后立刻在后台读取时长 / 宽高，
  /// 等用户点「发布」时直接复用结果，不再在关键路径上等 `VideoPlayerController.initialize`。
  Future<({int durationMs, int width, int height})?>? _videoMetaFuture;

  @override
  void initState() {
    super.initState();
    if (!widget.isVideo && widget.media.length > 1) {
      unawaited(_loadMultiPreviewBytes());
    }
    if (widget.isVideo && widget.media.isNotEmpty) {
      // 上一页（视频编辑页）若已经初始化过控制器，可直接复用其结果，
      // 否则后台异步预探测，等用户点「发布」时直接拿到结果。
      final dur = widget.videoDurationMs ?? 0;
      final w = widget.videoWidth ?? 0;
      final h = widget.videoHeight ?? 0;
      if (dur > 0 && w > 0 && h > 0) {
        _videoMetaFuture = Future.value(
          (durationMs: dur, width: w, height: h),
        );
      } else {
        _videoMetaFuture = _probeVideoMeta(widget.media.first);
      }
    }
    _descFocus.addListener(_onDescFocusChanged);
    _descController.addListener(_onDescTextOrSelectionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isVideo && !_videoComposeDefaultsSeeded) {
      _videoComposeDefaultsSeeded = true;
      _location = PublishLocationInput(name: 'publishDemoLocation'.tr());
      _visibilityChoice = 2;
    }
  }

  void _onDescFocusChanged() {
    if (!_descFocus.hasFocus) {
      _topicDebounce?.cancel();
      if (mounted) {
        setState(() {
          _topicRows = const [];
          _topicLoading = false;
        });
      }
    } else {
      _onDescTextOrSelectionChanged();
    }
  }

  void _onDescTextOrSelectionChanged() {
    if (!mounted) return;
    setState(() {});
    _topicDebounce?.cancel();
    if (!_descFocus.hasFocus) return;
    if (_activeHashSegment() == null) {
      setState(() {
        _topicRows = const [];
        _topicLoading = false;
      });
      return;
    }
    final q = _activeHashSegment()!.query;
    if (q.isEmpty) {
      unawaited(_loadHotTopics());
    } else {
      _topicDebounce = Timer(const Duration(milliseconds: 320), () {
        if (mounted) unawaited(_loadSearchTopics(q));
      });
    }
  }

  /// 光标前最近一次 `#` 起至光标、中间无空白 → 视为正在**编辑**新话题（选词完成后须有空格隔开正文）。
  ({int hashIndex, String query})? _activeHashSegment() {
    final text = _descController.text;
    final sel = _descController.selection;
    if (!sel.isValid) return null;
    final cursor = sel.extentOffset.clamp(0, text.length);
    if (cursor <= 0) return null;
    final before = text.substring(0, cursor);
    final hashIdx = before.lastIndexOf('#');
    if (hashIdx < 0) return null;
    final tail = text.substring(hashIdx + 1, cursor);
    if (tail.contains(' ') || tail.contains('\n')) return null;
    return (hashIndex: hashIdx, query: tail);
  }

  Future<void> _loadHotTopics() async {
    final id = ++_topicReq;
    if (mounted) {
      setState(() {
        _topicLoading = true;
        _topicRows = const [];
      });
    }
    final r = await context.read<FeedDomain>().getHotTopics();
    if (!mounted || id != _topicReq) return;
    if (r.status != 0 || r.data == null) {
      setState(() {
        _topicLoading = false;
        _topicRows = const [];
      });
      return;
    }
    setState(() {
      _topicLoading = false;
      _topicRows = r.data!;
    });
  }

  Future<void> _loadSearchTopics(String query) async {
    final id = ++_topicReq;
    if (mounted) {
      setState(() {
        _topicLoading = true;
        _topicRows = const [];
      });
    }
    final r = await context.read<FeedDomain>().searchTopics(query);
    if (!mounted || id != _topicReq) return;
    if (r.status != 0 || r.data == null) {
      setState(() {
        _topicLoading = false;
        _topicRows = const [];
      });
      return;
    }
    setState(() {
      _topicLoading = false;
      _topicRows = r.data!;
    });
  }

  void _onTopicChipTap() {
    final t = _descController.text;
    final sel = _descController.selection;
    final pos =
        sel.isValid ? sel.start.clamp(0, t.length) : t.length;
    if (t.characters.length >= _descMax) return;
    final newText = '${t.substring(0, pos)}#${t.substring(pos)}';
    if (newText.characters.length > _descMax) return;
    _descController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + 1),
    );
    _descFocus.requestFocus();
  }

  void _onTopicRowTap(PublishTopicRow row) {
    final seg = _activeHashSegment();
    if (seg == null) return;
    final t = _descController.text;
    final cursor = _descController.selection.extentOffset.clamp(0, t.length);
    final insert = row.tag;
    // 选词结束后带尾随空格：后续输入不再与同一段 # 绑定，也不会误请求搜索。
    final newText =
        '${t.substring(0, seg.hashIndex + 1)}$insert ${t.substring(cursor)}';
    if (newText.characters.length > _descMax) return;
    final newOffset = seg.hashIndex + 1 + insert.length + 1;
    _topicReq++;
    _topicDebounce?.cancel();
    setState(() {
      _topicRows = const [];
      _topicLoading = false;
    });
    _descController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    FocusManager.instance.primaryFocus?.unfocus();
  }

  bool _shouldShowTopicPanel() {
    if (!_descFocus.hasFocus || _activeHashSegment() == null) {
      return false;
    }
    return _topicLoading || _topicRows.isNotEmpty;
  }

  Widget _buildTopicSuggestPanel() {
    if (!_shouldShowTopicPanel()) return const SizedBox.shrink();
    final h = math.min(
      260.0,
      MediaQuery.sizeOf(context).height * 0.38,
    );
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        height: h,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFF0F0F0)),
          ),
        ),
        child: _topicLoading
            ? const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                itemCount: _topicRows.length,
                itemBuilder: (context, i) {
                  final row = _topicRows[i];
                  return InkWell(
                    onTap: () => _onTopicRowTap(row),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              row.lineTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF111111),
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (row.statLabel.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Text(
                              row.statLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _publishSettingsSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _loadMultiPreviewBytes() async {
    try {
      final list = <Uint8List>[];
      for (final f in widget.media) {
        list.add(await f.readAsBytes());
      }
      if (mounted) {
        setState(() => _multiPreviewBytes = list);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mediaPickerLoadError'.tr())),
        );
      }
    }
  }

  void _toastComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('publishComingSoon'.tr())),
    );
  }

  /// `POST /api/v1/posts`：`visibility` 仅支持 0/1/2；互关档位与仅粉丝暂共用 1。
  int _visibilityForApi() {
    switch (_visibilityChoice) {
      case 1:
      case 2:
        return 1;
      case 3:
        return 2;
      default:
        return 0;
    }
  }

  /// `POST /api/v1/posts`：`allow_comment` 仅 0=所有人 / 1=仅关注的人；粉丝 / 互关 / 暂同传 1。
  int _allowCommentForApi() {
    switch (_allowComment) {
      case 1:
      case 2:
      case 3:
        return 1;
      default:
        return 0;
    }
  }

  String _visibilitySummaryShort() {
    switch (_visibilityChoice) {
      case 1:
        return 'publishVisibilityShortFansOnly'.tr();
      case 2:
        return 'publishVisibilityShortMutual'.tr();
      case 3:
        return 'publishVisibilityShortSelf'.tr();
      default:
        return 'publishVisibilityShortEveryone'.tr();
    }
  }

  String _commentSummaryShort() {
    switch (_allowComment) {
      case 1:
        return 'publishCommentShortFansOnly'.tr();
      case 2:
        return 'publishVisibilityShortMutual'.tr();
      case 3:
        return 'publishVisibilityShortSelf'.tr();
      default:
        return 'publishCommentShortEveryone'.tr();
    }
  }

  String _locationSummaryShort() => _location == null
      ? 'publishLocationSummaryHidden'.tr()
      : _location!.name;

  int _resolvedCoverImageIndex(int imageCount) {
    if (imageCount <= 0) return 0;
    final maxIdx = imageCount - 1;
    final cap = math.min(maxIdx, _apiMaxCoverImageIndex);
    return _coverImageIndex.clamp(0, cap);
  }

  /// 正文内 `#话题` → 接口 `tags`（去重保序，单标签 ≤30 字符与 OpenAPI 一致）。
  List<String>? _tagsFromDescription(String text) {
    final re = RegExp(r'#([^\s#]{1,30})');
    final seen = <String>{};
    final out = <String>[];
    for (final m in re.allMatches(text)) {
      final t = (m.group(1) ?? '').trim();
      if (t.isEmpty || seen.contains(t)) continue;
      seen.add(t);
      out.add(t);
    }
    return out.isEmpty ? null : out;
  }

  Widget _douyinDragHandle({Color barColor = const Color(0xFFE8E8E8)}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  /// 设计稿：三项（公开 / 互关 / 私密）、无分隔线、正文常规字重 `#111111`、约 56pt 行高。
  Widget _designVisibilitySheetLine(
    BuildContext sheetContext, {
    required int choiceValue,
    required String title,
  }) {
    const titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Color(0xFF111111),
      height: 1.25,
    );
    final selected = switch (choiceValue) {
      0 => _visibilityChoice == 0,
      2 => _visibilityChoice == 2 || _visibilityChoice == 1,
      3 => _visibilityChoice == 3,
      _ => false,
    };
    return InkWell(
      onTap: () {
        Navigator.pop(sheetContext);
        setState(() => _visibilityChoice = choiceValue);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(child: Text(title, style: titleStyle)),
            if (selected)
              const Icon(Icons.check, size: 22, color: Color(0xFF111111))
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }

  void _showVisibilitySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _douyinDragHandle(),
                _designVisibilitySheetLine(
                  ctx,
                  choiceValue: 0,
                  title: 'publishVisibilitySheetLinePublic'.tr(),
                ),
                _designVisibilitySheetLine(
                  ctx,
                  choiceValue: 2,
                  title: 'publishVisibilitySheetLineMutual'.tr(),
                ),
                _designVisibilitySheetLine(
                  ctx,
                  choiceValue: 3,
                  title: 'publishVisibilitySheetLinePrivate'.tr(),
                ),
                SizedBox(height: MediaQuery.paddingOf(ctx).bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 设计稿：四项、无分隔线、`#111111` 常规字重、拖条约 `#CCCCCC`。
  Widget _designCommentPolicyLine(BuildContext sheetContext, int allowVal) {
    const titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Color(0xFF111111),
      height: 1.25,
    );
    final selected = _allowComment == allowVal;
    final title = switch (allowVal) {
      0 => 'publishCommentShortEveryone'.tr(),
      1 => 'publishCommentShortFansOnly'.tr(),
      2 => 'publishVisibilityMutualLine'.tr(),
      3 => 'publishVisibilitySelfLine'.tr(),
      _ => '',
    };
    return InkWell(
      onTap: () {
        Navigator.pop(sheetContext);
        setState(() => _allowComment = allowVal);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(child: Text(title, style: titleStyle)),
            if (selected)
              const Icon(Icons.check, size: 22, color: Color(0xFF111111))
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }

  void _showCommentPolicySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _douyinDragHandle(barColor: const Color(0xFFCCCCCC)),
                _designCommentPolicyLine(ctx, 0),
                _designCommentPolicyLine(ctx, 1),
                _designCommentPolicyLine(ctx, 2),
                _designCommentPolicyLine(ctx, 3),
                SizedBox(height: MediaQuery.paddingOf(ctx).bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocationSheet() {
    final h = MediaQuery.sizeOf(context).height * 0.62;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                height: h,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: _PublishLocationSheet(
                  accent: _douyinAccent,
                  mockPois: _mockPois,
                  initial: _location,
                  onPick: (picked) {
                    Navigator.pop(ctx);
                    setState(() => _location = picked);
                  },
                  dragHandle: _douyinDragHandle(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _topicDebounce?.cancel();
    _descFocus.removeListener(_onDescFocusChanged);
    _descFocus.dispose();
    _descController.dispose();
    super.dispose();
  }

  Widget _chip(String label, {VoidCallback? onTap}) {
    return Material(
      color: _chipBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap ?? _toastComingSoon,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// 设计稿：线框气泡 + 底部三圆点。
  Widget _publishCommentRowLeading() {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 22,
            color: _publishSettingsSecondary,
          ),
          Positioned(
            bottom: 5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.5),
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: _publishSettingsSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow({
    IconData? icon,
    Widget? leading,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    assert(icon != null || leading != null);
    final Widget left = leading ??
        Icon(icon!, size: 22, color: _publishSettingsSecondary);
    return InkWell(
      onTap: onTap ?? _toastComingSoon,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            left,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 15, color: Color(0xFF111111)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 14,
                  color: _publishSettingsSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: _publishSettingsChevron, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _singleImageBlock() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w * 1.25;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<Uint8List>(
                  future: widget.media.first.readAsBytes(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return ColoredBox(color: Colors.grey.shade200);
                    }
                    return Image.memory(snap.data!, fit: BoxFit.cover);
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14, top: 32),
                      child: Center(
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () {
                              setState(() => _coverImageIndex = 0);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('publishCoverSetDone'.tr()),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Text(
                                'publishEditCover'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 短视频发布页封面：首帧缩略图 + 「编辑封面」（与设计稿一致竖版比例）。
  Widget _buildVideoCoverBlock() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = MediaQuery.sizeOf(context).height;
        // 设计稿：封面占屏幕高度约 2/5，竖版 9:16 比例。
        final h = screenH * 2 / 5;
        final w = (h * 9 / 16).clamp(0.0, constraints.maxWidth);
        final path = widget.media.first.path;
        final dpr = MediaQuery.of(context).devicePixelRatio;
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder<Uint8List?>(
                    future: VideoThumbnail.thumbnailData(
                      video: path,
                      timeMs: 0,
                      maxWidth: (w * dpr).round().clamp(180, 720),
                      maxHeight: (h * dpr).round().clamp(320, 1280),
                      imageFormat: ImageFormat.JPEG,
                      quality: 88,
                    ),
                    builder: (context, snap) {
                      if (snap.hasError ||
                          !snap.hasData ||
                          snap.data == null) {
                        return ColoredBox(color: Colors.grey.shade300);
                      }
                      return Image.memory(snap.data!, fit: BoxFit.cover);
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14, top: 32),
                        child: Center(
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: () {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('publishCoverSetDone'.tr()),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Text(
                                  'publishEditCover'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _multiCarousel() {
    final bytes = _multiPreviewBytes;
    if (bytes == null) {
      return const SizedBox(
        height: 380,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return _PublishMultiCarousel(
      imageBytes: bytes,
      onSetCoverTap: (index) {
        setState(() => _coverImageIndex = index);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('publishCoverSetDone'.tr())),
        );
      },
    );
  }

  Future<void> _submitPost(PublishNotifier notifier) async {
    notifier.setSubmitting(true);
    try {
      final desc = _descController.text.trim();
      final content =
          desc.isEmpty ? 'publishDefaultPostTitle'.tr() : desc;
      if (content.characters.length > _descMax) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('publishContentTooLong'.tr())),
        );
        return;
      }
      final imageCount = widget.media.length;
      final coverIdx = _resolvedCoverImageIndex(imageCount);
      final tags = _tagsFromDescription(content);
      final result = await context.read<FeedDomain>().publishImagePost(
            content: content,
            images: widget.media,
            coverImageIndex: coverIdx,
            tags: tags,
            visibility: _visibilityForApi(),
            allowComment: _allowCommentForApi(),
            location: _location,
          );
      if (!mounted) return;
      if (result.status != 0 || result.data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_publishErrorMessage(result.msg))),
        );
        return;
      }
      eventBus.fire(PostPublishedEvent(postId: result.data!.postId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('publishSubmitSuccess'.tr())),
      );
      const HomeRoute().go(context);
    } finally {
      if (mounted) notifier.setSubmitting(false);
    }
  }

  /// 用一次性 [VideoPlayerController] 探测视频时长 / 宽高，以满足
  /// `POST /videos/upload-done` 对 `duration_ms / width / height` 的必填校验。
  Future<({int durationMs, int width, int height})?> _probeVideoMeta(
    XFile xFile,
  ) async {
    VideoPlayerController? controller;
    try {
      controller = await publishVideoPreviewCreateController(xFile);
      await controller.initialize();
      final dur = controller.value.duration.inMilliseconds;
      final size = controller.value.size;
      final w = size.width.round();
      final h = size.height.round();
      if (dur <= 0 || w <= 0 || h <= 0) return null;
      return (durationMs: dur, width: w, height: h);
    } catch (_) {
      return null;
    } finally {
      try {
        await controller?.dispose();
      } catch (_) {}
    }
  }

  Future<void> _submitVideoPost(PublishNotifier notifier) async {
    final desc = _descController.text.trim();
    if (desc.characters.length > _descMax) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('publishContentTooLong'.tr())),
      );
      return;
    }
    notifier.setSubmitting(true);
    try {
      // 优先使用 initState 里预探测的结果；若用户极快地点了发布、Future 还没就绪，
      // 也只是等同步等待已在执行的探测，不会重复创建 VideoPlayerController。
      final metaFuture = _videoMetaFuture ??= _probeVideoMeta(widget.media.first);
      final meta = await metaFuture;
      if (!mounted) return;
      if (meta == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('publishVideoMetaInvalid'.tr())),
        );
        return;
      }
      final tags = _tagsFromDescription(desc);
      // OpenAPI «发布视频» 请求体不含 allow_comment / mentioned_uids / draft_id，
      // 视频侧暂不下发，避免触发 422 校验。
      final result = await context.read<FeedDomain>().publishVideoPost(
            video: widget.media.first,
            description: desc,
            durationMs: meta.durationMs,
            width: meta.width,
            height: meta.height,
            tags: tags,
            visibility: _visibilityForApi(),
            location: _location,
          );
      if (!mounted) return;
      if (result.status != 0 || result.data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_publishErrorMessage(result.msg))),
        );
        return;
      }
      eventBus.fire(VideoPublishedEvent(videoId: result.data!.videoId));
      context.read<AppFeedNotifier>().createPost(
            title: desc.isEmpty ? 'publishDefaultPostTitle'.tr() : desc,
            content: desc.isEmpty ? 'publishDefaultPostTitle'.tr() : desc,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('publishSubmitSuccess'.tr())),
      );
      const HomeRoute().go(context);
    } finally {
      if (mounted) notifier.setSubmitting(false);
    }
  }

  /// 把当前编辑器的设置（可见性、评论权限、话题、定位）打包成 OpenAPI «保存草稿»
  /// 描述里的 `settings` 自由结构 JSON。
  Json _draftSettingsPayload(String content) {
    final tags = _tagsFromDescription(content);
    return <String, dynamic>{
      'visibility': _visibilityForApi(),
      'allow_comment': _allowCommentForApi(),
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (_location != null) 'location': _location!.toJson(),
    };
  }

  /// 把当前选中的本地媒体打包成草稿的 `media_data`。
  /// 因为草稿尚未走预签名上传，这里只能记录本地路径 / 文件名 + 必要展示元数据，
  /// 服务端按自由 JSON 落库即可，下次回到草稿时由客户端按需取用。
  Json _draftMediaDataPayload({
    required bool isVideo,
    required ({int durationMs, int width, int height})? videoMeta,
  }) {
    if (isVideo) {
      final v = widget.media.first;
      return <String, dynamic>{
        'video_path': v.path,
        if (v.name.isNotEmpty) 'video_name': v.name,
        if (videoMeta != null) ...{
          'duration_ms': videoMeta.durationMs,
          'width': videoMeta.width,
          'height': videoMeta.height,
        },
      };
    }
    return <String, dynamic>{
      'images': widget.media
          .map((e) => <String, dynamic>{
                'path': e.path,
                if (e.name.isNotEmpty) 'name': e.name,
              })
          .toList(),
      'cover_index': _resolvedCoverImageIndex(widget.media.length),
    };
  }

  /// 「保存草稿」按钮：调用 `POST /api/v1/drafts`，成功后退出整个发布流程
  /// （拍摄 / 编辑 / 发布等中间页都不保留），回到首页。
  ///
  /// 用 `notifier.savingDraft` 单独标记，与 `submitting` 互斥，让 spinner 只出现在
  /// 真正点击的那个按钮上——之前两个按钮共用 `submitting`，会出现「点保存草稿、
  /// 发布按钮转圈」的错觉。
  Future<void> _saveDraft(PublishNotifier notifier) async {
    if (notifier.busy) return;
    notifier.setSavingDraft(true);
    try {
      final desc = _descController.text;
      final isVideo = widget.isVideo;
      ({int durationMs, int width, int height})? videoMeta;
      if (isVideo) {
        try {
          videoMeta = await (_videoMetaFuture ??=
              _probeVideoMeta(widget.media.first));
        } catch (_) {
          videoMeta = null;
        }
      }
      if (!mounted) return;
      final result = await context.read<FeedDomain>().saveDraft(
            type: isVideo ? 'video' : 'post',
            content: desc,
            mediaData:
                _draftMediaDataPayload(isVideo: isVideo, videoMeta: videoMeta),
            settings: _draftSettingsPayload(desc),
          );
      if (!mounted) return;
      if (result.status != 0 || result.data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_publishErrorMessage(result.msg))),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('publishDraftSavedSuccess'.tr())),
      );
      // 与 `_submitPost` 一致——直接 go 回首页，把发布流程的所有中间页都丢掉。
      const HomeRoute().go(context);
    } finally {
      if (mounted) notifier.setSavingDraft(false);
    }
  }

  String _publishErrorMessage(String? msg) {
    if (msg == null || msg.isEmpty) return 'publishApiFailed'.tr();
    const known = <String>{
      'publishNeedImage',
      'publishEmptyImage',
      'publishPresignInvalid',
      'publishVideoEmptyFile',
      'publishVideoFileTooLarge',
      'publishVideoMetaInvalid',
      'publishVideoPresignInvalid',
      'publishVideoDoneInvalid',
      'publishVideoTranscodeFailed',
      'publishVideoTranscodeTimeout',
    };
    if (known.contains(msg)) return msg.tr();
    return msg;
  }

  Widget _buildPostScrollContent() {
    final multi = widget.media.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (multi) _multiCarousel() else _singleImageBlock(),
        const SizedBox(height: 20),
        ExtendedTextField(
          controller: _descController,
          focusNode: _descFocus,
          specialTextSpanBuilder: _hashtagSpanBuilder,
          inputFormatters: _descInputFormatters,
          maxLength: _descMax,
          maxLines: 4,
          minLines: 2,
          style: const TextStyle(fontSize: 16, color: Color(0xFF111111)),
          decoration: InputDecoration(
            hintText: 'publishDescPlaceholder'.tr(),
            hintStyle: const TextStyle(color: _hintColor, fontSize: 16),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'publishSettingsHeader'.tr(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        _settingsRow(
          icon: Icons.location_on_outlined,
          label: 'publishAddLocation'.tr(),
          value: _locationSummaryShort(),
          onTap: _showLocationSheet,
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F0F0)),
        _settingsRow(
          icon: Icons.people_outline,
          label: 'publishWhoCanSee'.tr(),
          value: _visibilitySummaryShort(),
          onTap: _showVisibilitySheet,
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F0F0)),
        _settingsRow(
          leading: _publishCommentRowLeading(),
          label: 'publishAllowComment'.tr(),
          value: _commentSummaryShort(),
          onTap: _showCommentPolicySheet,
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 100),
      ],
    );
  }

  Widget _buildVideoComposeScrollContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildVideoCoverBlock(),
        const SizedBox(height: 20),
        ExtendedTextField(
          controller: _descController,
          focusNode: _descFocus,
          specialTextSpanBuilder: _hashtagSpanBuilder,
          inputFormatters: _descInputFormatters,
          maxLength: _descMax,
          maxLines: 4,
          minLines: 2,
          style: const TextStyle(fontSize: 16, color: Color(0xFF111111)),
          decoration: InputDecoration(
            hintText: 'publishDescPlaceholder'.tr(),
            hintStyle: const TextStyle(color: _hintColor, fontSize: 16),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'publishSettingsHeader'.tr(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        _settingsRow(
          icon: Icons.location_on_outlined,
          label: 'publishAddLocation'.tr(),
          value: _locationSummaryShort(),
          onTap: _showLocationSheet,
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F0F0)),
        _settingsRow(
          icon: Icons.person_outline,
          label: 'publishWhoCanSee'.tr(),
          value: _visibilitySummaryShort(),
          onTap: _showVisibilitySheet,
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F0F0)),
        _settingsRow(
          leading: _publishCommentRowLeading(),
          label: 'publishAllowComment'.tr(),
          value: _commentSummaryShort(),
          onTap: _showCommentPolicySheet,
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 100),
      ],
    );
  }

  Widget _buildTopicToolBar() {
    final len = _descController.text.characters.length;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  'publishChipTopic'.tr(),
                  onTap: _onTopicChipTap,
                ),
                _chip('publishChipMention'.tr()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '$len/$_descMax',
              style: const TextStyle(fontSize: 13, color: _hintColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifierType =
        widget.isVideo ? PublishType.video : PublishType.post;

    return ChangeNotifierProvider(
      create: (_) => PublishNotifier()..updateType(notifierType),
      child: Consumer<PublishNotifier>(
        builder: (context, notifier, _) {
          if (widget.isVideo) {
            return Scaffold(
              backgroundColor: Colors.white,
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              child: _buildVideoComposeScrollContent(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: _buildTopicToolBar(),
                          ),
                          _buildTopicSuggestPanel(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        10,
                        20,
                        MediaQuery.paddingOf(context).bottom + 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: notifier.busy
                                  ? null
                                  : () => _saveDraft(notifier),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.black87),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: const StadiumBorder(),
                              ),
                              child: notifier.savingDraft
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black87,
                                      ),
                                    )
                                  : Text(
                                      'publishSaveDraft'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: notifier.busy
                                  ? null
                                  : () => _submitVideoPost(notifier),
                              style: FilledButton.styleFrom(
                                backgroundColor: _publishBg,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    _publishBg.withValues(alpha: 0.5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              child: notifier.submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'publishPostPrimary'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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

          return Scaffold(
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.black, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: _buildPostScrollContent(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: _buildTopicToolBar(),
                        ),
                        _buildTopicSuggestPanel(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      MediaQuery.paddingOf(context).bottom + 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: notifier.busy
                                ? null
                                : () => _saveDraft(notifier),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black87),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                            ),
                            child: notifier.savingDraft
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Text(
                                    'publishSaveDraft'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: notifier.busy
                                ? null
                                : () => _submitPost(notifier),
                            style: FilledButton.styleFrom(
                              backgroundColor: _publishBg,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _publishBg.withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: notifier.submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    widget.media.length > 1
                                        ? 'publishSubmitPost'.tr()
                                        : 'publishPostPrimary'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 抖音风格「添加地点」：定位成功后展示附近 POI（Photon + 系统逆地理），并附「更多地点」推荐列表。
class _PublishLocationSheet extends StatefulWidget {
  const _PublishLocationSheet({
    required this.dragHandle,
    required this.mockPois,
    required this.initial,
    required this.onPick,
    required this.accent,
  });

  final Widget dragHandle;
  final List<PublishLocationInput> mockPois;
  final PublishLocationInput? initial;
  final void Function(PublishLocationInput?) onPick;
  final Color accent;

  @override
  State<_PublishLocationSheet> createState() => _PublishLocationSheetState();
}

class _PublishLocationSheetState extends State<_PublishLocationSheet> {
  final _searchFocus = FocusNode();
  String _query = '';

  List<PublishLocationInput> _nearby = const [];
  bool _nearbyLoading = false;
  String? _nearbyNote;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadNearbyAddresses());
    });
  }

  Future<void> _loadNearbyAddresses() async {
    setState(() {
      _nearbyLoading = true;
      _nearbyNote = null;
    });
    final pos = await tryGetPublishPosition();
    if (!mounted) return;
    if (pos == null) {
      setState(() {
        _nearby = const [];
        _nearbyLoading = false;
        _nearbyNote = 'publishLocationNearbyNeedGps'.tr();
      });
      return;
    }
    final list = await loadNearbyForKnownPosition(context, pos);
    if (!mounted) return;
    setState(() {
      _nearby = list;
      _nearbyLoading = false;
      if (list.isEmpty) {
        _nearbyNote = 'publishLocationNearbyEmpty'.tr();
      }
    });
  }

  List<PublishLocationInput> get _moreMock {
    final names = _nearby.map((e) => e.name.toLowerCase()).toSet();
    return widget.mockPois
        .where((p) => !names.contains(p.name.toLowerCase()))
        .toList();
  }

  bool _matchesQuery(PublishLocationInput p) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (p.name.toLowerCase().contains(q)) return true;
    final a = (p.address ?? '').toLowerCase();
    return a.contains(q);
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _poiTile(PublishLocationInput p) {
    final sel = _isPoiSelected(p);
    return InkWell(
      onTap: () => widget.onPick(p),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place_outlined, size: 22, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                      height: 1.25,
                    ),
                  ),
                  if (p.address != null && p.address!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      p.address!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (sel)
              Icon(Icons.check_rounded, color: widget.accent, size: 24)
            else
              const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScrollChildren() {
    final q = _query.trim();
    final children = <Widget>[];

    if (q.isNotEmpty) {
      final merged = [..._nearby, ...widget.mockPois].where(_matchesQuery).toList();
      for (var i = 0; i < merged.length; i++) {
        if (i > 0) {
          children.add(const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFF2F2F2),
          ));
        }
        children.add(_poiTile(merged[i]));
      }
      if (merged.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'publishLocationSearchEmpty'.tr(),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      return children;
    }

    if (_nearbyNote != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Text(
            _nearbyNote!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
        ),
      );
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 20, bottom: 4),
          child: Wrap(
            spacing: 4,
            runSpacing: 0,
            children: [
              TextButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
                child: Text('publishLocationOpenAppSettings'.tr()),
              ),
              TextButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
                child: Text('publishLocationOpenSystemLocation'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    children.add(_sectionTitle('publishLocationNearbySection'.tr()));
    if (_nearbyLoading && _nearby.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    for (var i = 0; i < _nearby.length; i++) {
      if (i > 0) {
        children.add(const Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: Color(0xFFF2F2F2),
        ));
      }
      children.add(_poiTile(_nearby[i]));
    }

    final more = _moreMock;
    if (more.isNotEmpty) {
      children.add(const Divider(height: 8, thickness: 0, color: Colors.transparent));
      children.add(_sectionTitle('publishLocationMorePlaces'.tr()));
      for (var i = 0; i < more.length; i++) {
        if (i > 0) {
          children.add(const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFF2F2F2),
          ));
        }
        children.add(_poiTile(more[i]));
      }
    }

    return children;
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  bool _poiEquals(PublishLocationInput a, PublishLocationInput b) =>
      a.name == b.name &&
      (a.latitude == b.latitude) &&
      (a.longitude == b.longitude);

  bool _isPoiSelected(PublishLocationInput p) {
    final i = widget.initial;
    if (i == null) return false;
    return _poiEquals(i, p);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.dragHandle,
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: Text(
            'publishLocationSheetTitle'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFF2F2F2)),
        InkWell(
          onTap: () => widget.onPick(null),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'publishLocationHiddenTitle'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'publishLocationHiddenSub'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.initial == null)
                  Icon(Icons.check_rounded, color: widget.accent, size: 24)
                else
                  const SizedBox(width: 24),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: TextField(
            focusNode: _searchFocus,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'publishLocationSearchHint'.tr(),
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF999999), size: 22),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: _buildScrollChildren(),
          ),
        ),
      ],
    );
  }
}

/// 多图封面轮播：解码与 [PageController] 放在独立 State 内，避免拖动时整页 setState 导致图片重复异步加载闪烁。
class _PublishMultiCarousel extends StatefulWidget {
  const _PublishMultiCarousel({
    required this.imageBytes,
    required this.onSetCoverTap,
  });

  final List<Uint8List> imageBytes;
  final ValueChanged<int> onSetCoverTap;

  @override
  State<_PublishMultiCarousel> createState() => _PublishMultiCarouselState();
}

class _PublishMultiCarouselState extends State<_PublishMultiCarousel> {
  late final PageController _pageController;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.72, initialPage: 0);
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final p = _pageController.page;
    if (p != null && mounted) {
      setState(() => _page = p);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.imageBytes.length;
    return SizedBox(
      height: 380,
      child: PageView.builder(
        controller: _pageController,
        itemCount: n,
        allowImplicitScrolling: true,
        itemBuilder: (context, i) {
          final dist = (_page - i).abs().clamp(0.0, 1.0);
          final scale = 0.86 + 0.14 * (1.0 - dist);
          final center = dist < 0.55;
          return Center(
            child: RepaintBoundary(
              child: Transform.scale(
                scale: scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _CarouselImageCard(
                    bytes: widget.imageBytes[i],
                    showOverlay: center,
                    onEditCoverTap: () => widget.onSetCoverTap(i),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CarouselImageCard extends StatefulWidget {
  const _CarouselImageCard({
    required this.bytes,
    required this.showOverlay,
    required this.onEditCoverTap,
  });

  final Uint8List bytes;
  final bool showOverlay;
  final VoidCallback onEditCoverTap;

  @override
  State<_CarouselImageCard> createState() => _CarouselImageCardState();
}

class _CarouselImageCardState extends State<_CarouselImageCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              widget.bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
            if (widget.showOverlay)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                    child: Center(
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: widget.onEditCoverTap,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Text(
                              'publishSetCoverAndEdit'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
