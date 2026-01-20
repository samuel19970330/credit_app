import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';

class PdfGeneratorService {
  Future<Uint8List> generateReceipt({
    required String transactionId,
    required CustomerModel customer,
    required double amountPaid,
    required double remainingDebt,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Thermal printer width size
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('CREDIT SALES APP',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ),
              pw.Divider(),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(date)}'),
              pw.Text(
                  'Receipt #: ${transactionId.substring(transactionId.length - 6)}'),
              pw.SizedBox(height: 10),
              pw.Text('Customer: ${customer.name}'),
              pw.Text('Doc ID: ${customer.documentId}'),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount Paid:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${amountPaid.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('New Balance:'),
                  pw.Text('\$${remainingDebt.toStringAsFixed(2)}'),
                ],
              ),
              pw.Divider(),
              pw.Center(child: pw.Text('Thank you for your payment!')),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
