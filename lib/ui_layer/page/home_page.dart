import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/notifier/app_feed_notifier.dart';
import 'package:g_link/ui_layer/notifier/home_page_notifier.dart';
import 'package:g_link/ui_layer/theme/app_design.dart';
import 'package:g_link/ui_layer/widgets/app_bottom_sheet.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _postFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  static const _tabs = [
    'homeTabRecommend',
    'homeTabFollowing',
    'homeTabNearby'
  ];
  static const _categories = [
    'homeCategoryAll',
    'homeCategoryHot',
    'homeCategoryLatest',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomePageNotifier(),
      child: DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          backgroundColor: AppDesign.bg,
          appBar: AppBar(
            titleSpacing: 16,
            title: const Text(
              'G-Link',
              style: AppDesign.appBarTitle,
            ),
            actions: [
              IconButton(
                onPressed: _openSearchSheet,
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                onPressed: _openNotificationsSheet,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
            bottom: TabBar(
              tabs: _tabs.map((tab) => Tab(text: tab.tr())).toList(),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreatePostSheet,
            icon: const Icon(Icons.add),
            label: Text('homePublish'.tr()),
          ),
          body: Column(
            children: [
              _buildBanner(context),
              Expanded(
                child: TabBarView(
                  children: _tabs.map((_) => _buildFeed()).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDesign.cardRadius),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/app_announcement.png',
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                'homeBannerHint'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return Consumer2<HomePageNotifier, AppFeedNotifier>(
      builder: (context, notifier, feedNotifier, _) {
        final feedItems = feedNotifier.posts;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                _categories.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: notifier.selectedCategory == index
                        ? Colors.black87
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => notifier.updateCategory(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Text(
                        _categories[index].tr(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: notifier.selectedCategory == index
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...feedItems.map(
              (item) => _buildFeedCard(
                context: context,
                item: item,
                isNewlyPublished: item.id == feedNotifier.latestCreatedPostId,
                liked: notifier.likedPostIds.contains(item.id),
                onLike: () => notifier.toggleLike(item.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedCard({
    required BuildContext context,
    required AppFeedPost item,
    required bool isNewlyPublished,
    required bool liked,
    required VoidCallback onLike,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.cardRadius),
      ),
      color: AppDesign.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage:
                      AssetImage('assets/images/logo_gradient.png'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.author,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'homeFollowedAuthor'.tr(
                            namedArgs: {'author': item.author},
                          ),
                        ),
                      ),
                    );
                  },
                  child: Text('homeFollow'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (isNewlyPublished)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF3),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'homeJustPublished'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF027A48),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        context
                            .read<AppFeedNotifier>()
                            .consumeLatestCreatedPost();
                      },
                      child: Text('commonGotIt'.tr()),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              item.content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: liked ? Colors.redAccent : Colors.grey.shade600,
                  ),
                ),
                Text('${item.likes + (liked ? 1 : 0)}'),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    _openCommentsSheet(item.title);
                  },
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    _openShareSheet(item.title);
                  },
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreatePostSheet() async {
    _titleController.clear();
    _contentController.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            top: 8,
          ),
          child: Form(
            key: _postFormKey,
            child: Consumer<HomePageNotifier>(
              builder: (context, notifier, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'homeCreatePost'.tr(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'commonTitle'.tr(),
                      hintText: 'homeTitleHint'.tr(),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.length < 2 || text.length > 30) {
                        return 'homeTitleLengthError'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'commonContent'.tr(),
                      hintText: 'homeContentHint'.tr(),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.length < 10) {
                        return 'homeContentLengthError'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: notifier.isSubmitting
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              if (!_postFormKey.currentState!.validate()) {
                                return;
                              }
                              await notifier.submitPost(
                                title: _titleController.text.trim(),
                                content: _contentController.text.trim(),
                              );
                              if (!mounted) return;
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              messenger.showSnackBar(
                                SnackBar(
                                    content: Text('homePublishSuccess'.tr())),
                              );
                            },
                      child: notifier.isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('homeConfirmPublish'.tr()),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSearchSheet() async {
    final searchController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'commonSearchHint'.tr(),
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onSubmitted: (value) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'homeSearchDone'.tr(namedArgs: {'value': value.trim()}),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    searchController.dispose();
  }

  Future<void> _openNotificationsSheet() async {
    await AppBottomSheet.showSimpleList(
      context: context,
      title: 'homeNoticeTitle'.tr(),
      leadingIcon: Icons.notifications_active_outlined,
      items: [
        'homeNotice1'.tr(),
        'homeNotice2'.tr(),
        'homeNotice3'.tr(),
      ],
    );
  }

  Future<void> _openCommentsSheet(String title) async {
    await AppBottomSheet.showSimpleList(
      context: context,
      title: title,
      leadingIcon: Icons.comment_rounded,
      items: ['homeComment1'.tr(), 'homeComment2'.tr(), 'homeComment3'.tr()],
    );
  }

  Future<void> _openShareSheet(String title) async {
    await AppBottomSheet.showActions(
      context: context,
      title: 'homeShareTitle'.tr(namedArgs: {'title': title}),
      actions: [
        (
          icon: Icons.link_rounded,
          label: 'homeShareCopy'.tr(),
          onTap: () => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('homeLinkCopied'.tr())))
        ),
        (
          icon: Icons.chat_outlined,
          label: 'homeShareDm'.tr(),
          onTap: () => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('homeDmOpened'.tr())))
        ),
        (
          icon: Icons.qr_code_2_rounded,
          label: 'homeSharePoster'.tr(),
          onTap: () => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('homePosterPending'.tr())))
        ),
      ],
    );
  }
}
