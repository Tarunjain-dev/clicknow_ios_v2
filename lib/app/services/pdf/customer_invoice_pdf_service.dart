import 'dart:io';
import 'dart:typed_data';

import 'package:clicknow_version2/app/services/pdf/models/customer_invoice_pdf_data.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_file_service.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_formatters.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CustomerInvoicePdfService {
  CustomerInvoicePdfService._();

  static Future<Uint8List> generate(CustomerInvoicePdfData data) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => <pw.Widget>[
          _header(data),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(child: _billTo(data)),
              pw.SizedBox(width: 14),
              pw.Expanded(child: _invoiceInfo(data)),
            ],
          ),
          pw.SizedBox(height: 12),
          _bookingDetails(data),
          pw.SizedBox(height: 12),
          _itemsTable(data),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(child: _paymentReceived(data)),
              pw.SizedBox(width: 14),
              pw.Container(width: 230, child: _totals(data)),
            ],
          ),
          pw.SizedBox(height: 12),
          _keyValueSection('UPI / Bank Details', <String, String>{
            'UPI ID': PdfFormatters.safeText(data.upiId),
            'Scan & Pay UPI QR': 'Available when provided in payment records.',
            'Bank Details': PdfFormatters.safeText(
              data.bankDetails,
              fallback: 'Bank details will be updated soon.',
            ),
          }),
          pw.SizedBox(height: 12),
          _terms(data),
        ],
      ),
    );
    return document.save();
  }

  static Future<File> generateAndSave(CustomerInvoicePdfData data) async {
    final bytes = await generate(data);
    return PdfFileService.savePdf(
      bytes: bytes,
      fileName:
          'ClickNow_Invoice_${PdfFormatters.safeFileName(data.invoiceNumber)}.pdf',
    );
  }

  static Future<void> share(CustomerInvoicePdfData data) async {
    final file = await generateAndSave(data);
    await PdfFileService.sharePdf(
      file,
      subject: 'ClickNow Invoice ${data.invoiceNumber}',
      text: 'Invoice for booking ${data.bookingId}',
    );
  }

  static Future<void> open(CustomerInvoicePdfData data) async {
    final file = await generateAndSave(data);
    await PdfFileService.openPdf(file);
  }

  static pw.Widget _header(CustomerInvoicePdfData data) {
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
              pw.Text('Event Professionals Booking Application', style: _muted()),
              pw.Text(data.companyAddress, style: _muted()),
              pw.Text('${data.companyPhone} | ${data.companyEmail}', style: _muted()),
              pw.Text(PdfFormatters.safeText(data.companyWebsite), style: _muted()),
              pw.Text('GSTIN: ${PdfFormatters.safeText(data.companyGstin)}', style: _muted()),
            ],
          ),
        ),
        pw.SizedBox(
          width: 155,
          child: pw.Text(
            'TAX INVOICE / PAYMENT RECEIPT',
            textAlign: pw.TextAlign.right,
            style: _bold(17, PdfColor.fromHex('#23043E')),
          ),
        ),
      ],
    );
  }

  static pw.Widget _billTo(CustomerInvoicePdfData data) {
    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text('Bill To', style: _bold(12)),
          pw.SizedBox(height: 6),
          pw.Text(data.customerName, style: _body()),
          if ((data.customerBusinessName ?? '').trim().isNotEmpty)
            pw.Text(data.customerBusinessName!, style: _body()),
          pw.Text('Phone: ${PdfFormatters.safeText(data.customerPhone)}', style: _body()),
          pw.Text('Email: ${PdfFormatters.safeText(data.customerEmail)}', style: _body()),
          pw.Text('Address: ${PdfFormatters.safeText(data.customerAddress)}', style: _body()),
          pw.Text('Customer GSTIN: ${PdfFormatters.safeText(data.customerGstin)}', style: _body()),
        ],
      ),
    );
  }

  static pw.Widget _invoiceInfo(CustomerInvoicePdfData data) {
    return _keyValueSection('Invoice Info', <String, String>{
      'Invoice No.': data.invoiceNumber,
      'Invoice Date': PdfFormatters.formatDate(data.invoiceDate),
      'Booking No.': data.bookingId,
      'Place of Supply': PdfFormatters.safeText(data.placeOfSupply),
    });
  }

  static pw.Widget _bookingDetails(CustomerInvoicePdfData data) {
    return _keyValueSection('Partnership / Booking Details', <String, String>{
      'Booking For': data.serviceName,
      'Event / Service Type': data.eventType,
      'Plan': data.planName,
      'Event Date': PdfFormatters.formatDateTime(data.eventDateTime),
      'Event Location': PdfFormatters.safeText(data.venueAddress),
      'Booking Reference': data.bookingId,
      'Payment Mode': _paymentOption(data.paymentOption),
    });
  }

  static pw.Widget _paymentReceived(CustomerInvoicePdfData data) {
    return _keyValueSection('Payment Received', <String, String>{
      'Amount Received': PdfFormatters.formatCurrency(data.paidAmount),
      'Transaction ID / UTR': PdfFormatters.safeText(data.transactionId),
      'Payment ID': PdfFormatters.safeText(data.paymentId),
      'Payment Date': PdfFormatters.formatDateTime(data.paymentDate),
      'Payment Status': data.paymentStatus,
      'Payment Mode': PdfFormatters.safeText(data.paymentMode),
    });
  }

  static pw.Widget _itemsTable(CustomerInvoicePdfData data) {
    final rows = data.items.asMap().entries.map((entry) {
      final item = entry.value;
      return <String>[
        '${entry.key + 1}',
        '${item.itemName}\n${item.description}',
        item.sacCode,
        '${item.quantity}',
        PdfFormatters.formatCurrency(item.unitPrice),
        PdfFormatters.formatCurrency(item.amount),
      ];
    }).toList(growable: false);
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FixedColumnWidth(32),
        1: pw.FlexColumnWidth(2.6),
        2: pw.FixedColumnWidth(50),
        3: pw.FixedColumnWidth(32),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(1.1),
      },
      children: <pw.TableRow>[
        _tableRow(
          const <String>[
            'Sr.',
            'Description of Services',
            'SAC Code',
            'Qty.',
            'Unit Price',
            'Amount',
          ],
          header: true,
        ),
        ...rows.map(_tableRow),
      ],
    );
  }

  static pw.Widget _totals(CustomerInvoicePdfData data) {
    return _card(
      pw.Column(
        children: <pw.Widget>[
          _totalRow('Subtotal', data.subtotal),
          if (data.discountAmount > 0) _totalRow('Discount', -data.discountAmount),
          if ((data.couponCode ?? '').trim().isNotEmpty)
            _plainRow('Coupon Code', data.couponCode!),
          _totalRow('Taxable Amount', data.taxableAmount),
          _totalRow('CGST 9%', data.cgstAmount),
          _totalRow('SGST 9%', data.sgstAmount),
          if (data.igstAmount > 0) _totalRow('IGST', data.igstAmount),
          pw.Divider(color: PdfColors.grey400),
          _totalRow('Total Amount', data.totalAmount, strong: true),
          _plainRow('Amount in Words', PdfFormatters.amountInWords(data.totalAmount)),
          _totalRow('Remaining Amount', data.remainingAmount),
        ],
      ),
    );
  }

  static pw.Widget _terms(CustomerInvoicePdfData data) {
    final terms = PdfFormatters.safeText(
      data.termsAndConditions,
      fallback:
          'This is a payment receipt for the booking/partnership made with ClickNow.\n'
          'All services are subject to availability and confirmation.\n'
          'Policy details will be updated soon.\n'
          'Please retain this invoice for your records.\n'
          'For queries, contact Support@clicknow.co.in or 9253842526.',
    );
    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text('Terms & Conditions', style: _bold(12)),
          pw.SizedBox(height: 5),
          pw.Text(terms, style: _body()),
          if ((data.notes ?? '').trim().isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 8),
            pw.Text('Notes', style: _bold(12)),
            pw.Text(data.notes!, style: _body()),
          ],
        ],
      ),
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
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.SizedBox(width: 105, child: pw.Text(entry.key, style: _muted())),
                  pw.Expanded(child: pw.Text(entry.value, style: _body())),
                ],
              ),
            ),
          ),
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
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(cell, style: header ? _bold(8.8) : _body(8)),
            ),
          )
          .toList(growable: false),
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

  static pw.Widget _totalRow(String label, num value, {bool strong = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(child: pw.Text(label, style: strong ? _bold(11) : _body(10))),
          pw.Text(
            PdfFormatters.formatCurrency(value),
            style: strong ? _bold(12, PdfColor.fromHex('#23043E')) : _body(10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _plainRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Expanded(child: pw.Text(label, style: _body(10))),
          pw.SizedBox(
            width: 92,
            child: pw.Text(value, textAlign: pw.TextAlign.right, style: _body(9)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Expanded(
          child: pw.Text(
            'System-generated invoice. No physical signature required. Thank You. Connecting Events, Creating Success.',
            style: _muted(8),
          ),
        ),
        pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: _muted(8)),
      ],
    );
  }

  static String _paymentOption(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.contains('ADVANCE')) return '20% Advance';
    if (normalized.contains('FULL')) return 'Full Payment';
    return PdfFormatters.safeText(value);
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
