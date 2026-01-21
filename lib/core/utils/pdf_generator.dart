import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/credit.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/installment.dart';

class PdfGenerator {
  static final _currencyFormat =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  static Future<void> generateReceipt({
    required Credit credit,
    required Customer customer,
    required Installment installment,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final primaryColor = PdfColor.fromHex('#6C63FF'); // Matches AppTheme
    const accentColor = PdfColors.grey200;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'COMPROBANTE DE PAGO',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 24,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Recibo #${installment.id.substring(0, 8).toUpperCase()}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'FECHA',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            color: PdfColors.grey600),
                      ),
                      pw.Text(
                        _dateFormat.format(DateTime.now()),
                        style: pw.TextStyle(font: fontRegular, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // CUSTOMER INFO BOX
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RECIBIDO DE',
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 10,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 8),
                        pw.Text(customer.name,
                            style: pw.TextStyle(font: fontBold, fontSize: 16)),
                        pw.Text('C.C. ${customer.documentId}',
                            style:
                                pw.TextStyle(font: fontRegular, fontSize: 12)),
                        if (customer.phone != null)
                          pw.Text(customer.phone!,
                              style: pw.TextStyle(
                                  font: fontRegular, fontSize: 12)),
                      ],
                    ),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('CRÉDITO REF.',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: PdfColors.grey700)),
                          pw.SizedBox(height: 8),
                          pw.Text(credit.id.substring(0, 8).toUpperCase(),
                              style:
                                  pw.TextStyle(font: fontBold, fontSize: 14)),
                        ])
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // DETAILS TABLE
              pw.Text('DETALLES DEL PAGO',
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 14, color: primaryColor)),
              pw.Divider(color: primaryColor),
              pw.SizedBox(height: 10),

              _buildDetailRow(
                  'Concepto',
                  'Pago Cuota No. ${installment.number}',
                  fontRegular,
                  fontBold),
              _buildDetailRow(
                  'Vencimiento Cuota',
                  _dateFormat.format(installment.dueDate).split(' ')[0],
                  fontRegular,
                  fontBold),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // TOTAL
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL PAGADO:',
                      style: pw.TextStyle(font: fontBold, fontSize: 16)),
                  pw.SizedBox(width: 20),
                  pw.Text(
                    _currencyFormat.format(installment.amount),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // FOOTER / SIGNATURE
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Firma Autorizada',
                          style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                    ],
                  ),
                  pw.Text(
                    '¡Gracias por su pago!',
                    style: pw.TextStyle(
                        font: fontBold, color: primaryColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Print / Share
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'recibo_${customer.name}_${installment.number}.pdf',
    );
  }

  static Future<void> generatePazYSalvo({
    required Credit credit,
    required Customer customer,
  }) async {
    final doc = pw.Document();
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontItalic = await PdfGoogleFonts.openSansItalic();

    final primaryColor = PdfColor.fromHex('#6C63FF');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.SizedBox(height: 20),
              pw.Text(
                'CERTIFICADO DE PAZ Y SALVO',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 24,
                  color: primaryColor,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 60),

              // Body
              pw.Text(
                'A QUIEN INTERESE:',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
              pw.SizedBox(height: 30),
              pw.Paragraph(
                text:
                    'Por medio de la presente se certifica que el señor(a) ${customer.name.toUpperCase()}, identificado(a) con cédula de ciudadanía número ${customer.documentId}, se encuentra A PAZ Y SALVO por todo concepto relacionado con el crédito número ${credit.id.substring(0, 8).toUpperCase()}.',
                style: pw.TextStyle(
                    font: fontRegular, fontSize: 14, lineSpacing: 5),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 20),
              pw.Paragraph(
                text:
                    'El mencionado crédito, por valor de ${_currencyFormat.format(credit.totalAmount)}, más intereses, ha sido cancelado en su totalidad a satisfacción.',
                style: pw.TextStyle(
                    font: fontRegular, fontSize: 14, lineSpacing: 5),
                textAlign: pw.TextAlign.justify,
              ),

              pw.SizedBox(height: 60),

              // Details Box
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(children: [
                  _buildDetailRow(
                      'Fecha de Inicio:',
                      _dateFormat.format(credit.startDate),
                      fontRegular,
                      fontBold),
                  _buildDetailRow(
                      'Monto Total Pagado:',
                      _currencyFormat.format(credit.totalWithInterest),
                      fontRegular,
                      fontBold),
                  _buildDetailRow('Número de Cuotas:',
                      '${credit.installmentsCount}', fontRegular, fontBold),
                  _buildDetailRow('Estado:', 'PAGADO', fontRegular, fontBold),
                ]),
              ),

              pw.Spacer(),

              // Date
              pw.Text(
                'Expedido el día ${_dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(font: fontItalic, fontSize: 12),
              ),
              pw.SizedBox(height: 50),

              // Signature
              pw.Column(
                children: [
                  pw.Container(
                    width: 200,
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Firma Autorizada',
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                  pw.Text(
                    'Administración',
                    style: pw.TextStyle(font: fontRegular, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'paz_y_salvo_${customer.name}.pdf',
    );
  }

  static pw.Widget _buildDetailRow(
      String label, String value, pw.Font fontRegular, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(font: fontRegular, fontSize: 12)),
        ],
      ),
    );
  }
}
