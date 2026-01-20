class CreditItem {
  final String productId;
  final String productName;
  final double unitPrice; // Price at the moment of sale
  final int quantity;
  final double subtotal;

  CreditItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  }) : subtotal = unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory CreditItem.fromMap(Map<String, dynamic> map) {
    return CreditItem(
      productId: map['productId'],
      productName: map['productName'],
      unitPrice: map['unitPrice'],
      quantity: map['quantity'],
    );
  }
}
