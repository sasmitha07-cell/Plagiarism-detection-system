import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/flagged_section.dart';
import '../providers/scan_provider.dart';

class DocumentHighlightViewer extends StatefulWidget {
  final String documentText;
  final List<FlaggedSectionData> flaggedSections;
  final String? scanId;
  final String? documentId;

  const DocumentHighlightViewer({
    super.key,
    required this.documentText,
    required this.flaggedSections,
    this.scanId,
    this.documentId,
  });

  @override
  State<DocumentHighlightViewer> createState() => _DocumentHighlightViewerState();
}

class _DocumentHighlightViewerState extends State<DocumentHighlightViewer> {
  int _activeIssueIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectIssue(int index) {
    if (index < 0 || index >= widget.flaggedSections.length) return;
    setState(() => _activeIssueIndex = index);
    _showIssueDetailsModal(widget.flaggedSections[index]);
  }

  void _showIssueDetailsModal(FlaggedSectionData issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IssueInspectorSheet(
        issue: issue,
        scanId: widget.scanId,
        documentId: widget.documentId,
        onNext: _activeIssueIndex < widget.flaggedSections.length - 1
            ? () {
                Navigator.pop(ctx);
                _selectIssue(_activeIssueIndex + 1);
              }
            : null,
        onPrev: _activeIssueIndex > 0
            ? () {
                Navigator.pop(ctx);
                _selectIssue(_activeIssueIndex - 1);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.documentText.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            'No document text available.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final spans = _buildTextSpans();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header toolbar with issue counter & navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                const Icon(Icons.highlight_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'In-Document Highlights',
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.flaggedSections.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    onPressed: _activeIssueIndex > 0 ? () => _selectIssue(_activeIssueIndex - 1) : null,
                    tooltip: 'Previous issue',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Text(
                    '${_activeIssueIndex + 1} of ${widget.flaggedSections.length}',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    onPressed: _activeIssueIndex < widget.flaggedSections.length - 1
                        ? () => _selectIssue(_activeIssueIndex + 1)
                        : null,
                    tooltip: 'Next issue',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ],
            ),
          ),

          // Scrollable Document Text with Rich Highlights
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: SelectableText.rich(
                TextSpan(children: spans),
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.8,
                  letterSpacing: 0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Bottom Quick Legend / Action
          if (widget.flaggedSections.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap any highlighted text to inspect details & fix',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showIssueDetailsModal(widget.flaggedSections[_activeIssueIndex]),
                    icon: const Icon(Icons.touch_app_rounded, size: 14),
                    label: const Text('Inspect'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildTextSpans() {
    final text = widget.documentText;
    final sections = List<FlaggedSectionData>.from(widget.flaggedSections);

    if (sections.isEmpty) {
      return [TextSpan(text: text)];
    }

    // Sort by start position
    sections.sort((a, b) => a.startPosition.compareTo(b.startPosition));

    final spans = <InlineSpan>[];
    int currentPos = 0;

    for (int i = 0; i < sections.length; i++) {
      final sec = sections[i];
      int start = sec.startPosition.clamp(0, text.length);
      int end = sec.endPosition.clamp(start, text.length);

      // If start/end position was 0 or invalid, attempt fallback exact match in text
      if (start == 0 && end == 0 && sec.flaggedText.isNotEmpty) {
        final idx = text.indexOf(sec.flaggedText);
        if (idx != -1) {
          start = idx;
          end = idx + sec.flaggedText.length;
        }
      }

      if (start > currentPos && currentPos < text.length) {
        spans.add(TextSpan(text: text.substring(currentPos, start)));
        currentPos = start;
      }

      // Prevent overlapping or redundant spans from repeating text
      if (start < currentPos) {
        start = currentPos;
      }
      if (end <= start) {
        continue;
      }

      if (start < text.length && end <= text.length && start < end) {
        final isSelected = i == _activeIssueIndex;
        final highlightColor = _getHighlightColor(sec.signals);

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => _selectIssue(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: highlightColor.withValues(alpha: isSelected ? 0.40 : 0.22),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? highlightColor : highlightColor.withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  text.substring(start, end),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
        currentPos = end;
      }
    }

    if (currentPos < text.length) {
      spans.add(TextSpan(text: text.substring(currentPos)));
    }

    return spans;
  }

  Color _getHighlightColor(List<PlagiarismType> signals) {
    if (signals.contains(PlagiarismType.quotedAndCited)) {
      return AppColors.riskSafe; // Green (Exempt scholarship)
    }
    if (signals.contains(PlagiarismType.exactCopy)) {
      return AppColors.riskCritical; // Red
    }
    if (signals.contains(PlagiarismType.webDiscovery)) {
      return AppColors.tertiary; // Blue
    }
    if (signals.contains(PlagiarismType.selfPlagiarism)) {
      return AppColors.secondary; // Purple/Teal
    }
    if (signals.contains(PlagiarismType.missingCitation)) {
      return AppColors.accent; // Orange
    }
    return AppColors.riskMedium; // Amber
  }
}

class _IssueInspectorSheet extends StatelessWidget {
  final FlaggedSectionData issue;
  final String? scanId;
  final String? documentId;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  const _IssueInspectorSheet({
    required this.issue,
    this.scanId,
    this.documentId,
    this.onNext,
    this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    final type = issue.signals.isNotEmpty ? issue.signals.first : PlagiarismType.semanticSimilarity;
    final riskColor = _getRiskColor(issue.riskLevel);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Match type & similarity score badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: riskColor, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _getTypeLabel(type),
                          style: AppTypography.labelMedium.copyWith(
                            color: riskColor,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${issue.similarityScore}% Match',
                style: AppTypography.titleMedium.copyWith(
                  color: riskColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Flagged Passage
          Text('Flagged Text', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              '"${issue.flaggedText}"',
              style: AppTypography.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Source Information
          if (issue.sourceTitle != null || issue.sourceUrl != null) ...[
            Text('Matched Source', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.sourceTitle ?? 'Web / Database Source',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (issue.sourceUrl != null && issue.sourceUrl!.isNotEmpty)
                          Text(
                            issue.sourceUrl!,
                            style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reason / Clinical Explanation
          if (issue.explanation != null && issue.explanation!.isNotEmpty) ...[
            Text('Why it was flagged', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: 4),
            Text(
              issue.explanation!,
              style: AppTypography.bodySmall.copyWith(height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
          ],

          // Action Buttons: Fix with AI Coach / Add Citation
          Row(
            children: [
              if (issue.sourceUrl != null && issue.sourceUrl!.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/profile/citations');
                    },
                    icon: const Icon(Icons.format_quote_rounded, size: 18),
                    label: const Text('Cite Source', maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              if (issue.sourceUrl != null && issue.sourceUrl!.isNotEmpty)
                const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/coach/rewrite', extra: {
                      'text': issue.flaggedText,
                      'scanId': scanId,
                      'documentId': documentId,
                      'startPos': issue.startPosition,
                      'endPos': issue.endPosition,
                      'type': type,
                    });
                  },
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                  label: const Text('Fix with AI Coach', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'critical':
        return AppColors.riskCritical;
      case 'high':
        return AppColors.riskHigh;
      case 'medium':
        return AppColors.riskMedium;
      case 'low':
      case 'safe':
      default:
        return AppColors.riskLow;
    }
  }

  String _getTypeLabel(PlagiarismType type) {
    switch (type) {
      case PlagiarismType.exactCopy:
        return 'Exact Copy';
      case PlagiarismType.partialCopy:
        return 'Partial Copy';
      case PlagiarismType.semanticSimilarity:
        return 'Semantic Similarity';
      case PlagiarismType.missingCitation:
        return 'Missing Citation';
      case PlagiarismType.paraphrased:
        return 'Paraphrased Content';
      case PlagiarismType.aiRewritten:
        return 'AI-Rewritten Content';
      case PlagiarismType.webDiscovery:
        return 'Web Match';
      case PlagiarismType.selfPlagiarism:
        return 'Possible Self-Plagiarism';
      case PlagiarismType.quotedAndCited:
        return 'Quoted & Cited';
    }
  }
}
