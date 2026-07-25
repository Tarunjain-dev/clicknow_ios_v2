class PdfLineItem {
  const PdfLineItem({
    required this.itemName,
    required this.description,
    this.sacCode = '9983',
    required this.unitPrice,
    required this.quantity,
    required this.discountPercent,
    required this.taxPercent,
    required this.amount,
  });

  final String itemName;
  final String description;
  final String sacCode;
  final double unitPrice;
  final int quantity;
  final double discountPercent;
  final double taxPercent;
  final double amount;

  double get taxableAmount {
    final gross = unitPrice * quantity;
    return gross - (gross * discountPercent / 100);
  }

  double get taxAmount => taxableAmount * taxPercent / 100;

  double get finalAmount => amount;
}
