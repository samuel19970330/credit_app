import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<List<Product>> getProducts() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  @override
  Future<void> addProduct(Product product) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateProduct(Product product) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  @override
  Future<void> deleteProduct(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? OR sku LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((json) => Product.fromMap(json)).toList();
  }
}
