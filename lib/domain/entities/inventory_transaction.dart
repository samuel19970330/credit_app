class InventoryTransaction {
  final String id;
  final String productId;
  final String type; // 'INBOUND', 'OUTBOUND', 'ADJUSTMENT'
  final int quantity;
  final int previousStock;
  final int newStock;
  final DateTime date;
  final String? referenceDoc;

  InventoryTransaction({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.date,
    this.referenceDoc,
  });
}
