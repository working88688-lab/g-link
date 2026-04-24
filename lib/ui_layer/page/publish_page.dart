import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:g_link/ui_layer/notifier/app_feed_notifier.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/theme/app_design.dart';
import 'package:provider/provider.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PublishNotifier(),
      child: Scaffold(
        backgroundColor: AppDesign.bg,
        appBar: AppBar(
          title: Text('publishTitle'.tr(), style: AppDesign.appBarTitle),
        ),
        body: SafeArea(
          child: Consumer<PublishNotifier>(
            builder: (context, notifier, _) {
              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    Text(
                      'publishContentTitle'.tr(),
                      style: AppDesign.appBarTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'publishSubtitle'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppDesign.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<PublishType>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: PublishType.post,
                          icon: Icon(Icons.article_outlined),
                          label: Text('publishTypePost'.tr()),
                        ),
                        ButtonSegment(
                          value: PublishType.video,
                          icon: Icon(Icons.slow_motion_video_rounded),
                          label: Text('publishTypeVideo'.tr()),
                        ),
                      ],
                      selected: {notifier.publishType},
                      onSelectionChanged: (value) =>
                          notifier.updateType(value.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 30,
                      decoration: InputDecoration(
                        labelText: 'commonTitle'.tr(),
                        hintText: 'publishTitleHint'.tr(),
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.length < 2) return 'publishTitleError'.tr();
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      minLines: 5,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'commonContent'.tr(),
                        hintText: notifier.publishType == PublishType.post
                            ? 'publishBodyHintPost'.tr()
                            : 'publishBodyHintVideo'.tr(),
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.length < 10) return 'publishBodyError'.tr();
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('publishAllowComment'.tr()),
                      value: notifier.allowComment,
                      onChanged: notifier.toggleComment,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('publishSyncProfile'.tr()),
                      value: notifier.syncToProfile,
                      onChanged: notifier.toggleSync,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: notifier.submitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              await notifier.submit();
                              if (!context.mounted) return;
                              context.read<AppFeedNotifier>().createPost(
                                    title: _titleController.text.trim(),
                                    content: _descController.text.trim(),
                                  );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('publishSubmitSuccess'.tr())),
                              );
                              const HomeRoute().go(context);
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: notifier.submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('publishSubmit'.tr()),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum PublishType { post, video }

class PublishNotifier extends ChangeNotifier {
  PublishType publishType = PublishType.post;
  bool allowComment = true;
  bool syncToProfile = true;
  bool submitting = false;

  void updateType(PublishType type) {
    if (publishType == type) return;
    publishType = type;
    notifyListeners();
  }

  void toggleComment(bool value) {
    allowComment = value;
    notifyListeners();
  }

  void toggleSync(bool value) {
    syncToProfile = value;
    notifyListeners();
  }

  Future<void> submit() async {
    submitting = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    submitting = false;
    notifyListeners();
  }
}
