import 'dart:io';
import 'dart:typed_data';

import 'package:clicknow_version2/app/services/pdf/models/professional_payroll_pdf_data.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_file_service.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_formatters.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ProfessionalPayrollPdfService {
  ProfessionalPayrollPdfService._();

  static Future<Uint8List> generate(ProfessionalPayrollPdfData data) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => <pw.Widget>[
          _header(data),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(child: _paidTo(data)),
              pw.SizedBox(width: 14),
              pw.Expanded(child: _slipDetails(data)),
            ],
          ),
          pw.SizedBox(height: 12),
          _bookingDetails(data),
          pw.SizedBox(height: 12),
          _earningsTable(data),
          pw.SizedBox(height: 12),
          _payoutDetails(data),
          pw.SizedBox(height: 12),
          _keyValueSection('ClickNow Bank Details', <String, String>{
            'Bank Details': PdfFormatters.safeText(data.bankDetails),
          }),
          pw.SizedBox(height: 12),
          _declaration(),
          pw.SizedBox(height: 18),
          _signature(),
        ],
      ),
    );
    return document.save();
  }

  static Future<File> generateAndSave(ProfessionalPayrollPdfData data) async {
    final bytes = await generate(data);
    return PdfFileService.savePdf(
      bytes: bytes,
      fileName:
          'ClickNow_Payroll_${PdfFormatters.safeFileName(data.payrollId)}.pdf',
    );
  }

  static Future<void> share(ProfessionalPayrollPdfData data) async {
    final file = await generateAndSave(data);
    await PdfFileService.sharePdf(
      file,
      subject: 'ClickNow Payroll Slip ${data.payrollId}',
      text: 'Payroll slip for booking ${data.bookingId}',
    );
  }

  static Future<void> open(ProfessionalPayrollPdfData data) async {
    final file = await generateAndSave(data);
    await PdfFileService.openPdf(file);
  }

  static pw.Widget _header(ProfessionalPayrollPdfData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Container(
          width: 84,
          height: 54,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#23043E'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'ClickNow',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(data.companyName, style: _bold(16)),
              pw.Text(data.companyAddress, style: _muted()),
              pw.Text('GSTIN: ${PdfFormatters.safeText(data.companyGstin)}', style: _muted()),
              pw.Text('${data.companyEmail} | ${data.companyPhone}', style: _muted()),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: <pw.Widget>[
            pw.Text(
              'FREELANCER PAYMENT SLIP',
              textAlign: pw.TextAlign.right,
              style: _bold(17, PdfColor.fromHex('#23043E')),
            ),
            pw.Text(data.payoutStatus, style: _bold(11)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _paidTo(ProfessionalPayrollPdfData data) {
    return _keyValueSection('Professional Details', <String, String>{
      'Professional Name': data.professionalName,
      'Freelancer ID': data.professionalId,
      'Phone': data.professionalPhone,
      'Email': PdfFormatters.safeText(data.professionalEmail),
    });
  }

  static pw.Widget _slipDetails(ProfessionalPayrollPdfData data) {
    return _keyValueSection('Payment Slip Details', <String, String>{
      'Slip No.': data.payrollId,
      'Date': PdfFormatters.formatDate(data.generatedAt),
      'Payment Date': PdfFormatters.formatDateTime(data.releasedAt),
      'Amount Paid': PdfFormatters.formatCurrency(data.netPayoutAmount),
      'Payment Mode': PdfFormatters.safeText(data.paymentMode),
      'GST Status': PdfFormatters.safeText(data.gstStatus),
    });
  }

  static pw.Widget _bookingDetails(ProfessionalPayrollPdfData data) {
    return _keyValueSection('Booking / Service Details', <String, String>{
      'Booking ID': data.bookingId,
      'Service Category': data.serviceName,
      'Event Type': data.eventType,
      'Plan': data.planName,
      'Event Date': PdfFormatters.formatDateTime(data.eventDateTime),
      'Customer Name': PdfFormatters.safeText(data.customerName),
      'Venue': PdfFormatters.safeText(data.venueAddress ?? data.venueName),
    });
  }

  static pw.Widget _payoutDetails(ProfessionalPayrollPdfData data) {
    return _keyValueSection('Payout Details', <String, String>{
      'Payout Status': data.payoutStatus,
      'Released By': PdfFormatters.safeText(data.releasedBy),
      'Transaction ID / UTR': PdfFormatters.safeText(data.transactionReference),
      'Professional Confirmation': PdfFormatters.safeText(data.professionalConfirmationStatus),
      'Scan for Payment Details': data.transactionReference == null
          ? 'Not available'
          : 'QR payload can use transaction ${data.transactionReference}',
    });
  }

  static pw.Widget _earningsTable(ProfessionalPayrollPdfData data) {
    final rows = <List<String>>[
      <String>[
        'Released Payout Amount',
        PdfFormatters.formatCurrency(data.netPayoutAmount),
      ],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1),
      },
      children: <pw.TableRow>[
        _tableRow(const <String>['Description', 'Amount'], header: true),
        ...rows.map(_tableRow),
      ],
    );
  }

  static pw.Widget _declaration() {
    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text('Declaration', style: _bold(12)),
          pw.SizedBox(height: 5),
          pw.Text(
            'Payment has been processed towards freelance professional services provided to ClickNow.',
            style: _body(),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'This is a system-generated payment slip and does not require a physical signature. Thank you for your valuable association with ClickNow.',
            style: _body(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signature() {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: <pw.Widget>[
          pw.Container(width: 150, height: 1, color: PdfColors.grey500),
          pw.SizedBox(height: 5),
          pw.Text('Authorized Signatory', style: _bold(10)),
          pw.Text('ClickNow', style: _muted()),
        ],
      ),
    );
  }

  static pw.TableRow _tableRow(List<String> cells, {bool header = false}) {
    return pw.TableRow(
      decoration: header ? pw.BoxDecoration(color: PdfColor.fromHex('#F1E7F8')) : null,
      children: cells
          .map(
            (cell) => pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(cell, style: header ? _bold(10) : _body(10)),
            ),
          )
          .toList(growable: false),
    );
  }

  static pw.Widget _keyValueSection(String title, Map<String, String> values) {
    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(title, style: _bold(12)),
          pw.SizedBox(height: 6),
          ...values.entries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.SizedBox(width: 126, child: pw.Text(entry.key, style: _muted())),
                  pw.Expanded(child: pw.Text(entry.value, style: _body())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _card(pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.7),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Expanded(
          child: pw.Text(
            'System-generated payment slip. No physical signature required. Thank you for your valuable association with ClickNow.',
            style: _muted(8),
          ),
        ),
        pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: _muted(8)),
      ],
    );
  }

  static pw.TextStyle _bold([double size = 10, PdfColor? color]) {
    return pw.TextStyle(
      fontSize: size,
      fontWeight: pw.FontWeight.bold,
      color: color ?? PdfColors.black,
    );
  }

  static pw.TextStyle _body([double size = 10]) => pw.TextStyle(fontSize: size);

  static pw.TextStyle _muted([double size = 9]) {
    return pw.TextStyle(fontSize: size, color: PdfColors.grey700);
  }
}
