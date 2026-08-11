import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/gradient_button.dart';

class CitationScreen extends ConsumerStatefulWidget {
  const CitationScreen({super.key});

  @override
  ConsumerState<CitationScreen> createState() => _CitationScreenState();
}

class _CitationScreenState extends ConsumerState<CitationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _dateController = TextEditingController();
  final _publisherController = TextEditingController();

  String _selectedStyle = 'APA';
  final List<String> _styles = ['APA', 'MLA', 'Chicago', 'Harvard'];
  
  String? _generatedCitation;
  bool _isGenerating = false;

  @override
  void dispose() {
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

    // Simulate API/Generation delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final date = _dateController.text.trim();
    final url = _urlController.text.trim();
    final publisher = _publisherController.text.trim();

    String result = '';
    
    // Mock basic formatting logic
    switch (_selectedStyle) {
      case 'APA':
        result = '${author.isNotEmpty ? '$author.' : ''} (${date.isNotEmpty ? date : 'n.d.'}). $title. ${publisher.isNotEmpty ? '$publisher.' : ''} ${url.isNotEmpty ? 'Retrieved from $url' : ''}';
        break;
      case 'MLA':
        result = '${author.isNotEmpty ? '$author.' : ''} "$title." ${publisher.isNotEmpty ? '$publisher,' : ''} ${date.isNotEmpty ? date : ''}. ${url.isNotEmpty ? url : ''}';
        break;
      case 'Chicago':
        result = '${author.isNotEmpty ? '$author.' : ''} "$title." ${publisher.isNotEmpty ? '$publisher,' : ''} ${date.isNotEmpty ? date : ''}. ${url.isNotEmpty ? url : ''}';
        break;
      case 'Harvard':
        result = '${author.isNotEmpty ? '$author,' : ''} ${date.isNotEmpty ? '($date)' : '(n.d.)'} \'$title\', ${publisher.isNotEmpty ? '$publisher,' : ''} available at: $url';
        break;
    }

    setState(() {
      _isGenerating = false;
      _generatedCitation = result.trim().replaceAll(RegExp(r'\s+'), ' ');
    });
  }

  void _copyToClipboard() {
    if (_generatedCitation != null) {
      Clipboard.setData(ClipboardData(text: _generatedCitation!));
      AppSnackbar.showSuccess(context, 'Citation copied to clipboard');
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _clearForm,
            tooltip: 'Clear Form',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
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
                      SegmentedButton<String>(
                        segments: _styles.map((style) => ButtonSegment<String>(
                          value: style,
                          label: Text(style),
                        )).toList(),
                        selected: {_selectedStyle},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedStyle = newSelection.first;
                          });
                          if (_generatedCitation != null) {
                            _generateCitation(); // Regenerate if already generated
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primarySurface;
                            }
                            return AppColors.surface;
                          }),
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
                        label: 'URL (Webpage link)',
                        icon: Icons.link_rounded,
                        isOptional: true,
                      ).animate().fadeIn().slideX(begin: 0.1),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _titleController,
                        label: 'Title of Article / Page',
                        icon: Icons.title_rounded,
                        validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                      ).animate().fadeIn().slideX(begin: 0.1, delay: 50.ms),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _authorController,
                        label: 'Author(s) (Last, First)',
                        icon: Icons.person_outline_rounded,
                        isOptional: true,
                      ).animate().fadeIn().slideX(begin: 0.1, delay: 100.ms),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _dateController,
                              label: 'Published Date',
                              icon: Icons.calendar_today_rounded,
                              isOptional: true,
                            ).animate().fadeIn().slideX(begin: 0.1, delay: 150.ms),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _publisherController,
                              label: 'Publisher / Site',
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
                      ).animate().fadeIn(delay: 300.ms),
                      
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
                            Text(
                              'Generated Citation',
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
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
                                  Text(
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
                                      TextButton.icon(
                                        onPressed: _copyToClipboard,
                                        icon: const Icon(Icons.copy_rounded, size: 18),
                                        label: const Text('Copy'),
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
            ],
          ),
        ),
      ),
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
