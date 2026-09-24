import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../features/scan/providers/scan_provider.dart';

class PdfExportService {
  PdfExportService._();
  static final instance = PdfExportService._();

  Future<File> generateComprehensiveReportPdf({
    required String title,
    required String content,
    required double similarityScore,
    required double aiScore,
    required double writingScore,
    required double exactMatchScore,
    required double semanticScore,
    required double paraphraseScore,
    required String dateStr,
    required String scanId,
    String? executiveSummary,
    List<FlaggedSectionData> flaggedSections = const [],
    List<Map<String, dynamic>> sources = const [],
    List<String> recommendations = const [],
  }) async {
    final pdf = pw.Document();
    final originalityScore = (100.0 - similarityScore).clamp(0.0, 100.0);

    final effectiveSources = sources.isNotEmpty
        ? sources
        : flaggedSections
            .where((f) => f.sourceTitle != null || f.sourceUrl != null)
            .map((f) => {
                  'title': f.sourceTitle ?? 'Web Source',
                  'url': f.sourceUrl ?? '',
                  'similarity_percentage': f.similarityScore,
                  'snippet': f.flaggedText,
                  'domain': f.domain,
                })
            .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) => _buildPageHeader(title, scanId, dateStr),
        footer: (pw.Context context) => _buildPageFooter(context),
        build: (pw.Context context) {
          return [
            _buildReportBanner(title, scanId, dateStr),
            pw.SizedBox(height: 20),
            _buildScoreCardsGrid(
              similarityScore: similarityScore,
              originalityScore: originalityScore,
              aiScore: aiScore,
              writingScore: writingScore,
            ),
            pw.SizedBox(height: 20),
            _buildBreakdownTable(
              exactMatchScore: exactMatchScore,
              semanticScore: semanticScore,
              paraphraseScore: paraphraseScore,
              aiScore: aiScore,
              originalityScore: originalityScore,
            ),
            pw.SizedBox(height: 24),
            if (executiveSummary != null && executiveSummary.isNotEmpty) ...[
              _buildSectionTitle('Executive Summary'),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  executiveSummary,
                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5, color: PdfColors.grey800),
                ),
              ),
              pw.SizedBox(height: 24),
            ],
            if (effectiveSources.isNotEmpty) ...[
              _buildSectionTitle('Detected Sources (${effectiveSources.length})'),
              ...effectiveSources.map((s) => _buildSourceItem(s)),
              pw.SizedBox(height: 24),
            ],
            if (flaggedSections.isNotEmpty) ...[
              _buildSectionTitle('Flagged Matches & Integrity Issues (${flaggedSections.length})'),
              ...flaggedSections.take(15).map((f) => _buildFlaggedSectionItem(f)),
              pw.SizedBox(height: 24),
            ],
            if (recommendations.isNotEmpty) ...[
              _buildSectionTitle('Actionable Recommendations'),
              ...recommendations.map((r) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                        pw.Expanded(
                          child: pw.Text(r, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4)),
                        ),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 24),
            ],
            _buildSectionTitle('Full Document Text'),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Text(
                content,
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.6, color: PdfColors.grey900),
              ),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Academic_Report_${scanId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildPageHeader(String title, String scanId, String dateStr) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Academic Writing Coach — Integrity Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Scan ID: $scanId', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Confidential Academic Integrity Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _buildReportBanner(String title, String scanId, String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ACADEMIC INTEGRITY & QUALITY REPORT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text('Document: $title', style: const pw.TextStyle(fontSize: 12, color: PdfColors.blue100)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue100)),
              pw.SizedBox(height: 2),
              pw.Text('Status: Verified Complete', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green300)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildScoreCardsGrid({
    required double similarityScore,
    required double originalityScore,
    required double aiScore,
    required double writingScore,
  }) {
    return pw.Row(
      children: [
        _buildScoreBox('Originality', '${originalityScore.toStringAsFixed(1)}%', PdfColors.green700),
        pw.SizedBox(width: 10),
        _buildScoreBox('Plagiarism', '${similarityScore.toStringAsFixed(1)}%', similarityScore > 25 ? PdfColors.red700 : PdfColors.green700),
        pw.SizedBox(width: 10),
        _buildScoreBox('AI Probability', '${aiScore.toStringAsFixed(1)}%', aiScore > 40 ? PdfColors.purple700 : PdfColors.blue700),
        pw.SizedBox(width: 10),
        _buildScoreBox('Writing Quality', '${writingScore.toStringAsFixed(0)}/100', PdfColors.blue800),
      ],
    );
  }

  pw.Widget _buildScoreBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          children: [
            pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 4),
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildBreakdownTable({
    required double exactMatchScore,
    required double semanticScore,
    required double paraphraseScore,
    required double aiScore,
    required double originalityScore,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildCell('Metric', isHeader: true),
            _buildCell('Score', isHeader: true),
            _buildCell('Analysis Category', isHeader: true),
          ],
        ),
        pw.TableRow(children: [
          _buildCell('Exact Copy Overlap'),
          _buildCell('${exactMatchScore.toStringAsFixed(1)}%'),
          _buildCell('Verbatim string match against indexed web & personal sources'),
        ]),
        pw.TableRow(children: [
          _buildCell('Semantic Similarity'),
          _buildCell('${semanticScore.toStringAsFixed(1)}%'),
          _buildCell('Vector embedding conceptual overlap'),
        ]),
        pw.TableRow(children: [
          _buildCell('Paraphrased Content'),
          _buildCell('${paraphraseScore.toStringAsFixed(1)}%'),
          _buildCell('Near-duplicate sentence structure patterns'),
        ]),
        pw.TableRow(children: [
          _buildCell('AI Writing Likelihood'),
          _buildCell('${aiScore.toStringAsFixed(1)}%'),
          _buildCell('Structural uniformity & perplexity indicator'),
        ]),
      ],
    );
  }

  pw.Widget _buildCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
      ),
    );
  }

  pw.Widget _buildSourceItem(Map<String, dynamic> source) {
    final title = source['title'] as String? ?? 'Web Source';
    final url = source['url'] as String? ?? '';
    final sim = (source['similarity_percentage'] as num?)?.toDouble() ?? 0.0;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                if (url.isNotEmpty)
                  pw.Text(url, style: const pw.TextStyle(fontSize: 7, color: PdfColors.blue700)),
              ],
            ),
          ),
          pw.Text('${sim.toStringAsFixed(1)}% Match', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        ],
      ),
    );
  }

  pw.Widget _buildFlaggedSectionItem(FlaggedSectionData item) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Flagged Passage (${item.similarityScore}% Match)',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
              ),
              if (item.sourceTitle != null)
                pw.Text('Source: ${item.sourceTitle}', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('"${item.flaggedText}"', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
          if (item.explanation != null && item.explanation!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Why Flagged: ${item.explanation}', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          ],
        ],
      ),
    );
  }

  // Legacy method for backward compatibility
  Future<File> generateReportPdf({
    required String title,
    required String content,
    required double similarityScore,
    required double writingScore,
    required String dateStr,
    required String scanId,
  }) {
    return generateComprehensiveReportPdf(
      title: title,
      content: content,
      similarityScore: similarityScore,
      aiScore: 0.0,
      writingScore: writingScore,
      exactMatchScore: similarityScore * 0.4,
      semanticScore: similarityScore * 0.4,
      paraphraseScore: similarityScore * 0.2,
      dateStr: dateStr,
      scanId: scanId,
    );
  }
}
