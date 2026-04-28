import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class FeedbackSubmitPage extends StatefulWidget {
  const FeedbackSubmitPage({super.key});

  @override
  State<FeedbackSubmitPage> createState() => _FeedbackSubmitPageState();
}

class _FeedbackSubmitPageState extends State<FeedbackSubmitPage> {
  static const int _maxChars = 200;
  static const int _maxImages = 5;

  final _descCtrl = TextEditingController();
  final List<String> _imagePaths = [];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 12.w),
              children: [
                _buildDescSection(),
                SizedBox(height: 12.w),
                _buildImageSection(),
                SizedBox(height: 24.w),
              ],
            ),
          ),
          _buildSubmitButton(context),
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
        'feedbackSubmitTitle'.tr(),
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

  Widget _buildDescSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 8.w),
          child: Text(
            'feedbackDescHint'.tr(),
            style: TextStyle(
              color: const Color(0xFF45556C),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: EdgeInsets.all(16.w),
          child: Stack(
            children: [
              TextField(
                controller: _descCtrl,
                maxLength: _maxChars,
                maxLines: 6,
                style:
                    TextStyle(color: const Color(0xFF1A1F2C), fontSize: 14.sp),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'feedbackDescHint'.tr(),
                  hintStyle: TextStyle(
                    color: const Color(0xFF90A1B9),
                    fontSize: 14.sp,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.w),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                  contentPadding: EdgeInsets.fromLTRB(12.w, 12.w, 12.w, 32.w),
                ),
              ),
              Positioned(
                right: 12.w,
                bottom: 10.w,
                child: Text(
                  'feedbackCharCount'.tr(namedArgs: {
                    'count': '${_descCtrl.text.length}',
                    'max': '$_maxChars',
                  }),
                  style: TextStyle(
                    color: const Color(0xFF90A1B9),
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 8.w),
          child: Text(
            'feedbackMaxImages'.tr(namedArgs: {'max': '$_maxImages'}),
            style: TextStyle(
              color: const Color(0xFF45556C),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: EdgeInsets.all(16.w),
          child: Wrap(
            spacing: 10.w,
            runSpacing: 10.w,
            children: [
              // 已选图片占位
              ..._imagePaths.map((p) => _imageThumbnail(p)),
              // 添加按钮（未达上限时显示）
              if (_imagePaths.length < _maxImages)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 24.w, color: const Color(0xFF90A1B9)),
                        SizedBox(height: 4.w),
                        Text(
                          'feedbackMaxImages'
                              .tr(namedArgs: {'max': '$_maxImages'}),
                          style: TextStyle(
                              color: const Color(0xFF90A1B9), fontSize: 11.sp),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageThumbnail(String path) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.w),
          child: Container(
            width: 80.w,
            height: 80.w,
            color: const Color(0xFFE3E7EC),
          ),
        ),
        Positioned(
          top: 2.w,
          right: 2.w,
          child: GestureDetector(
            onTap: () => setState(() => _imagePaths.remove(path)),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 12.w, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16.w, 12.w, 16.w, 8.w),
        child: GestureDetector(
          onTap: _submit,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2C),
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Center(
              child: Text(
                'feedbackSubmitted'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pickImage() {
    // 实际需要调用 image_picker；此处仅示意添加占位路径
    setState(() => _imagePaths.add('placeholder_${_imagePaths.length}'));
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('feedbackSubmitted'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }
}
