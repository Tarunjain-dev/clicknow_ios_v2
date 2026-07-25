import 'dart:io';

import 'package:clicknow_version2/app/screens/common/support/models/support_models.dart';
import 'package:clicknow_version2/app/screens/common/support/screens/ticket_chat_screen.dart';
import 'package:clicknow_version2/app/screens/common/support/services/support_service.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RaiseTicketScreen extends StatefulWidget {
  const RaiseTicketScreen({
    super.key,
    required this.actor,
    this.initialCategory,
    this.initialSubject,
    this.relatedBookingId,
    this.relatedPaymentId,
    this.relatedRefundId,
    this.relatedPayrollId,
  });

  final SupportActor actor;
  final String? initialCategory;
  final String? initialSubject;
  final String? relatedBookingId;
  final String? relatedPaymentId;
  final String? relatedRefundId;
  final String? relatedPayrollId;

  @override
  State<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends State<RaiseTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  late final TextEditingController _subject;
  String? _category;
  File? _attachment;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _subject = TextEditingController(text: widget.initialSubject ?? '');
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1600,
    );
    if (picked != null && mounted) {
      setState(() => _attachment = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _category == null ||
        _submitting) {
      if (_category == null) {
        AppSnackbar.error(
          'Category Required',
          'Please select an issue category.',
        );
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      final id = await SupportService.instance.createTicket(
        actor: widget.actor,
        category: _category!,
        subject: _subject.text,
        description: _description.text,
        relatedBookingId: widget.relatedBookingId,
        relatedPaymentId: widget.relatedPaymentId,
        relatedRefundId: widget.relatedRefundId,
        relatedPayrollId: widget.relatedPayrollId,
        initialAttachment: _attachment,
      );
      if (!mounted) return;
      AppSnackbar.success('Ticket Raised', 'Your support ticket was created.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TicketChatScreen(ticketId: id, actor: widget.actor),
        ),
      );
    } catch (error) {
      AppSnackbar.error('Could Not Raise Ticket', _error(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFunctions.isDarkMode(context);
    final categories = widget.actor.role == 'professional'
        ? SupportValues.professionalCategories
        : SupportValues.customerCategories;
    final fill = isDark ? const Color(0xff19142D) : const Color(0xffF5F2F8);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xff0E0A18) : Colors.white,
      appBar: AppBar(
        title: const Text('Raise Support Ticket'),
        backgroundColor: isDark ? const Color(0xff171129) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: ResponsiveUtility.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: categories.contains(_category) ? _category : null,
              items: categories
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(SupportValues.label(value)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() => _category = value),
              decoration: _decoration('Issue category', fill),
              dropdownColor: isDark ? const Color(0xff19142D) : Colors.white,
            ),
            SizedBox(height: ResponsiveUtility.height(12)),
            TextFormField(
              controller: _subject,
              decoration: _decoration('Subject', fill),
              validator: (value) => (value?.trim().length ?? 0) < 5
                  ? 'Enter at least 5 characters'
                  : null,
            ),
            SizedBox(height: ResponsiveUtility.height(12)),
            TextFormField(
              controller: _description,
              minLines: 5,
              maxLines: 8,
              decoration: _decoration('Describe the issue in detail', fill),
              validator: (value) => (value?.trim().length ?? 0) < 15
                  ? 'Enter at least 15 characters'
                  : null,
            ),
            if (_relatedValues().isNotEmpty) ...[
              SizedBox(height: ResponsiveUtility.height(14)),
              _relatedCard(isDark),
            ],
            SizedBox(height: ResponsiveUtility.height(14)),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _attachment == null ? 'Attach image proof' : 'Change image',
              ),
            ),
            if (_attachment != null) ...[
              SizedBox(height: ResponsiveUtility.height(10)),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _attachment!,
                      height: ResponsiveUtility.height(180),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: IconButton.filled(
                      onPressed: () => setState(() => _attachment = null),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: ResponsiveUtility.height(22)),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4B075F),
                foregroundColor: Colors.white,
                minimumSize: Size(
                  double.infinity,
                  ResponsiveUtility.height(52),
                ),
              ),
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Ticket'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, Color fill) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: fill,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Map<String, String> _relatedValues() => <String, String>{
    if ((widget.relatedBookingId ?? '').isNotEmpty)
      'Booking': widget.relatedBookingId!,
    if ((widget.relatedPaymentId ?? '').isNotEmpty)
      'Payment': widget.relatedPaymentId!,
    if ((widget.relatedRefundId ?? '').isNotEmpty)
      'Refund': widget.relatedRefundId!,
    if ((widget.relatedPayrollId ?? '').isNotEmpty)
      'Payroll': widget.relatedPayrollId!,
  };

  Widget _relatedCard(bool isDark) => Container(
    padding: ResponsiveUtility.all(13),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xff19142D) : const Color(0xffF5F2F8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related records',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        ..._relatedValues().entries.map(
          (entry) => Text('${entry.key}: ${entry.value}'),
        ),
      ],
    ),
  );
}

String _error(Object error) =>
    error.toString().replaceFirst(RegExp(r'^(Bad state|StateError):\s*'), '');
