import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/product.dart';

class ExcelService {
  static Future<String> generateProductTemplate() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Productos'];

    // Headers
    List<String> headers = ['Nombre', 'SKU', 'Stock', 'Precio', 'Costo'];
    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    // Example Row (Optional, maybe helpful)
    sheetObject.appendRow([
      TextCellValue('Ejemplo Producto'),
      TextCellValue('SKU123'),
      const IntCellValue(10),
      const DoubleCellValue(50000),
      const DoubleCellValue(30000),
    ]);

    // Delete default sheet if exists and different
    if (excel.sheets.containsKey('Sheet1') && excel.sheets.length > 1) {
      excel.delete('Sheet1');
    }

    // Save
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/plantilla_productos.xlsx';
    final file = File(path);

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      return path;
    }
    throw Exception('Error al generar el archivo Excel');
  }

  static Future<List<Product>> parseProducts(List<int> fileBytes) async {
    var excel = Excel.decodeBytes(fileBytes);
    List<Product> products = [];
    const uuid = Uuid();

    for (var table in excel.tables.keys) {
      // Assuming 'Productos' sheet or first sheet
      // if (table != 'Productos') continue;

      var sheet = excel.tables[table];
      if (sheet == null) continue;

      // Skip header row
      bool isHeader = true;
      for (var row in sheet.rows) {
        if (isHeader) {
          isHeader = false;
          continue;
        }

        // Check if row is empty
        if (row.isEmpty || row[0] == null) continue;

        try {
          // Headers: Name (0), SKU (1), Stock (2), Price (3), Cost (4)
          final name = row[0]?.value?.toString() ?? '';
          final sku = row[1]?.value?.toString() ?? '';

          // Stock
          int stock = 0;
          if (row[2]?.value is int) {
            stock = row[2]?.value as int;
          } else if (row[2]?.value is double) {
            stock = (row[2]?.value as double).toInt();
          } else {
            stock = int.tryParse(row[2]?.value.toString() ?? '0') ?? 0;
          }

          // Price
          double price = 0.0;
          if (row[3]?.value is double) {
            price = row[3]?.value as double;
          } else if (row[3]?.value is int) {
            price = (row[3]?.value as int).toDouble();
          } else {
            price = double.tryParse(row[3]?.value.toString() ?? '0') ?? 0;
          }

          // Cost
          double cost = 0.0;
          if (row[4]?.value is double) {
            cost = row[4]?.value as double;
          } else if (row[4]?.value is int) {
            cost = (row[4]?.value as int).toDouble();
          } else {
            cost = double.tryParse(row[4]?.value.toString() ?? '0') ?? 0;
          }

          if (name.isNotEmpty && sku.isNotEmpty) {
            products.add(Product(
              id: uuid.v4(),
              name: name,
              sku: sku,
              currentStock: stock,
              price: price,
              cost: cost,
              isActive: true,
            ));
          }
        } catch (e) {
          // Skip malformed rows or log
          print('Error parsing row: $e');
        }
      }
    }
    return products;
  }
}
