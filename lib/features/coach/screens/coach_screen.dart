import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/models/scan_result.dart';
import '../../../core/services/writing_coach_service.dart';
import '../models/coach_message.dart';
import '../providers/coach_chat_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home/providers/home_provider.dart';
import '../../../core/utils/error_mapper.dart';

class CoachScreen extends ConsumerStatefulWidget {
  final String? scanId;
  const CoachScreen({super.key, this.scanId});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _editorController = TextEditingController();
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  WritingAnalysisReport? _liveReport;
  bool _isAnalyzingLive = false;
  String _selectedCategory = 'All';

  final List<String> _quickCoachPrompts = [
    'How can I improve my introduction?',
    'Is my argument strong enough?',
    'Which paragraph is weakest?',
    'Where do I need citations?',
    'Make this phrasing more academic.',
    'Explain my plagiarism matches.',
  ];

  final List<String> _categories = [
    'All',
    'Grammar',
    'Clarity',
    'Academic Tone',
    'Vocabulary',
    'Conciseness',
    'Citations',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _editorController.text =
        'In order to look into the data, we conducted an investigation on kids and things. '
        'A lot of good findings were made by our team because data is very huge and crazy. '
        'According to recent studies, empirical methodology plays a crucial role in academic rigor.';
    _runLiveAnalysis();

    // Initialize document text in chat provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coachChatProvider.notifier).updateDraftText(_editorController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _editorController.dispose();
    _chatInputController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _runLiveAnalysis() async {
    final text = _editorController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAnalyzingLive = true);
    try {
      final report = await WritingCoachService.instance.analyzeText(text);
      if (mounted) {
        setState(() {
          _liveReport = report;
          _isAnalyzingLive = false;
        });
        ref.read(coachChatProvider.notifier).updateDraftText(text);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzingLive = false);
        AppSnackbar.showError(context, AppErrorMapper.toUserFriendlyMessage(e, defaultAction: 'analyze writing'));
      }
    }
  }

  void _acceptLiveIssue(WritingIssue issue) {
    setState(() {
      issue.isAccepted = true;
      final text = _editorController.text;
      if (issue.startOffset <= text.length && issue.endOffset <= text.length && issue.startOffset < issue.endOffset) {
        _editorController.text = text.replaceRange(issue.startOffset, issue.endOffset, issue.suggestedReplacement);
      } else {
        final idx = text.indexOf(issue.originalText);
        if (idx != -1) {
          _editorController.text = text.replaceRange(idx, idx + issue.originalText.length, issue.suggestedReplacement);
        }
      }
    });
    AppSnackbar.showSuccess(context, 'Suggestion applied!');
    _runLiveAnalysis();
  }

  void _rejectLiveIssue(WritingIssue issue) {
    setState(() {
      issue.isRejected = true;
    });
  }

  void _sendDraftToCoach() {
    final draftText = _editorController.text.trim();
    if (draftText.isEmpty) {
      AppSnackbar.showError(context, 'Editor text is empty.');
      return;
    }
    ref.read(coachChatProvider.notifier).setDocumentContext(
      title: 'Live Editor Draft',
      text: draftText,
    );
    _tabController.animateTo(2); // Switch to Tab 3 (Conversational Coach)
    AppSnackbar.showSuccess(context, 'Draft loaded into Conversational Coach!');
  }

  void _coachScannedDocument(ScanResult scan) async {
    final client = Supabase.instance.client;
    String docContent = '';
    try {
      final row = await client.from('documents').select('content').eq('id', scan.documentId).maybeSingle();
      if (row != null && row['content'] != null) {
        docContent = row['content'].toString();
      }
    } catch (_) {}

    ref.read(coachChatProvider.notifier).setDocumentContext(
      title: scan.title,
      text: docContent.isNotEmpty ? docContent : 'Scanned document: ${scan.title}',
      documentId: scan.documentId,
      scanResult: scan,
    );

    if (!mounted) return;
    _tabController.animateTo(2); // Switch to Conversational Coach tab
    AppSnackbar.showSuccess(context, 'Loaded "${scan.title}" into Academic Coach!');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Writing Coach Studio'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Academic Writing Guide',
            onPressed: () => context.push('/profile/help'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: 'Live Editor'),
            Tab(icon: Icon(Icons.folder_shared_rounded, size: 18), text: 'Scanned Documents'),
            Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 18), text: 'Conversational Coach'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveEditorTab(),
          _buildScannedDocumentTab(),
          _buildConversationalCoachTab(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 1: LIVE COACH EDITOR
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildLiveEditorTab() {
    final report = _liveReport;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B3B2B), Color(0xFF2C5E43)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interactive Writing Coach',
                        style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get instant grammar, style, tone, and conciseness feedback.',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Text Editor Container
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowCard,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _editorController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Type or paste your academic writing here…',
                    border: InputBorder.none,
                  ),
                  style: AppTypography.bodyMedium.copyWith(height: 1.6),
                  onChanged: (_) {
                    _runLiveAnalysis();
                  },
                ),
                const Divider(height: 24),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Text(
                      '${_editorController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words | ${_editorController.text.length} chars',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _sendDraftToCoach,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                          label: const Text('Coach Draft'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isAnalyzingLive ? null : _runLiveAnalysis,
                          icon: _isAnalyzingLive
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Analyze'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Score Cards
          if (report != null) ...[
            Text('Quality Breakdown', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Overall Score', '${report.overallScore.round()}%', Icons.star_rounded, AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Readability', '${report.readabilityScore.round()}', Icons.menu_book_rounded, AppColors.secondary)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Tone', '${report.academicToneScore.round()}%', Icons.school_rounded, AppColors.tertiary)),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Category Filter Chips
          if (report != null && report.issues.isNotEmpty) ...[
            Text('Issues & Suggestions (${report.issues.where((i) => !i.isAccepted && !i.isRejected).length})',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primarySurface,
                      backgroundColor: AppColors.surface,
                      labelStyle: AppTypography.labelSmall.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Filtered Issues List
            ..._filterIssues(report.issues.where((i) => !i.isAccepted && !i.isRejected).toList(), _selectedCategory)
                .map((issue) => _buildLiveIssueCard(issue)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIssueCard(WritingIssue issue) {
    final color = _getIssueColor(issue.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  issue.type.name.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
                onPressed: () => _rejectLiveIssue(issue),
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Replace: ', style: TextStyle(color: AppColors.textTertiary)),
                TextSpan(
                  text: issue.originalText,
                  style: const TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough, color: AppColors.riskCritical),
                ),
                const TextSpan(text: '  ➔  ', style: TextStyle(color: AppColors.textTertiary)),
                TextSpan(
                  text: issue.suggestedReplacement,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.riskSafe),
                ),
              ],
            ),
            style: AppTypography.bodySmall,
          ),
          if (issue.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(issue.explanation, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _acceptLiveIssue(issue),
              icon: const Icon(Icons.check_rounded, size: 14),
              label: const Text('Apply Fix'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 2: SCANNED DOCUMENTS HUB
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildScannedDocumentTab() {
    final recentScansAsync = ref.watch(recentScansProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(recentScansProvider),
      child: recentScansAsync.when(
        loading: () => _buildScansSkeletonList(),
        error: (err, _) => _buildScansErrorView(err),
        data: (scans) {
          if (scans.isEmpty) {
            return _buildScansEmptyView();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: scans.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Scanned Papers (${scans.length})',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextButton.icon(
                        onPressed: () => ref.refresh(recentScansProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }

              final scan = scans[index - 1];
              return _buildDocumentCard(scan);
            },
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(ScanResult scan) {
    final isSafe = scan.overallSimilarityScore < 20;
    final riskColor = isSafe ? AppColors.riskSafe : (scan.overallSimilarityScore < 50 ? AppColors.riskMedium : AppColors.riskCritical);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.title,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scanned ${scan.timeAgo} • ${scan.totalFlaggedSections} flagged section${scan.totalFlaggedSections == 1 ? '' : 's'}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${scan.originalityScore.round()}% Original',
                  style: AppTypography.labelSmall.copyWith(color: riskColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Scores Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Originality', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: 2),
                    Text('${scan.originalityScore.round()}%', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: riskColor)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Writing Quality', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: 2),
                    Text('${(scan.overallWritingScore ?? 75).round()}/100', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: 2),
                    Text(
                      scan.status.name.toUpperCase(),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scan.isCompleted ? AppColors.riskSafe : (scan.hasFailed ? AppColors.riskCritical : AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/scan/result/${scan.id}'),
                  icon: const Icon(Icons.assessment_outlined, size: 16),
                  label: const Text('View Analysis'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _coachScannedDocument(scan),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Coach Paper'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScansEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('No Scanned Documents Yet', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Upload or scan an academic paper to get full plagiarism breakdown and deep writing guidance.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Start New Scan',
              icon: Icons.upload_file_rounded,
              onPressed: () => context.go('/scan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScansErrorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.riskCritical),
            const SizedBox(height: 16),
            Text('Unable to Load Documents', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'We encountered an issue communicating with the server. Please check your internet connection.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(recentScansProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScansSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: double.infinity, height: 16, color: AppColors.borderLight),
                      const SizedBox(height: 6),
                      Container(width: 120, height: 12, color: AppColors.borderLight),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 36, color: AppColors.borderLight),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 3: CONVERSATIONAL ACADEMIC COACH
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildConversationalCoachTab() {
    final chatState = ref.watch(coachChatProvider);
    final chatNotifier = ref.read(coachChatProvider.notifier);

    return Column(
      children: [
        // Active Document Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently Analyzing:',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                    Text(
                      chatState.activeDocumentTitle,
                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _tabController.animateTo(1),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: const Text('Change'),
              ),
            ],
          ),
        ),

        // Messages Stream
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(20),
            itemCount: chatState.messages.length,
            itemBuilder: (context, index) {
              final msg = chatState.messages[index];
              return _buildChatMessageBubble(msg);
            },
          ),
        ),

        // Quick Prompt Suggestions (shown when not generating)
        if (!chatState.isGenerating)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickCoachPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(prompt),
                      avatar: const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primary),
                      backgroundColor: AppColors.surface,
                      labelStyle: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                      onPressed: () {
                        chatNotifier.sendMessage(prompt);
                        _scrollToBottom();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ask your coach about this paper…',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty && !chatState.isGenerating) {
                        chatNotifier.sendMessage(val.trim());
                        _chatInputController.clear();
                        _scrollToBottom();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: chatState.isGenerating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: chatState.isGenerating
                      ? null
                      : () {
                          final text = _chatInputController.text.trim();
                          if (text.isNotEmpty) {
                            chatNotifier.sendMessage(text);
                            _chatInputController.clear();
                            _scrollToBottom();
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessageBubble(CoachMessage msg) {
    final isUser = msg.sender == MessageSender.user;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18).copyWith(bottomRight: Radius.zero),
          ),
          child: Text(
            msg.content,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white, height: 1.5),
          ),
        ),
      );
    }

    // Thinking indicator
    if (msg.isThinking) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 32),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: Radius.zero),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Coach is reviewing your draft against academic criteria…',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Error message bubble
    if (msg.error != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.riskCriticalLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.riskCritical.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.riskCritical, size: 18),
                  const SizedBox(width: 8),
                  Text('Inquiry Error', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.riskCritical)),
                ],
              ),
              const SizedBox(height: 6),
              Text(msg.content, style: AppTypography.bodySmall),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => ref.read(coachChatProvider.notifier).retryLastMessage(),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Retry Inquiry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.riskCritical,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Full Coach Response Card
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, right: 24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20).copyWith(bottomLeft: Radius.zero),
          border: Border.all(color: AppColors.primarySurface),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Academic Coach',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              msg.content,
              style: AppTypography.bodyMedium.copyWith(height: 1.6, color: AppColors.textPrimary),
            ),

            // Strengths
            if (msg.strengths.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Identified Strengths:', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.riskSafe)),
              const SizedBox(height: 6),
              ...msg.strengths.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.riskSafe),
                        const SizedBox(width: 6),
                        Expanded(child: Text(s, style: AppTypography.bodySmall)),
                      ],
                    ),
                  )),
            ],

            // Recommendations
            if (msg.recommendations.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Recommended Actions:', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 6),
              ...msg.recommendations.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(r, style: AppTypography.bodySmall)),
                      ],
                    ),
                  )),
            ],

            // Suggested revision
            if (msg.suggestedRevision != null && msg.suggestedRevision!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Suggested Scholarly Phrasing:', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  msg.suggestedRevision!,
                  style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic, height: 1.5),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: msg.suggestedRevision!));
                      AppSnackbar.showSuccess(context, 'Revision copied to clipboard!');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _editorController.text = msg.suggestedRevision!;
                      _tabController.animateTo(0);
                      _runLiveAnalysis();
                      AppSnackbar.showSuccess(context, 'Revision applied to Live Editor!');
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Apply to Editor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],

            // Citation advice
            if (msg.citationAdvice != null && msg.citationAdvice!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Citation & Literature Grounding:', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.tertiary)),
              const SizedBox(height: 4),
              Text(
                msg.citationAdvice!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<WritingIssue> _filterIssues(List<WritingIssue> issues, String category) {
    if (category == 'All') return issues;
    if (category == 'Grammar') return issues.where((i) => i.type == WritingIssueType.grammar || i.type == WritingIssueType.spelling).toList();
    if (category == 'Clarity') return issues.where((i) => i.type == WritingIssueType.clarity).toList();
    if (category == 'Academic Tone') return issues.where((i) => i.type == WritingIssueType.academicTone).toList();
    if (category == 'Vocabulary') return issues.where((i) => i.type == WritingIssueType.vocabulary).toList();
    if (category == 'Conciseness') return issues.where((i) => i.type == WritingIssueType.conciseness).toList();
    if (category == 'Citations') return issues.where((i) => i.type == WritingIssueType.citationNeeded).toList();
    return issues;
  }

  Color _getIssueColor(WritingIssueType type) {
    switch (type) {
      case WritingIssueType.grammar:
      case WritingIssueType.spelling:
        return AppColors.riskCritical;
      case WritingIssueType.academicTone:
        return AppColors.primary;
      case WritingIssueType.vocabulary:
        return AppColors.tertiary;
      case WritingIssueType.clarity:
        return AppColors.riskMedium;
      case WritingIssueType.conciseness:
        return AppColors.accent;
      case WritingIssueType.citationNeeded:
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }
}
