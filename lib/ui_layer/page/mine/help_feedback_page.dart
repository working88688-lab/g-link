import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/profile.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/image_paths.dart';
import 'package:g_link/ui_layer/page/mine/feedback_submit_page.dart';
import 'package:g_link/ui_layer/page/mine/widgets/mine_settings_widgets.dart';
import 'package:g_link/ui_layer/router/routes.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:provider/provider.dart';

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  bool _loading = true;
  String? _error;
  List<FaqCategoryItem> _faqCategories = [];
  int? _expandedFaqId;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
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
              : ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    ..._faqCategories.map((category) => _buildSection(context, category: category)),
                    SizedBox(height: 12.w),
                    _buildFeedbackEntry(context),
                    SizedBox(height: 24.w),
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
        'helpFeedbackTitle'.tr(),
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

  Widget _buildSection(BuildContext context, {required FaqCategoryItem category}) {
    final title = _categoryLabel(category.category).tr();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF45556C),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.w),
        Column(
          children: List.generate(category.items.length, (i) {
            final item = category.items[i];
            final expanded = _expandedFaqId == item.id;
            return Column(
              children: [
                _FaqTile(
                  title: item.question,
                  expanded: expanded,
                  onTap: () {
                    setState(() {
                      _expandedFaqId = expanded ? null : item.id;
                    });
                  },
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 6.w),
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Text(
                      item.answer,
                      style: TextStyle(
                        color: const Color(0xFF45556C),
                        fontSize: 12.sp,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                if (i < category.items.length - 1) SizedBox(height: 6.w),
              ],
            );
          }),
        ),
        SizedBox(height: 16.w),
      ],
    );
  }

  Widget _buildFeedbackEntry(BuildContext context) {
    return MineSetingsWidgets.buildCard(
      children: InkWell(
        onTap: () => FeedbackSubmitRoute().push(context),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'helpFeedbackSubmit'.tr(),
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              MyImage.asset(
                MyImagePaths.iconArrowRightBlack,
                width: 20.w,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadFaqs() async {
    try {
      final categories = await context.read<ProfileDomain>().getFaqCategories();
      if (!mounted) return;
      setState(() {
        _faqCategories = categories.data ?? const [];
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

  String _categoryLabel(String category) {
    switch (category) {
      case 'account':
        return 'helpFeedbackFaqCategoryAccount';
      case 'content':
        return 'helpFeedbackFaqCategoryContent';
      case 'safety':
        return 'helpFeedbackFaqCategorySafety';
      default:
        return 'helpFeedbackFaqCategoryOther';
    }
  }
}

// ──────────────────────────────────────────
// FAQ 列表项
// ──────────────────────────────────────────
class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.title, required this.expanded, required this.onTap});

  final String title;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.w),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: MyImage.asset(
                MyImagePaths.iconArrowRightBlack,
                width: 20.w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
