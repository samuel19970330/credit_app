class Product {
  final String id;
  final String name;
  final String sku;
  final int currentStock;
  final double price;
  final double cost;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.price,
    required this.cost,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'currentStock': currentStock,
      'price': price,
      'cost': cost,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      sku: map['sku'],
      currentStock: map['currentStock'],
      price: map['price'],
      cost: map['cost'],
      isActive: map['isActive'] == 1,
    );
  }
}
