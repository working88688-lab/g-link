import 'package:easy_localization/easy_localization.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/report.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:g_link/ui_layer/widgets/my_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../image_paths.dart';
import '../../widgets/my_app_bar.dart';

class ComplaintPage extends StatefulWidget {
  final int? targetId;
  final ReportTarget reportTarget;

  const ComplaintPage({
    super.key,
    this.targetId,
    this.reportTarget = ReportTarget.user,
  });

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  /// 当前步骤：0 = 选择原因，1 = 填写详情
  int _step = 0;

  ReportTypeItem? _selectedType;
  List<ReportTypeItem> _reportTypes = [];
  bool _loadingTypes = true;
  String? _loadError;

  final TextEditingController _descController = TextEditingController();
  final List<XFile> _images = [];
  bool _submitting = false;

  static const int _maxImages = 5;
  static const int _maxDescLength = 200;

  @override
  void initState() {
    super.initState();
    _loadReportTypes();
  }

  Future<void> _loadReportTypes() async {
    try {
      final types = await context.read<ReportDomain>().getReportTypes();
      if (mounted) {
        setState(() {
          _reportTypes = types;
          _loadingTypes = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingTypes = false;
          _loadError = 'complaintLoadTypesFailed'.tr();
        });
      }
    }
  }

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

  void _onReasonTap(ReportTypeItem type) {
    setState(() {
      _selectedType = type;
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
    final id = widget.targetId;
    final type = _selectedType;
    if (id == null || type == null) return;

    setState(() => _submitting = true);
    try {
      // 上传图片，收集 download_url
      final List<String> evidenceUrls = [];
      final domain = context.read<ReportDomain>();
      for (final img in _images) {
        final url = await domain.uploadReportEvidence(img.path);
        evidenceUrls.add(url);
      }

      await domain.submitReport(
        target: widget.reportTarget,
        targetId: id,
        reasonType: type.id,
        reasonDetail: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        evidenceUrls: evidenceUrls,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('complaintSubmitted'.tr())),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('complaintSubmitFailed'.tr())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        titleWidget: Text(
          'complaintTitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Color(0xFF1D293D),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600),
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
    if (_loadingTypes) {
      return const Center(
          key: ValueKey('loading'), child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        key: ValueKey('error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!,
                style: TextStyle(color: Colors.red, fontSize: 14.sp)),
            SizedBox(height: 12.h),
            TextButton(
                onPressed: () {
                  setState(() {
                    _loadingTypes = true;
                    _loadError = null;
                  });
                  _loadReportTypes();
                },
                child: Text('retry'.tr())),
          ],
        ),
      );
    }
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: EdgeInsets.only(
                left: 16.w, right: 16.w, top: 16.w, bottom: 8.w),
            child: Text(
              'complaintSelectReason'.tr(),
              style: TextStyle(
                fontSize: 14.17.sp,
                color: const Color(0xFF62748E),
              ),
            )),
        Expanded(
          child: ListView.separated(
            itemCount: _reportTypes.length,
            separatorBuilder: (_, __) => SizedBox(height: 0.w),
            itemBuilder: (context, index) {
              final type = _reportTypes[index];
              return _ReasonItem(
                reason: type.name,
                onTap: () => _onReasonTap(type),
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
                _selectedType?.name ?? '',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: const Color(0xFF1A1F2C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.w),
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
            buildCounter: (_,
                    {required currentLength, required isFocused, maxLength}) =>
                null,
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
