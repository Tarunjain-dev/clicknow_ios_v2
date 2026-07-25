import 'package:intl/intl.dart';

class PdfFormatters {
  PdfFormatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs.',
    decimalDigits: 2,
  );

  static String formatCurrency(num value) => _currency.format(value);

  static String amountInWords(num value) {
    final rupees = value.round().abs();
    if (rupees == 0) return 'Zero Rupees Only';
    return '${_numberToWords(rupees)} Rupees Only';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return 'Not provided';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not provided';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  static String safeText(String? value, {String fallback = 'Not provided'}) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String safeFileName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : cleaned;
  }

  static String _numberToWords(int value) {
    const ones = <String>[
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    const tens = <String>[
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String underHundred(int number) {
      if (number < 20) return ones[number];
      final ten = tens[number ~/ 10];
      final one = ones[number % 10];
      return one.isEmpty ? ten : '$ten $one';
    }

    String underThousand(int number) {
      final hundred = number ~/ 100;
      final rest = number % 100;
      if (hundred == 0) return underHundred(rest);
      final prefix = '${ones[hundred]} Hundred';
      return rest == 0 ? prefix : '$prefix ${underHundred(rest)}';
    }

    final parts = <String>[];
    final crore = value ~/ 10000000;
    value %= 10000000;
    final lakh = value ~/ 100000;
    value %= 100000;
    final thousand = value ~/ 1000;
    value %= 1000;
    if (crore > 0) parts.add('${underThousand(crore)} Crore');
    if (lakh > 0) parts.add('${underThousand(lakh)} Lakh');
    if (thousand > 0) parts.add('${underThousand(thousand)} Thousand');
    if (value > 0) parts.add(underThousand(value));
    return parts.join(' ');
  }
}
