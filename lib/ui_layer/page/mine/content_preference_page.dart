import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/page/mine/widgets/mine_settings_widgets.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';

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

  final _allInterests = [
    '摄影',
    '家居灵感',
    '职场成长',
    '科技数码',
    '电影解说',
    '艺术展览',
    '宠物日常',
    '旅行',
    '穿搭',
    '美食',
    '健身',
    '音乐',
    '游戏',
    '读书',
    '运动',
  ];

  final Set<String> _selectedInterests = {'旅行'};

  final List<String> _blockedKeywords = ['剧透', '极端饮食', '过度炫富'];

  final _keywordCtrl = TextEditingController();

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
      body: Column(
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
                    Spacer(),
                    Text(
                      'contentPrefSelectedCount'.tr(namedArgs: {'count': '${_selectedInterests.length}'}),
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
                  children: _allInterests.map((tag) {
                    final selected = _selectedInterests.contains(tag);
                    return _TagChip(
                      label: tag,
                      selected: selected,
                      onTap: () => _toggleInterest(tag),
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
                  Spacer(),
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
                  // 现有关键词
                  ..._blockedKeywords.map(
                    (kw) => _TagChip(
                      label: kw,
                      selected: false,
                      showClose: true,
                      onTap: () {},
                      onClose: () => setState(() => _blockedKeywords.remove(kw)),
                    ),
                  ),
                  // 添加按钮
                  GestureDetector(
                    onTap: _showAddKeywordSheet,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.w),
                      decoration: BoxDecoration(
                        color:  const Color(0xFFF8F9FE),
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
          )),
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

  void _toggleInterest(String tag) {
    setState(() {
      if (_selectedInterests.contains(tag)) {
        _selectedInterests.remove(tag);
      } else if (_selectedInterests.length < _maxInterests) {
        _selectedInterests.add(tag);
      }
    });
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

  void _submit() {
    Navigator.of(context).pop();
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
