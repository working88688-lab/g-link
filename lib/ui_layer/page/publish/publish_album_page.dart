import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../image_paths.dart';
import '../../widgets/my_image.dart';

class PublishAlbumPage extends StatefulWidget {
  const PublishAlbumPage({super.key, this.initialSelectedAssets = const []});

  final List<AssetEntity> initialSelectedAssets;

  @override
  State<PublishAlbumPage> createState() => _PublishAlbumPageState();
}

class _PublishAlbumPageState extends State<PublishAlbumPage> {
  static const _tabs = ['图片', '视频'];
  static const ThumbnailSize _thumbnailSize = ThumbnailSize(400, 400);

  final List<AssetPathEntity> _albums = [];
  List<AssetEntity> _assets = [];

  String _selectedTab = '图片';
  late final List<AssetEntity> _selectedAssets = List<AssetEntity>.from(widget.initialSelectedAssets);
  final Map<String, Future<Uint8List?>> _thumbnailFutures = {};
  bool _loading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _loading = true;
      _errorText = null;
      _thumbnailFutures.clear();
    });

    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        setState(() {
          _loading = false;
          _errorText = '未获取相册权限';
        });
        return;
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
      );
      if (albums.isEmpty) {
        setState(() {
          _loading = false;
          _errorText = '未找到相册内容';
        });
        return;
      }

      final album = albums.first;
      final assets = await album.getAssetListPaged(page: 0, size: 200);

      if (!mounted) return;
      setState(() {
        _albums
          ..clear()
          ..addAll(albums);
        _assets = assets;
        _thumbnailFutures.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = '相册加载失败：$e';
      });
    }
  }

  Future<void> _selectAlbum() async {
    if (_albums.isEmpty) return;
    final index = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '选择相册',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _albums.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE8ECF3)),
                    itemBuilder: (context, itemIndex) {
                      final album = _albums[itemIndex];
                      return ListTile(
                        title: Text(album.name),
                        subtitle: FutureBuilder<int>(
                          future: album.assetCountAsync,
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            return Text('$count 项');
                          },
                        ),
                        onTap: () => Navigator.of(context).pop(itemIndex),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (index == null || index < 0 || index >= _albums.length) return;
    final album = _albums[index];
    final assets = await album.getAssetListPaged(page: 0, size: 200);
    if (!mounted) return;
    setState(() {
      _assets = assets;
      _thumbnailFutures.clear();
    });
  }

  List<AssetEntity> get _filteredAssets {
    return _assets.where((asset) {
      if (_selectedTab == '视频') return asset.type == AssetType.video;
      return asset.type == AssetType.image || asset.type == AssetType.other;
    }).toList();
  }

  Future<Uint8List?> _thumbnailFutureFor(AssetEntity asset) {
    return _thumbnailFutures.putIfAbsent(
      asset.id,
      () => asset.thumbnailDataWithSize(
        _thumbnailSize,
        quality: 85,
      ),
    );
  }

  void _toggleAssetSelection(AssetEntity asset) {
    setState(() {
      final selectedIndex = _selectedAssets.indexWhere((e) => e.id == asset.id);
      if (selectedIndex >= 0) {
        _selectedAssets.removeAt(selectedIndex);
      } else {
        _selectedAssets.add(asset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleAssets = _filteredAssets;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
          child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).maybePop();
                      },
                      child: MyImage.asset(
                        MyImagePaths.iconClose,
                        width: 24.w,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '所有照片',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D293D),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Color(0xFF1C1C1E)),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(width: 24, height: 32),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    for (int i = 0; i < _tabs.length; i++) ...[
                      _TabItem(
                        text: _tabs[i],
                        selected: _selectedTab == _tabs[i],
                        onTap: () => setState(() {
                          _selectedTab = _tabs[i];
                          _selectedAssets.clear();
                        }),
                      ),
                      if (i != _tabs.length - 1) const SizedBox(width: 24),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorText != null
                        ? Center(
                            child: Text(
                              _errorText!,
                              style: const TextStyle(color: Color(0xFF8E8E93)),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            itemCount: visibleAssets.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4.w,
                              mainAxisSpacing: 4.w,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              final asset = visibleAssets[index];
                              return _AlbumGridItem(
                                asset: asset,
                                selected: _selectedAssets.any((e) => e.id == asset.id),
                                thumbnailFuture: _thumbnailFutureFor(asset),
                                onTap: () => _toggleAssetSelection(asset),
                              );
                            },
                          ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _selectedAssets.isEmpty
                  ? const SizedBox.shrink(key: ValueKey('selected-assets-hidden'))
                  : SafeArea(
                      key: const ValueKey('selected-assets-visible'),
                      top: false,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(16.w, 14.w, 16.w, 16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16.w)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 50.w,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedAssets.length,
                                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                                itemBuilder: (context, index) {
                                  final asset = _selectedAssets[index];
                                  return _SelectedAssetPreview(
                                    asset: asset,
                                    thumbnailFuture: _thumbnailFutureFor(asset),
                                    onRemove: () => _toggleAssetSelection(asset),
                                    onTap: () {},
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 14.w),
                            GestureDetector(
                              onTap: () async {
                                if (!context.mounted) return;
                                Navigator.of(context).pop(_selectedAssets);
                                //
                                // final first = _selectedAssets.first;
                                // final file = await first.file;
                                // if (!context.mounted) return;
                                // Navigator.of(context).pop({
                                //   'name': first.title,
                                //   'type': first.type == AssetType.video ? 'video' : 'image',
                                //   'source': 'album',
                                //   'count': _selectedAssets.length,
                                //   'path': file?.path,
                                //   'assets': _selectedAssets
                                //       .map((asset) => {
                                //             'id': asset.id,
                                //             'name': asset.title,
                                //             'type': asset.type == AssetType.video ? 'video' : 'image',
                                //           })
                                //       .toList(),
                                // });
                              },
                              child: Container(
                                height: 50.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: const Color(0xFF1A1F2C),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '下一步',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      )),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF1C1C1E) : const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: 28,
            height: 2,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1C1C1E) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumGridItem extends StatelessWidget {
  const _AlbumGridItem({
    required this.asset,
    required this.selected,
    required this.thumbnailFuture,
    required this.onTap,
  });

  final AssetEntity asset;
  final bool selected;
  final Future<Uint8List?> thumbnailFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<Uint8List?>(
              future: thumbnailFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data != null) {
                  return Image.memory(
                    data,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  );
                }
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: asset.type == AssetType.video
                          ? [const Color(0xFF8E54E9), const Color(0xFF4776E6)]
                          : [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)],
                    ),
                  ),
                );
              },
            ),
            if (asset.type == AssetType.video)
              const Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            Positioned(
              top: 6.w,
              right: 6.w,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                child: MyImage.asset(
                  selected ? MyImagePaths.iconSel : MyImagePaths.iconUnSel,
                  key: ValueKey<bool>(selected),
                  width: 16.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedAssetPreview extends StatelessWidget {
  const _SelectedAssetPreview({
    required this.asset,
    required this.thumbnailFuture,
    required this.onRemove,
    required this.onTap,
  });

  final AssetEntity asset;
  final Future<Uint8List?> thumbnailFuture;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 50.w,
        height: 50.w,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.w),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List?>(
                future: thumbnailFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (data != null) {
                    return Image.memory(
                      data,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                  }
                  return Container(
                    color: const Color(0xFFE9ECF3),
                    alignment: Alignment.center,
                    child: Icon(
                      asset.type == AssetType.video ? Icons.videocam_rounded : Icons.image_rounded,
                      color: const Color(0xFF8E8E93),
                      size: 20.w,
                    ),
                  );
                },
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onRemove,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.5.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.7),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(6.w),
                      ),
                    ),
                    child: MyImage.asset(
                      MyImagePaths.iconPublishClose,
                      width: 11.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
