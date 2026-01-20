import '../../domain/entities/inventory_transaction.dart';

class InventoryTransactionModel extends InventoryTransaction {
  InventoryTransactionModel({
    required super.id,
    required super.productId,
    required super.type,
    required super.quantity,
    required super.previousStock,
    required super.newStock,
    required super.date,
    super.referenceDoc,
  });

  factory InventoryTransactionModel.fromMap(Map<String, dynamic> map) {
    return InventoryTransactionModel(
      id: map['id'],
      productId: map['product_id'],
      type: map['type'],
      quantity: map['quantity'],
      previousStock: map['previous_stock'],
      newStock: map['new_stock'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      referenceDoc: map['reference_doc'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'previous_stock': previousStock,
      'new_stock': newStock,
      'date': date.millisecondsSinceEpoch,
      'reference_doc': referenceDoc,
    };
  }
}
