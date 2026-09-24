import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';

final savedCitationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final client = Supabase.instance.client;
  final data = await client
      .from('citations')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(data as List);
});

class CitationScreen extends ConsumerStatefulWidget {
  const CitationScreen({super.key});

  @override
  ConsumerState<CitationScreen> createState() => _CitationScreenState();
}

class _CitationScreenState extends ConsumerState<CitationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _dateController = TextEditingController();
  final _publisherController = TextEditingController();

  String _selectedStyle = 'APA';
  final List<String> _styles = ['APA', 'MLA', 'Chicago', 'Harvard', 'IEEE'];

  String? _generatedCitation;
  bool _isGenerating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _dateController.dispose();
    _publisherController.dispose();
    super.dispose();
  }

  Future<void> _generateCitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _generatedCitation = null;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final date = _dateController.text.trim();
    final url = _urlController.text.trim();
    final publisher = _publisherController.text.trim();

    String result = '';

    switch (_selectedStyle) {
      case 'APA':
        result =
            '${author.isNotEmpty ? '$author.' : ''} (${date.isNotEmpty ? date : 'n.d.'}). $title. ${publisher.isNotEmpty ? '$publisher.' : ''} ${url.isNotEmpty ? 'Retrieved from $url' : ''}';
        break;
      case 'MLA':
        result =
            '${author.isNotEmpty ? '$author.' : ''} "$title." ${publisher.isNotEmpty ? '$publisher,' : ''} ${date.isNotEmpty ? date : 'n.d.'}. ${url.isNotEmpty ? url : ''}';
        break;
      case 'Chicago':
        result =
            '${author.isNotEmpty ? '$author.' : ''} "$title." ${publisher.isNotEmpty ? '$publisher,' : ''} ${date.isNotEmpty ? date : 'n.d.'}. ${url.isNotEmpty ? url : ''}';
        break;
      case 'Harvard':
        result =
            '${author.isNotEmpty ? '$author,' : ''} ${date.isNotEmpty ? '($date)' : '(n.d.)'} \'$title\', ${publisher.isNotEmpty ? '$publisher,' : ''} available at: $url';
        break;
      case 'IEEE':
        result =
            '${author.isNotEmpty ? '$author, ' : ''}"$title," ${publisher.isNotEmpty ? '$publisher, ' : ''}${date.isNotEmpty ? '$date. ' : ''}${url.isNotEmpty ? '[Online]. Available: $url' : ''}';
        break;
    }

    setState(() {
      _isGenerating = false;
      _generatedCitation = result.trim().replaceAll(RegExp(r'\s+'), ' ');
    });
  }

  Future<void> _saveCitation() async {
    if (_generatedCitation == null) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      AppSnackbar.showError(context, 'Please sign in to save citations.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      await client.from('citations').insert({
        'user_id': userId,
        'style': _selectedStyle.toLowerCase(),
        'source_type': 'web',
        'title': _titleController.text.trim(),
        'authors': [_authorController.text.trim()],
        'publication_date': _dateController.text.trim(),
        'publisher': _publisherController.text.trim(),
        'url': _urlController.text.trim(),
        'formatted_citation': _generatedCitation,
      });

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Citation saved to your library!');
        ref.invalidate(savedCitationsProvider);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Failed to save citation: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.showSuccess(context, 'Copied to clipboard');
  }

  void _clearForm() {
    _urlController.clear();
    _titleController.clear();
    _authorController.clear();
    _dateController.clear();
    _publisherController.clear();
    setState(() {
      _generatedCitation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Citation Generator'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _clearForm,
            tooltip: 'Clear Form',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.format_quote_rounded, size: 18), text: 'Generator'),
            Tab(icon: Icon(Icons.library_books_rounded, size: 18), text: 'Saved Library'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneratorTab(),
          _buildSavedLibraryTab(),
        ],
      ),
    );
  }

  Widget _buildGeneratorTab() {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Style Selector
              Text(
                'Citation Style',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ).animate().fadeIn(),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _styles.map((style) {
                    final isSelected = _selectedStyle == style;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(style),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedStyle = style);
                            if (_generatedCitation != null) _generateCitation();
                          }
                        },
                        selectedColor: AppColors.primarySurface,
                        backgroundColor: AppColors.surface,
                        labelStyle: AppTypography.labelMedium.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Form Fields
              Text(
                'Source Details',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ).animate().fadeIn(),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _urlController,
                label: 'URL (Webpage or DOI link)',
                icon: Icons.link_rounded,
                isOptional: true,
              ).animate().fadeIn().slideX(begin: 0.1),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _titleController,
                label: 'Title of Article / Book / Page',
                icon: Icons.title_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              ).animate().fadeIn().slideX(begin: 0.1, delay: 50.ms),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _authorController,
                label: 'Author(s) (e.g. Smith, John or Harvard University)',
                icon: Icons.person_outline_rounded,
                isOptional: true,
              ).animate().fadeIn().slideX(begin: 0.1, delay: 100.ms),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _dateController,
                      label: 'Published Year / Date',
                      icon: Icons.calendar_today_rounded,
                      isOptional: true,
                    ).animate().fadeIn().slideX(begin: 0.1, delay: 150.ms),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _publisherController,
                      label: 'Publisher / Journal',
                      icon: Icons.business_rounded,
                      isOptional: true,
                    ).animate().fadeIn().slideX(begin: 0.1, delay: 200.ms),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Generate Button
              GradientButton(
                text: 'Generate Citation',
                icon: Icons.auto_awesome_rounded,
                onPressed: _isGenerating ? null : _generateCitation,
                gradient: AppColors.gradientHero,
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 32),

              // Result Section
              if (_isGenerating)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ).animate().fadeIn()
              else if (_generatedCitation != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_selectedStyle Formatted Citation',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_selectedStyle, style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primarySurface),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowCard,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SelectableText(
                            _generatedCitation!,
                            style: AppTypography.bodyMedium.copyWith(
                              height: 1.6,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isSaving ? null : _saveCitation,
                                icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                                label: Text(_isSaving ? 'Saving...' : 'Save to Library'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _copyToClipboard(_generatedCitation!),
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Copy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedLibraryTab() {
    final citationsAsync = ref.watch(savedCitationsProvider);

    return citationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading citations: $e')),
      data: (citations) {
        if (citations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.format_quote_rounded, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No Saved Citations', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Generate citations and tap "Save to Library" to build your bibliography.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: citations.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bibliography (${citations.length})',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final fullBib = citations.map((c) => c['formatted_citation'] as String? ?? '').where((s) => s.isNotEmpty).join('\n\n');
                        _copyToClipboard(fullBib);
                      },
                      icon: const Icon(Icons.copy_all_rounded, size: 16),
                      label: const Text('Copy All'),
                    ),
                  ],
                ),
              );
            }

            final c = citations[index - 1];
            final citText = c['formatted_citation'] as String? ?? c['title'] as String? ?? '';
            final style = (c['style'] as String? ?? 'apa').toUpperCase();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(style, style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.riskCritical, size: 18),
                        onPressed: () async {
                          final id = c['id'] as String;
                          await Supabase.instance.client.from('citations').delete().eq('id', id);
                          ref.invalidate(savedCitationsProvider);
                          if (context.mounted) {
                            AppSnackbar.showSuccess(context, 'Citation deleted');
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(citText, style: AppTypography.bodySmall.copyWith(height: 1.5)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _copyToClipboard(citText),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isOptional = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (isOptional ? ' (Optional)' : ''),
        prefixIcon: Icon(icon),
      ),
      validator: validator,
      style: AppTypography.bodyMedium,
    );
  }
}
