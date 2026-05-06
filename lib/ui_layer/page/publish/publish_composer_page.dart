import 'package:flutter/material.dart';

class PublishMediaDraft {
  const PublishMediaDraft({
    required this.mediaType,
    this.title,
    this.coverLabel,
    this.sourceLabel,
  });

  final String mediaType;
  final String? title;
  final String? coverLabel;
  final String? sourceLabel;
}


class PublishComposerPage extends StatefulWidget {
  const PublishComposerPage({super.key, this.initialDraft});

  final PublishMediaDraft? initialDraft;

  @override
  State<PublishComposerPage> createState() => _PublishComposerPageState();
}

class _PublishComposerPageState extends State<PublishComposerPage> {
  static const _chips = ['#周末去哪', '#咖啡店打卡', '#滤镜分享', '#话题', '@提及'];

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final draft = widget.initialDraft;
    if (draft != null && _controller.text.isEmpty) {
      final seed = draft.title ?? '';
      if (seed.isNotEmpty) {
        _controller.text = seed;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.initialDraft;
    final mediaLabel = switch (draft?.mediaType) {
      'video' => '视频',
      _ => '图片',
    };
    final coverLabel = draft?.coverLabel ?? '编辑封面';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1C1C1E)),
                  ),
                  const Spacer(),
                  const Text(
                    '发布帖子',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    mediaLabel,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 160,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FA),
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF173B67), Color(0xFF0E1423)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: draft == null
                                        ? [const Color(0xFF1F5C99), const Color(0xFF0E1423)]
                                        : [const Color(0xFF1E3A5F), const Color(0xFF0C0F18)],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    draft?.mediaType == 'video' ? Icons.play_circle_fill_rounded : Icons.image_rounded,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 16,
                            child: Center(
                              child: Text(
                                coverLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: '请添加描述',
                      border: InputBorder.none,
                      counterText: '',
                      hintStyle: TextStyle(
                        color: Color(0xFFB0B6C3),
                        fontSize: 15,
                      ),
                    ),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E)),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      for (final chip in _chips)
                        _TagChip(label: chip, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Divider(height: 1, color: Color(0xFFF0F2F6)),
                  const SizedBox(height: 18),
                  const Text(
                    '发布设置',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)),
                  ),
                  const SizedBox(height: 18),
                  _SettingRow(
                    icon: Icons.location_on_outlined,
                    label: '添加地点',
                    value: '上海·桂林路',
                    onTap: () {},
                  ),
                  const SizedBox(height: 18),
                  _SettingRow(
                    icon: Icons.person_outline,
                    label: '谁可以看',
                    value: '互关可见',
                    onTap: () {},
                  ),
                  const SizedBox(height: 18),
                  _SettingRow(
                    icon: Icons.chat_bubble_outline,
                    label: '允许评论',
                    value: '所有人',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          side: const BorderSide(color: Color(0xFF1C1C1E), width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text(
                          '保存草稿',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text(
                          '发布帖子',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      backgroundColor: const Color(0xFFF4F6FA),
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF3A4459)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF1C1C1E)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E)),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 15, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFFB0B6C3)),
        ],
      ),
    );
  }
}
