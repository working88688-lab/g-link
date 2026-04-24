import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:g_link/domain/domain.dart';
import 'package:g_link/ui_layer/theme/app_design.dart';
import 'package:g_link/ui_layer/widgets/app_bottom_sheet.dart';
import 'package:provider/provider.dart';

class ShortVideoPage extends StatefulWidget {
  const ShortVideoPage({super.key});

  @override
  State<ShortVideoPage> createState() => _ShortVideoPageState();
}

class _ShortVideoPageState extends State<ShortVideoPage> {
  bool _prefsLoaded = false;
  bool _initialAutoPlay = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final autoPlay =
        await context.read<AppDomain>().cache.readGuideAutoPlayEnabled();
    if (!mounted) return;
    setState(() {
      _initialAutoPlay = autoPlay;
      _prefsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return ChangeNotifierProvider(
      create: (_) => ShortVideoNotifier(autoPlay: _initialAutoPlay),
      child: Scaffold(
        backgroundColor: AppDesign.bg,
        appBar: AppBar(
          title: Text(
            'shortVideoTitle'.tr(),
            style: AppDesign.appBarTitle,
          ),
          actions: [
            Consumer<ShortVideoNotifier>(
              builder: (context, notifier, _) => IconButton(
                onPressed: () async {
                  notifier.toggleAutoPlay();
                  await context
                      .read<AppDomain>()
                      .cache
                      .upsertGuideAutoPlayEnabled(notifier.autoPlay);
                },
                icon: Icon(
                  notifier.autoPlay
                      ? Icons.play_circle_fill_rounded
                      : Icons.pause_circle_outline_rounded,
                ),
              ),
            ),
          ],
        ),
        body: Consumer<ShortVideoNotifier>(
          builder: (context, notifier, _) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
              itemCount: 8,
              itemBuilder: (context, index) {
                final liked = notifier.likedIndexes.contains(index);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(AppDesign.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 9 / 14.5,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDesign.cardRadius),
                          child: Image.asset(
                            'assets/images/img.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppDesign.cardRadius),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '@creator_$index',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'shortVideoCardDesc'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => notifier.toggleLike(index),
                                  icon: Icon(
                                    liked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color:
                                        liked ? Colors.redAccent : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                IconButton(
                                  onPressed: () {
                                    _openCommentPanel(context, index);
                                  },
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCommentPanel(BuildContext context, int index) async {
    await AppBottomSheet.showSimpleList(
      context: context,
      title: 'shortVideoCommentTitle'.tr(namedArgs: {'name': 'creator_$index'}),
      leadingIcon: Icons.comment_rounded,
      items: [
        'shortVideoComment1'.tr(),
        'shortVideoComment2'.tr(),
        'shortVideoComment3'.tr(),
      ],
    );
  }
}

class ShortVideoNotifier extends ChangeNotifier {
  ShortVideoNotifier({required this.autoPlay});

  bool autoPlay;
  final Set<int> likedIndexes = <int>{};

  void toggleAutoPlay() {
    autoPlay = !autoPlay;
    notifyListeners();
  }

  void toggleLike(int index) {
    if (likedIndexes.contains(index)) {
      likedIndexes.remove(index);
    } else {
      likedIndexes.add(index);
    }
    notifyListeners();
  }
}
