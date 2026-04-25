import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../image_paths.dart';
import '../../theme.dart';
import '../../widgets/my_app_bar.dart';

/// 投诉原因列表
const _complaintReasons = [
  '虚假信息',
  '暴力、仇恨、血腥',
  '骚扰或辱骂',
  '色情或成人内容',
  '诈骗或欺诈',
  '侵犯隐私',
  '其他',
];

class ComplaintPage extends StatefulWidget {
  /// 被投诉的用户 ID，可选
  final String? targetUserId;

  const ComplaintPage({super.key, this.targetUserId});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  /// 当前步骤：0 = 选择原因，1 = 填写详情
  int _step = 0;

  String? _selectedReason;
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

  void _onReasonTap(String reason) {
    setState(() {
      _selectedReason = reason;
      _step = 1;
    });
  }

  void _onBack() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    // TODO: 接入实际的投诉提交 API
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('投诉已提交，我们将尽快处理')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        titleWidget: Text(
          '投诉',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF1D293D), fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        backArrowOnTap: _onBack,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _step == 0
            ? _buildReasonStep(key: const ValueKey('step0'))
            : _buildDetailStep(key: const ValueKey('step1')),
      ),
    );
  }

  // ─── 第一步：选择原因 ───────────────────────────────────────────────────────

  Widget _buildReasonStep({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.w, bottom: 8.w),
            child: Text(
              '请选择投诉该账号的原因',
              style: TextStyle(
                fontSize: 14.17.sp,
                color: const Color(0xFF62748E),
              ),
            )),
        Expanded(
          child: ListView.separated(
            itemCount: _complaintReasons.length,
            separatorBuilder: (_, __) => SizedBox(
              height: 0.w,
            ),
            itemBuilder: (context, index) {
              final reason = _complaintReasons[index];
              return _ReasonItem(
                reason: reason,
                onTap: () => _onReasonTap(reason),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── 第二步：填写详情 ───────────────────────────────────────────────────────

  Widget _buildDetailStep({Key? key}) {
    return Column(
      children: [
        Expanded(
            child: SingleChildScrollView(
          key: key,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 19.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 已选原因标签
              Text(
                _selectedReason ?? '',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: const Color(0xFF1A1F2C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.w),
              // 详细描述
              Text(
                '详细描述',
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
                '图片材料',
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
              hintText: '请描述具体原因',
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
          '最多可上传$_maxImages张',
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
                    '提交',
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
}

// ─── 投诉原因列表项 ──────────────────────────────────────────────────────────

class _ReasonItem extends StatelessWidget {
  final String reason;
  final VoidCallback onTap;

  const _ReasonItem({required this.reason, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              reason,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1F2C),
              ),
            ),
            MyImage.asset(
              MyImagePaths.iconArrowRight,
              width: 16.19.w,
            ),
          ],
        ),
      ),
    );
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
