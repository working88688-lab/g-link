import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:g_link/domain/domains/report.dart';
import 'package:g_link/domain/model/profile_models.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// 投诉 / 举报两步流程（设计稿 11.2 / 11.3）：
/// 1. 原因列表：`GET /api/v1/reports/types`
/// 2. 描述 + 证据图 + `POST /api/v1/reports`
class ComplaintPage extends StatefulWidget {
  const ComplaintPage({
    super.key,
    this.targetId,
    this.reportTarget = ReportTarget.user,
  });

  final int? targetId;
  final ReportTarget reportTarget;

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
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

  static const Color _divider = Color(0xFFEDEDED);
  static const Color _labelGray = Color(0xFF45556C);
  static const Color _hintGray = Color(0xFF90A1B9);
  static const Color _fieldBg = Color(0xFFF5F6F8);
  static const Color _fieldBorder = Color(0xFFE3E7ED);
  static const Color _submitBg = Color(0xFF1A1F2C);

  @override
  void initState() {
    super.initState();
    _loadReportTypes();
  }

  Future<void> _loadReportTypes() async {
    try {
      final types = await context.read<ReportDomain>().getReportTypes();
      if (!mounted) return;
      setState(() {
        _reportTypes = types;
        _loadingTypes = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTypes = false;
        _loadError = 'complaintLoadTypesFailed'.tr();
      });
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
    if (id <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('complaintInvalidTarget'.tr())),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
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
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28.sp),
          onPressed: _onBack,
          padding: EdgeInsets.zero,
        ),
        title: Text(
          'complaintTitle'.tr(),
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _step == 0
            ? _buildReasonStep(key: const ValueKey('step0'))
            : _buildDetailStep(key: const ValueKey('step1')),
      ),
    );
  }

  Widget _buildReasonStep({Key? key}) {
    if (_loadingTypes) {
      return Center(
        key: const ValueKey('loading'),
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_loadError != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFFE53935), fontSize: 14.sp),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () {
                  setState(() {
                    _loadingTypes = true;
                    _loadError = null;
                  });
                  _loadReportTypes();
                },
                child: Text('commonRetry'.tr()),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Text(
            'complaintSelectReason'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: _labelGray,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const ClampingScrollPhysics(),
            itemCount: _reportTypes.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: _divider,
            ),
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

  Widget _buildDetailStep({Key? key}) {
    return Column(
      key: key,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedType?.name ?? '',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: const Color(0xFF1A1F2C),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'complaintDetailTitle'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: _labelGray,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 10.h),
                _buildTextArea(),
                SizedBox(height: 20.h),
                Text(
                  'complaintImageTitle'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: _labelGray,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 10.h),
                _buildImagePicker(),
              ],
            ),
          ),
        ),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildTextArea() {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _fieldBorder),
      ),
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _descController,
            maxLines: 5,
            minLines: 5,
            maxLength: _maxDescLength,
            buildCounter: (_,
                    {required currentLength, required isFocused, maxLength}) =>
                null,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF1A1F2C)),
            decoration: InputDecoration(
              hintText: 'complaintDescHint'.tr(),
              hintStyle: TextStyle(
                fontSize: 14.sp,
                color: _hintGray,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
          Text(
            '${_descController.text.length}/$_maxDescLength',
            style: TextStyle(fontSize: 12.sp, color: _hintGray),
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Ink(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: _fieldBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: _fieldBorder),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 32.sp,
                      color: const Color(0xFFB8C0CC),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          'complaintMaxImages'.tr(namedArgs: {'count': '$_maxImages'}),
          style: TextStyle(fontSize: 13.sp, color: _hintGray),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        child: SizedBox(
          width: double.infinity,
          height: 48.w,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _submitBg,
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
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'complaintSubmit'.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonItem extends StatelessWidget {
  const _ReasonItem({required this.reason, required this.onTap});

  final String reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 14.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1F2C),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22.sp,
              color: const Color(0xFFC4CAD4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80.w,
      height: 80.w,
      child: Stack(
        clipBehavior: Clip.none,
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
            top: -4.w,
            right: -4.w,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: const BoxDecoration(
                  color: Color(0xCC000000),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, size: 14.sp, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
