import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/receipt_models.dart';

class ReceiptPdfService {
  static final Future<pw.Font> _unicodeFont = _loadUnicodeFont();

  Future<Uint8List> buildPdf(ReceiptDraft draft) async {
    final font = await _unicodeFont;
    final document = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final currency = SupportedCurrency.fromCode(draft.currencyCode);
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      name: currency.code,
      symbol: '${currency.symbol} ',
      decimalDigits: currency == SupportedCurrency.jpy ? 0 : 2,
    );
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(
        base: font,
        bold: font,
        italic: font,
        boldItalic: font,
        fontFallback: [font],
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8EBDD'),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#703421'),
                            letterSpacing: 3,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          draft.title,
                          style: const pw.TextStyle(
                            fontSize: 13,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#703421'),
                        borderRadius: pw.BorderRadius.circular(14),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _metaText(
                            'Receipt No.',
                            draft.receiptNumber,
                            invert: true,
                          ),
                          pw.SizedBox(height: 6),
                          _metaText(
                            'Issue Date',
                            DateFormat('yyyy-MM-dd').format(draft.issueDate),
                            invert: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 22),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _partyCard('Received By', draft.payee, '#FFF8F0'),
                    ),
                    pw.SizedBox(width: 18),
                    pw.Expanded(
                      child: _partyCard(
                        'Received From',
                        draft.payer,
                        '#FFF8F0',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 26),
          pw.Container(
            padding: const pw.EdgeInsets.all(22),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#D7C0A8')),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Charge Summary',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#703421'),
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.8),
                    1: const pw.FlexColumnWidth(0.9),
                    2: const pw.FlexColumnWidth(1.2),
                    3: const pw.FlexColumnWidth(1.2),
                  },
                  children: [
                    _tableRow(
                      'Description',
                      'Qty',
                      'Unit',
                      'Amount',
                      header: true,
                    ),
                    _tableRow(
                      draft.description,
                      displayNumber(draft.quantity),
                      formatter.format(draft.unitPrice),
                      formatter.format(draft.subtotal),
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.SizedBox(
                      width: 190,
                      child: pw.Column(
                        children: [
                          _amountLine(
                            'Subtotal',
                            formatter.format(draft.subtotal),
                          ),
                          _amountLine(
                            'Tax',
                            '${displayNumber(draft.taxRate)}%',
                          ),
                          _amountLine(
                            'Tax Amount',
                            formatter.format(draft.taxAmount),
                          ),
                          pw.Divider(color: PdfColor.fromHex('#D7C0A8')),
                          _amountLine(
                            'Total',
                            formatter.format(draft.total),
                            emphasis: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFF8F0'),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Notes',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#703421'),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  draft.note.isEmpty ? 'No additional notes.' : draft.note,
                  style: const pw.TextStyle(fontSize: 11.5, lineSpacing: 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<pw.Font> _loadUnicodeFont() async {
    final data = await rootBundle.load('assets/fonts/ArialUnicode.ttf');
    return pw.Font.ttf(data);
  }

  pw.Widget _partyCard(String title, PartyTemplate party, String fillColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex(fillColor),
        borderRadius: pw.BorderRadius.circular(18),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#703421'),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            party.name,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
          pw.SizedBox(height: 6),
          pw.Text(party.contact, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(party.address, style: const pw.TextStyle(fontSize: 11)),
          if (party.accountLabel.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              party.accountLabel,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
          if (party.note.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              party.note,
              style: const pw.TextStyle(
                fontSize: 10.5,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.TableRow _tableRow(
    String a,
    String b,
    String c,
    String d, {
    bool header = false,
  }) {
    final textStyle = pw.TextStyle(
      fontSize: header ? 11 : 10.5,
      fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: header ? PdfColor.fromHex('#703421') : PdfColors.black,
    );

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: header ? PdfColor.fromHex('#F8EBDD') : PdfColors.white,
      ),
      children: [
        _tableCell(a, textStyle, align: pw.Alignment.centerLeft),
        _tableCell(b, textStyle, align: pw.Alignment.center),
        _tableCell(c, textStyle, align: pw.Alignment.centerRight),
        _tableCell(d, textStyle, align: pw.Alignment.centerRight),
      ],
    );
  }

  pw.Widget _tableCell(
    String text,
    pw.TextStyle style, {
    required pw.Alignment align,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Text(text, style: style),
    );
  }

  pw.Widget _amountLine(String label, String value, {bool emphasis = false}) {
    final style = pw.TextStyle(
      fontSize: emphasis ? 13 : 11,
      fontWeight: emphasis ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: emphasis ? PdfColor.fromHex('#703421') : PdfColors.black,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  pw.Widget _metaText(String label, String value, {bool invert = false}) {
    final color = invert ? PdfColors.white : PdfColors.black;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: color)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
