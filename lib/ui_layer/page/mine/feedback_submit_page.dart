import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../image_paths.dart';
import '../../widgets/my_image.dart';

// ──────────────────────────────────────────
// 页面
// ──────────────────────────────────────────
class FeedbackSubmitPage extends StatefulWidget {
  const FeedbackSubmitPage({super.key});

  @override
  State<FeedbackSubmitPage> createState() => _FeedbackSubmitPageState();
}

class _FeedbackSubmitPageState extends State<FeedbackSubmitPage> {
  final TextEditingController _descController = TextEditingController();
  final List<XFile> _images = [];
  bool _submitting = false;

  static const int _maxImages = 5;
  static const int _maxDescLength = 200;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 详细描述
                Text(
                  'complaintDetailTitle'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF45556C),
                  ),
                ),
                SizedBox(height: 10.w),
                _buildTextArea(),
                SizedBox(height: 19.h),
                // 图片材料
                Text(
                  'complaintImageTitle'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF45556C),
                  ),
                ),
                SizedBox(height: 10.h),
                _buildImagePicker(),
                SizedBox(height: 32.h),
              ],
            ),
          )),
          // 提交按钮
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE3E7ED)),
      ),
      padding: EdgeInsets.all(10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _descController,
            maxLines: 5,
            maxLength: _maxDescLength,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF1A1F2C)),
            decoration: InputDecoration(
              hintText: 'complaintDescHint'.tr(),
              hintStyle: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF90A1B9),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
          Text(
            '${_descController.text.length}/$_maxDescLength',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9099B9)),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            ..._images.asMap().entries.map((e) => _ImageTile(
                  file: e.value,
                  onRemove: () => _removeImage(e.key),
                )),
            if (_images.length < _maxImages)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FE),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFE3E7ED)),
                  ),
                  child: Align(
                    child: MyImage.asset(
                      MyImagePaths.iconUploadPlus,
                      width: 24.w,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          'complaintMaxImages'.tr(namedArgs: {'count': '$_maxImages'}),
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF90A1B9)),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
        child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: SizedBox(
        width: double.infinity,
        height: 50.w,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFF1A1F2C),
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: TextButton(
            onPressed: _submitting ? null : _submit,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            child: _submitting
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'complaintSubmit'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    ));
  }

  Future<void> _submit() async {}

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

  Future<void> _pickImage() async {
    if (_images.length >= _maxImages) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      setState(() => _images.add(file));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }
}

// ─── 已选图片缩略图 ──────────────────────────────────────────────────────────

class _ImageTile extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _ImageTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80.w,
      height: 80.w,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.file(
              File(file.path),
              width: 80.w,
              height: 80.w,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 2.w,
            right: 2.w,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20.w,
                height: 20.w,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 14.w, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
