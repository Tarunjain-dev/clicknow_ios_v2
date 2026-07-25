import 'package:clicknow_version2/app/screens/customer/profile/getx/customer_profile_controller.dart';
import 'package:clicknow_version2/app/screens/common/pdf/pdf_preview_screen.dart';
import 'package:clicknow_version2/app/services/pdf/customer_invoice_pdf_service.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_data_builder.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_formatters.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InvoiceHistoryScreen extends StatelessWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Scaling Utility instance
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    /// -- Customer profile controller instance
    final controller = CustomerProfileController.instance;

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color:  isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  scale.getScaledWidth(10),
                  scale.getScaledHeight(10),
                  scale.getScaledWidth(12),
                  scale.getScaledHeight(8),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: Get.back,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.black),
                      ),
                    ),
                    SizedBox(width: scale.getScaledWidth(6)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice history',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveUtility.fontSize(18),
                            ),
                          ),
                          Obx(
                            () => Text(
                              'Total spent: Rs.${_formatAmount(controller.totalInvoiceAmount)}',
                              style: TextStyle(
                                color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                                fontSize: ResponsiveUtility.fontSize(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: isDark  ? Color(0xFF2A3363) : Color(0xFFD9D9D9)),
              Expanded(
                child: Obx(() {
                  if (controller.invoices.isEmpty) {
                    return Center(
                      child: Text(
                        'No invoices available.',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.75),
                          fontSize: ResponsiveUtility.fontSize(14),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      scale.getScaledWidth(12),
                      scale.getScaledHeight(10),
                      scale.getScaledWidth(12),
                      scale.getScaledHeight(12),
                    ),
                    itemCount: controller.invoices.length,
                    separatorBuilder: (context, separatorIndex) => SizedBox(height: scale.getScaledHeight(8)),
                    itemBuilder: (_, index) {
                      final invoice = controller.invoices[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF151233).withValues(alpha: 0.95) : Color(0xFFFCFBFF).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? Color(0xFF2A3363) : Color(0xFFD9D9D9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                scale.getScaledWidth(8),
                                scale.getScaledHeight(10),
                                scale.getScaledWidth(8),
                                scale.getScaledHeight(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: scale.getScaledWidth(20),
                                    height: scale.getScaledHeight(20),
                                    decoration: BoxDecoration(
                                      color: isDark ? Color(0xFF2E315E) : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: isDark ? Color(0xFF4F86FF) : AppColors.black.withValues(alpha: 0.4),
                                      size: scale.getScaledWidth(12),
                                    ),
                                  ),
                                  SizedBox(width: scale.getScaledWidth(8)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          invoice.serviceName,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : AppColors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: ResponsiveUtility.fontSize(16),
                                          ),
                                        ),
                                        SizedBox(height: scale.getScaledHeight(2)),
                                        _point(scale, 'Event : ${invoice.eventName}', isDark),
                                        _point(scale, 'Date: ${invoice.date}', isDark),
                                        _point(scale, 'Invoice : ${invoice.id}', isDark),
                                        _point(scale, 'Booking ID : ${invoice.bookingId}', isDark),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 1,
                              color: isDark ? Color(0xFF2A3363).withValues(alpha: 0.8) : Color(0xFFD9D9D9).withValues(alpha: 0.8),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                scale.getScaledWidth(10),
                                scale.getScaledHeight(8),
                                scale.getScaledWidth(8),
                                scale.getScaledHeight(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Total Amount : Rs.${_formatAmount(invoice.totalAmount)}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white.withValues(alpha: 0.95) : Colors.black.withValues(alpha: 0.95),
                                        fontSize: ResponsiveUtility.fontSize(12),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: scale.getScaledHeight(28),
                                    child: OutlinedButton(
                                      onPressed: () => _openInvoice(
                                        context,
                                        invoice,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF38416C)),
                                        foregroundColor: isDark ? Colors.white : AppColors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: Text(
                                        'View PDF',
                                        style: TextStyle(
                                          fontSize: scale.getScaledFont(12),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _point(ScalingUtility scale, String text, bool isDark) {
    return Text(
      '- $text',
      style: TextStyle(
        color: isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black.withValues(alpha: 0.65),
        fontSize: ResponsiveUtility.fontSize(12),
      ),
    );
  }

  String _formatAmount(int amount) {
    final text = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final indexFromEnd = text.length - i;
      buffer.write(text[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  Future<void> _openInvoice(
    BuildContext context,
    CustomerInvoiceItem invoice,
  ) async {
    try {
      final data = await PdfDataBuilder.instance.customerInvoiceForBooking(
        bookingId: invoice.bookingId,
      );
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfPreviewScreen(
            title: 'Invoice ${data.invoiceNumber}',
            fileName:
                'ClickNow_Invoice_${PdfFormatters.safeFileName(data.invoiceNumber)}.pdf',
            buildPdf: () => CustomerInvoicePdfService.generate(data),
          ),
        ),
      );
    } catch (_) {
      AppSnackbar.error('Invoice Failed', 'Unable to generate invoice PDF.');
    }
  }
}

