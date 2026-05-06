import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import 'media_asset_preview_page.dart';

/// 相册资源列表按拍摄/创建时间倒序（最新在前）。
final PMFilter _mediaGalleryNewestFirstFilter = FilterOptionGroup(
  orders: const [
    OrderOption(
      type: OrderOptionType.createDate,
      asc: false,
    ),
  ],
);

/// 系统相册页返回结果（用于发布编辑页）。
class MediaPickResult {
  MediaPickResult({required this.files, required this.isVideo})
      : assert(files.isNotEmpty),
        assert(!isVideo || files.length == 1);

  final List<XFile> files;
  final bool isVideo;
}

enum _MediaFilter { all, image, video }

/// 媒体相册选择（设计稿 8.1 / 8.2）：顶栏、相册下拉、全部/图片/视频、三列网格、选中底部面板与「下一步」。
class MediaPickerPage extends StatefulWidget {
  const MediaPickerPage({
    super.key,
    this.maxSelection = 1,
  });

  /// 1 为单选（可与短视频/视频条目）；大于 1 时仅展示图片且支持多选（帖子相册）。
  final int maxSelection;

  @override
  State<MediaPickerPage> createState() => _MediaPickerPageState();
}

class _MediaPickerPageState extends State<MediaPickerPage> {
  static const int _pageSize = 60;
  static const Color _tabInactive = Color(0xFF999999);
  static const Color _selectBlue = Color(0xFF007AFF);
  static const Color _nextBtnBg = Color(0xFF1A1A1A);

  final ScrollController _scrollController = ScrollController();

  PermissionState _permission = PermissionState.notDetermined;
  bool _loading = true;
  String? _loadError;

  List<AssetPathEntity> _albums = [];
  int _albumIndex = 0;
  _MediaFilter _filter = _MediaFilter.all;

  final List<AssetEntity> _assets = [];
  int _page = 0;
  int _totalCount = 0;
  bool _loadingMore = false;

  final List<AssetEntity> _selectedOrdered = [];

  AssetPathEntity? get _currentPath =>
      _albums.isEmpty ? null : _albums[_albumIndex];

  RequestType get _requestType {
    switch (_filter) {
      case _MediaFilter.all:
        return RequestType.common;
      case _MediaFilter.image:
        return RequestType.image;
      case _MediaFilter.video:
        return RequestType.video;
    }
  }

  RequestType get _effectiveRequestType =>
      widget.maxSelection > 1 ? RequestType.image : _requestType;

