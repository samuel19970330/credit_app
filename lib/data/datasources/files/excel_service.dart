import 'dart:io';
import 'package:excel/excel.dart';
import '../../models/product_model.dart';

class ExcelService {
  /// Parses an Excel file and returns a list of Products.
  /// Expects columns: [Name, SKU, Stock, Price, Cost]
  Future<List<ProductModel>> parseProducts(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final List<ProductModel> products = [];

    for (var table in excel.tables.keys) {
      // Assuming first sheet contains data
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      // Skip header row (index 0)
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        
        // Simple validation: Ensure minimum columns
        if (row.length < 5) continue;

        try {
          final name = row[0]?.value?.toString() ?? 'Unknown';
          final sku = row[1]?.value?.toString() ?? '';
          final stock = int.tryParse(row[2]?.value?.toString() ?? '0') ?? 0;
          final price = double.tryParse(row[3]?.value?.toString() ?? '0.0') ?? 0.0;
          final cost = double.tryParse(row[4]?.value?.toString() ?? '0.0') ?? 0.0;

          if (sku.isEmpty) continue; // SKU is required

          products.add(ProductModel(
            id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(), // Temp ID
            name: name,
            sku: sku,
            currentStock: stock,
            price: price,
            cost: cost,
            isActive: true,
          ));
        } catch (e) {
          // Log error or skip row
          print('Error parsing row $i: $e');
        }
      }
    }
    return products;
  }

  /// Generates an Excel file bytes from a list of products.
  List<int>? generateProductExport(List<ProductModel> products) {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Inventory'];

    // Header
    sheet.appendRow([
      TextCellValue('Name'), 
      TextCellValue('SKU'), 
      TextCellValue('Current Stock'), 
      TextCellValue('Price'), 
      TextCellValue('Cost')
    ]);

    for (var product in products) {
      sheet.appendRow([
        TextCellValue(product.name),
        TextCellValue(product.sku),
        IntCellValue(product.currentStock),
        DoubleCellValue(product.price),
        DoubleCellValue(product.cost),
      ]);
    }

    // Remove default 'Sheet1'
    excel.delete('Sheet1');

    return excel.save();
  }
}
