import '../../domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.name,
    required super.sku,
    required super.currentStock,
    required super.price,
    required super.cost,
    required super.isActive,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'],
      sku: map['sku'],
      currentStock: map['current_stock'],
      price: map['price'],
      cost: map['cost'],
      isActive: map['is_active'] == 1,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'current_stock': currentStock,
      'price': price,
      'cost': cost,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      sku: product.sku,
      currentStock: product.currentStock,
      price: product.price,
      cost: product.cost,
      isActive: product.isActive,
    );
  }
}
