import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/page/mine/widgets/mine_settings_widgets.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:provider/provider.dart';

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class ContentPreferencePage extends StatefulWidget {
  const ContentPreferencePage({super.key});

  @override
  State<ContentPreferencePage> createState() => _ContentPreferencePageState();
}

class _ContentPreferencePageState extends State<ContentPreferencePage> {
  static const int _maxInterests = 8;

  final Set<int> _selectedTagIds = {};
  final List<String> _blockedKeywords = [];
  final Set<String> _initialBlockedKeywords = {};
  final TextEditingController _keywordCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<InterestTag> _interestTags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.all(16.w),
                        children: [
                          _buildInterestsSection(),
                          SizedBox(height: 12.w),
                          _buildBlockKeywordsSection(),
                        ],
                      ),
                    ),
                    _buildSubmitButton(),
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
        'contentPrefTitle'.tr(),
        style: TextStyle(
          color: const Color(0xFF1D293D),
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEDF0F5)),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return MineSetingsWidgets.buildCard(
        children: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'contentPrefInterestTitle'.tr(),
                      style: TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'contentPrefSelectedCount'.tr(namedArgs: {'count': '${_selectedTagIds.length}'}),
                      style: TextStyle(
                        color: const Color(0xFF45556C),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'contentPrefInterestDesc'.tr(namedArgs: {'max': '$_maxInterests'}),
                        style: TextStyle(
                          color: const Color(0xFF45556C),
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 19.w),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 12.w,
                  children: _interestTags.map((tag) {
                    final selected = _selectedTagIds.contains(tag.id);
                    return _TagChip(
                      label: tag.name,
                      selected: selected,
                      onTap: () => _toggleInterest(tag.id),
                    );
                  }).toList(),
                ),
              ],
            )));
  }

  Widget _buildBlockKeywordsSection() {
    return MineSetingsWidgets.buildCard(
      children: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'contentPrefBlockTitle'.tr(),
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'contentPrefBlockCount'.tr(namedArgs: {'count': '${_blockedKeywords.length}'}),
                  style: TextStyle(
                    color: const Color(0xFF45556C),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              'contentPrefBlockDesc'.tr(),
              style: TextStyle(
                color: const Color(0xFF45556C),
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 19.w),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.w,
              children: [
                ..._blockedKeywords.map(
                  (kw) => _TagChip(
                    label: kw,
                    selected: false,
                    showClose: true,
                    onTap: () {},
                    onClose: () => setState(() => _blockedKeywords.remove(kw)),
                  ),
                ),
                GestureDetector(
                  onTap: _showAddKeywordSheet,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(18.w),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyImage.asset(
                          MyImagePaths.iconPlus,
                          width: 20.w,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'contentPrefAddKeyword'.tr(),
                          style: TextStyle(
                            color: const Color(0xFF1A1F2C),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 16.w),
        child: Column(
          children: [
            Text(
              'contentPrefFooter'.tr(),
              style: TextStyle(
                color: const Color(0xFF62748E),
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.w),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2C),
                  borderRadius: BorderRadius.circular(29.w),
                ),
                child: Center(
                  child: Text(
                    'complaintSubmit'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _toggleInterest(int tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else if (_selectedTagIds.length < _maxInterests) {
        _selectedTagIds.add(tagId);
      }
    });
  }

  Future<void> _loadTags() async {
    try {
      final profile = context.read<ProfileDomain>();
      final tagsResult = await profile.getInterestTags();
      final blockedResult = await profile.getBlockedKeywords();
      final tags = tagsResult.data ?? const <InterestTag>[];
      final blocked = blockedResult.data ?? const <String>[];
      if (!mounted) return;
      setState(() {
        _interestTags = tags;
        _selectedTagIds
          ..clear()
          ..addAll(tags.where((e) => e.isSelected).map((e) => e.id));
        _blockedKeywords
          ..clear()
          ..addAll(blocked);
        _initialBlockedKeywords
          ..clear()
          ..addAll(blocked);
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
        _loading = false;
      });
    }
  }

  void _showAddKeywordSheet() {
    _keywordCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.w)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keywordCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'contentPrefAddKeyword'.tr(),
                      hintStyle: TextStyle(color: const Color(0xFF90A1B9), fontSize: 14.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.w),
                        borderSide: BorderSide(color: const Color(0xFFE3E7EC)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                TextButton(
                  onPressed: () {
                    final kw = _keywordCtrl.text.trim();
                    if (kw.isNotEmpty && !_blockedKeywords.contains(kw)) {
                      setState(() => _blockedKeywords.add(kw));
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: Text('commonConfirm'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    try {
      final profile = context.read<ProfileDomain>();
      await profile.updateMyInterestTags(tagIds: _selectedTagIds.toList());

      final added = _blockedKeywords.where((kw) => !_initialBlockedKeywords.contains(kw)).toList();
      final removed = _initialBlockedKeywords.where((kw) => !_blockedKeywords.contains(kw)).toList();
      for (final kw in added) {
        await profile.addBlockedKeyword(keyword: kw);
      }
      for (final kw in removed) {
        await profile.deleteBlockedKeyword(keyword: kw);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
      });
    }
  }
}

// ──────────────────────────────────────────
// 标签 chip
// ──────────────────────────────────────────
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showClose = false,
    this.onClose,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1F2C) : const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(18.w),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFFF8F9FE) : const Color(0xFF1A1F2C),
                fontSize: 12.sp,
              ),
            ),
            if (showClose) ...[
              SizedBox(width: 4.w),
              GestureDetector(
                onTap: onClose,
                child: MyImage.asset(
                  MyImagePaths.iconClose,
                  width: 16.w,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