  bool get _multiImageMode => widget.maxSelection > 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (kIsWeb) {
      _loading = false;
      _loadError = 'mediaPickerWebUnsupported'.tr();
    } else {
      _initNative();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scrollController.position.pixels > max - 480) {
      unawaited(_loadMore());
    }
  }

  Future<void> _initNative() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final state = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    if (!state.hasAccess) {
      setState(() {
        _permission = state;
        _loading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _permission = state);
    await _reloadFromAlbums();
  }

  Future<void> _reloadFromAlbums() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final paths = await PhotoManager.getAssetPathList(
        hasAll: true,
        onlyAll: false,
        type: _effectiveRequestType,
        filterOption: _mediaGalleryNewestFirstFilter,
      );
      if (!mounted) return;
      if (paths.isEmpty) {
        setState(() {
          _albums = [];
          _albumIndex = 0;
          _assets.clear();
          _page = 0;
          _totalCount = 0;
          _loading = false;
        });
        return;
      }
      final allIdx = paths.indexWhere((p) => p.isAll);
      _albums = paths;
      _albumIndex = allIdx >= 0 ? allIdx : 0;

      await _fetchPage(reset: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'mediaPickerLoadError'.tr();
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchPage({required bool reset}) async {
    final path = _currentPath;
    if (path == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      if (reset) {
        _page = 0;
        _assets.clear();
        _selectedOrdered.clear();
      }
      _totalCount = await path.assetCountAsync;
      final list = await path.getAssetListPaged(page: 0, size: _pageSize);
      if (!mounted) return;
      _assets.addAll(list);
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'mediaPickerLoadError'.tr();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    final path = _currentPath;
    if (path == null || _loadingMore || _assets.length >= _totalCount) {
      return;
    }
    _loadingMore = true;
    try {
      final next = await path.getAssetListPaged(page: _page + 1, size: _pageSize);
      if (!mounted) return;
      if (next.isEmpty) {
        setState(() => _loadingMore = false);
        return;
      }
      setState(() {
        _page++;
        _assets.addAll(next);
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _onFilterChanged(_MediaFilter f) async {
    if (_multiImageMode) return;
    if (_filter == f) return;
    setState(() {
      _filter = f;
      _selectedOrdered.clear();
    });
    setState(() => _loading = true);
    await _reloadFromAlbums();
  }

  Future<void> _onAlbumPicked(int index) async {
    if (index == _albumIndex || index < 0 || index >= _albums.length) return;
    setState(() {
      _albumIndex = index;
      _selectedOrdered.clear();
      _loading = true;
    });
    await _fetchPage(reset: true);
  }

  void _showAlbumSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView.builder(
            itemCount: _albums.length,
            itemBuilder: (context, i) {
              final p = _albums[i];
              final sel = i == _albumIndex;
              return ListTile(
                title: Text(
                  p.name,
                  style: TextStyle(
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? Colors.black : const Color(0xFF333333),
                  ),
                ),
                trailing: sel ? const Icon(Icons.check, color: _selectBlue) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _onAlbumPicked(i);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _openPreview(AssetEntity entity) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => MediaAssetPreviewPage(entity: entity),
      ),
    );
  }

  void _toggleEntity(AssetEntity entity) {
    if (_multiImageMode && entity.type == AssetType.video) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mediaPickerPostImagesOnly'.tr())),
      );
      return;
    }

    final i = _selectedOrdered.indexWhere((e) => e.id == entity.id);
    if (i >= 0) {
      setState(() => _selectedOrdered.removeAt(i));
      return;
    }

    if (_selectedOrdered.length >= widget.maxSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'mediaPickerMaxN'.tr(namedArgs: {'n': '${widget.maxSelection}'}),
          ),
        ),
      );
      return;
    }

    setState(() => _selectedOrdered.add(entity));
  }

  int _selectionOrder(AssetEntity entity) {
    final i = _selectedOrdered.indexWhere((e) => e.id == entity.id);
    return i < 0 ? 0 : i + 1;
  }

  Future<void> _onNext() async {
    if (_selectedOrdered.isEmpty) return;
    try {
      final files = <XFile>[];
      var isVideo = false;
      for (final entity in _selectedOrdered) {
        final file = await entity.originFile;
        if (!mounted) return;
        if (file == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('mediaPickerLoadError'.tr())),
          );
          return;
        }
        files.add(XFile(file.path));
        if (entity.type == AssetType.video) {
          isVideo = true;
        }
      }
      if (!mounted) return;
      if (_selectedOrdered.length == 1 && isVideo) {
        Navigator.of(context).pop(
          MediaPickResult(files: files, isVideo: true),
        );
        return;
      }
      Navigator.of(context).pop(
        MediaPickResult(files: files, isVideo: false),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mediaPickerLoadError'.tr())),
        );
      }
    }
  }

  Future<void> _fallbackSystemPicker() async {
    final picker = ImagePicker();
    final x = await picker.pickMedia();
    if (!mounted) return;
    if (x == null) return;
    final isVideo = x.path.toLowerCase().contains('video') ||
        x.mimeType?.startsWith('video') == true;
    Navigator.of(context).pop(
      MediaPickResult(files: [x], isVideo: isVideo),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'mediaPickerTabAll'.tr(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF666666)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _fallbackSystemPicker,
                  style: FilledButton.styleFrom(
                    backgroundColor: _nextBtnBg,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('mediaPickerOpenSystem'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_permission.hasAccess && !_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'mediaPickerPermission'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    await PhotoManager.openSetting();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _nextBtnBg,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('mediaPickerOpenSettings'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loadError != null && _albums.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(_loadError!, style: const TextStyle(color: Color(0xFF666666))),
        ),
      );
    }

    final path = _currentPath;
    final albumTitle = path?.name ?? 'mediaPickerAllPhotos'.tr();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MediaQuery.paddingOf(context).top > 0
              ? SizedBox(height: MediaQuery.paddingOf(context).top)
              : const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 26),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _albums.length > 1 ? _showAlbumSheet : null,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            albumTitle,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (_albums.length > 1) ...[
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.black87, size: 22),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (_multiImageMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'mediaPickerTabImage'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          else
            _FilterTabBar(
              filter: _filter,
              onChanged: _onFilterChanged,
            ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_loading && _assets.isEmpty)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                if (!_loading && _assets.isEmpty)
                  Center(
                    child: Text(
                      'mediaPickerEmpty'.tr(),
                      style: const TextStyle(color: _tabInactive),
                    ),
                  ),
                if (_assets.isNotEmpty)
                  GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      0,
                      2,
                      0,
                      MediaQuery.paddingOf(context).bottom +
                          8 +
                          (_selectedOrdered.isNotEmpty
                              ? (_multiImageMode ? 196.0 : 168.0)
                              : 0),
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 1,
                    ),
                    itemCount: _assets.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _assets.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final entity = _assets[index];
                      final order = _selectionOrder(entity);
                      return _MediaCell(
                        entity: entity,
                        selectionOrder: order,
                        maxSelection: widget.maxSelection,
                        onOpenPreview: () => _openPreview(entity),
                        onToggleSelect: () => _toggleEntity(entity),
                      );
                    },
                  ),
                if (_selectedOrdered.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _multiImageMode
                        ? _MultiSelectionPanel(
                            entities: List<AssetEntity>.from(_selectedOrdered),
                            onRemoveAt: (i) {
                              setState(() {
                                if (i >= 0 && i < _selectedOrdered.length) {
                                  _selectedOrdered.removeAt(i);
                                }
                              });
                            },
                            onNext: _onNext,
                          )
                        : _SelectionPanel(
                            entity: _selectedOrdered.first,
                            onRemove: () =>
                                setState(() => _selectedOrdered.clear()),
                            onNext: _onNext,
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabBar extends StatelessWidget {
  const _FilterTabBar({
    required this.filter,
    required this.onChanged,
  });

  final _MediaFilter filter;
  final ValueChanged<_MediaFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(_MediaFilter f, String label) {
      final on = filter == f;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(f),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                  color: on ? Colors.black : _MediaPickerPageState._tabInactive,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 3,
                decoration: BoxDecoration(
                  color: on ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(_MediaFilter.all, 'mediaPickerTabAll'.tr()),
        tab(_MediaFilter.image, 'mediaPickerTabImage'.tr()),
        tab(_MediaFilter.video, 'mediaPickerTabVideo'.tr()),
      ],
    );
  }
}

class _MediaCell extends StatelessWidget {
  const _MediaCell({
    required this.entity,
    required this.selectionOrder,
    required this.maxSelection,
    required this.onOpenPreview,
    required this.onToggleSelect,
  });

  final AssetEntity entity;
  /// 0 = 未选中；否则为选中序号（从 1 开始）。
  final int selectionOrder;
  final int maxSelection;
  final VoidCallback onOpenPreview;
  final VoidCallback onToggleSelect;

  bool get selected => selectionOrder > 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: onOpenPreview,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List?>(
                future: entity.thumbnailDataWithSize(
                  const ThumbnailSize.square(240),
                ),
                builder: (context, snap) {
                  final bytes = snap.data;
                  if (bytes == null) {
                    return ColoredBox(color: Colors.grey.shade300);
                  }
                  return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
                },
              ),
              if (entity.type == AssetType.video)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 22,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                ),
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleSelect,
              customBorder: const CircleBorder(),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _MediaPickerPageState._selectBlue : Colors.transparent,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 2,
                          ),
                        ],
                ),
                child: selected
                    ? (maxSelection > 1
                        ? Text(
                            '$selectionOrder',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 14, color: Colors.white))
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.entity,
    required this.onRemove,
    required this.onNext,
  });

  final AssetEntity entity;
  final VoidCallback onRemove;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      elevation: 12,
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 12 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<Uint8List?>(
                            future: entity.thumbnailDataWithSize(
                              const ThumbnailSize.square(200),
                            ),
                            builder: (context, snap) {
                              final b = snap.data;
                              if (b == null) {
                                return ColoredBox(color: Colors.grey.shade300);
                              }
                              return Image.memory(b, fit: BoxFit.cover);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: -7,
                        right: -7,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 4,
                                  color: Color(0x22000000),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: _MediaPickerPageState._nextBtnBg,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'mediaPickerNext'.tr(),
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
    );
  }
}

class _MultiSelectionPanel extends StatelessWidget {
  const _MultiSelectionPanel({
    required this.entities,
    required this.onRemoveAt,
    required this.onNext,
  });

  final List<AssetEntity> entities;
  final ValueChanged<int> onRemoveAt;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      elevation: 12,
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 12 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final entity = entities[i];
                  return SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<Uint8List?>(
                              future: entity.thumbnailDataWithSize(
                                const ThumbnailSize.square(200),
                              ),
                              builder: (context, snap) {
                                final b = snap.data;
                                if (b == null) {
                                  return ColoredBox(color: Colors.grey.shade300);
                                }
                                return Image.memory(b, fit: BoxFit.cover);
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => onRemoveAt(i),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Color(0x22000000),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: _MediaPickerPageState._nextBtnBg,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'mediaPickerNext'.tr(),
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
    );
  }
}
