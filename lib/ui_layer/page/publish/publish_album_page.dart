import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../image_paths.dart';
import '../../widgets/my_image.dart';

class PublishAlbumPage extends StatefulWidget {
  const PublishAlbumPage({super.key});

  @override
  State<PublishAlbumPage> createState() => _PublishAlbumPageState();
}

class _PublishAlbumPageState extends State<PublishAlbumPage> {
  static const _tabs = ['图片', '视频'];

  final List<AssetPathEntity> _albums = [];
  List<AssetEntity> _assets = [];
  AssetPathEntity? _currentAlbum;

  String _selectedTab = '图片';
  final List<AssetEntity> _selectedAssets = [];
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
        _currentAlbum = album;
        _assets = assets;
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
      _currentAlbum = album;
      _assets = assets;
    });
  }

  List<AssetEntity> get _filteredAssets {
    return _assets.where((asset) {
      if (_selectedTab == '视频') return asset.type == AssetType.video;
      return asset.type == AssetType.image || asset.type == AssetType.other;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleAssets = _filteredAssets;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
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
                            final selected = _selectedAssets.any((e) => e.id == asset.id);
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (selected) {
                                  _selectedAssets.removeWhere((e) => e.id == asset.id);
                                } else {
                                  _selectedAssets.add(asset);
                                }
                              }),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  FutureBuilder<Uint8List?>(
                                    future: asset.thumbnailDataWithSize(
                                      const ThumbnailSize(400, 400),
                                      quality: 85,
                                    ),
                                    builder: (context, snapshot) {
                                      final data = snapshot.data;
                                      if (data != null) {
                                        return Image.memory(data, fit: BoxFit.cover);
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
                                    child: MyImage.asset(
                                      selected ? MyImagePaths.iconSel : MyImagePaths.iconUnSel,
                                      width: 16.w,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7FB),
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        side: const BorderSide(color: Color(0xFFE5E5EA)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _selectedAssets.isEmpty
                          ? null
                          : () async {
                              final first = _selectedAssets.first;
                              final file = await first.file;
                              if (!context.mounted) return;
                              Navigator.of(context).pop({
                                'name': first.title,
                                'type': first.type == AssetType.video ? 'video' : 'image',
                                'source': 'album',
                                'count': _selectedAssets.length,
                                'path': file?.path,
                                'assets': _selectedAssets
                                    .map((asset) => {
                                          'id': asset.id,
                                          'name': asset.title,
                                          'type': asset.type == AssetType.video ? 'video' : 'image',
                                        })
                                    .toList(),
                              });
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(96, 44),
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      child: const Text(
                        '完成',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

