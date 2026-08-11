import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfExportService {
  PdfExportService._();
  static final instance = PdfExportService._();

  Future<File> generateReportPdf({
    required String title,
    required String content,
    required double similarityScore,
    required double writingScore,
    required String dateStr,
    required String scanId,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(title, dateStr, scanId),
            pw.SizedBox(height: 20),
            _buildScoreSummary(similarityScore, writingScore),
            pw.SizedBox(height: 30),
            pw.Text(
              'Document Content',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              content,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Report_$scanId.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(String title, String dateStr, String scanId) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Academic Writing Coach',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Plagiarism & Writing Analysis Report', style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Title: $title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: $dateStr'),
              ],
            ),
            pw.Text('Scan ID: $scanId', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildScoreSummary(double similarityScore, double writingScore) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildScoreItem('Similarity', '${similarityScore.toStringAsFixed(1)}%', similarityScore > 30 ? PdfColors.red : PdfColors.green),
          _buildScoreItem('Writing Score', writingScore.toStringAsFixed(1), PdfColors.blue),
        ],
      ),
    );
  }

  pw.Widget _buildScoreItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: color),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }
}
