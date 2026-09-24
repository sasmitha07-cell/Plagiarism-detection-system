import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _messageController = TextEditingController();
  final _subjectController = TextEditingController();
  int? _expandedIndex;

  static const _faqs = [
    _Faq(
      q: 'How accurate is the plagiarism detection?',
      a: 'Our AI engine uses semantic similarity matching combined with Gemini\'s language understanding. '
          'We detect exact copies, paraphrased content, and AI-generated text with high accuracy. '
          'Results should be used as a guide alongside your own judgment.',
    ),
    _Faq(
      q: 'What file formats are supported?',
      a: 'You can upload PDF, DOCX, DOC, TXT, and RTF files up to 50 MB. '
          'You can also paste text directly, record voice input, or scan a document using your camera.',
    ),
    _Faq(
      q: 'Is my submitted content stored or shared?',
      a: 'Your documents are stored securely in your private account and are never shared with third parties. '
          'You can delete any document from your history at any time. '
          'See our Privacy Policy for full details.',
    ),
    _Faq(
      q: 'How do I improve my plagiarism score?',
      a: 'Use the Writing Coach to rephrase flagged sections, add proper citations for matched content, '
          'and run the document again. The coach will guide you step-by-step.',
    ),
    _Faq(
      q: 'Can I compare two of my own documents?',
      a: 'Yes! Navigate to the Compare tab at the bottom of the screen and upload two documents. '
          'The system will generate a side-by-side similarity report.',
    ),
    _Faq(
      q: 'Does the app work offline?',
      a: 'Basic text editing is available offline, but plagiarism scanning and AI analysis require '
          'an active internet connection to communicate with our servers.',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),

                  // Hero banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientHero,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How can we help?',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Browse FAQs or send us a message.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white38,
                          size: 64,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // FAQ section
                  Text(
                    'Frequently Asked Questions',
                    style: AppTypography.titleLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 16),

                  ..._faqs.asMap().entries.map((e) {
                    final i = e.key;
                    final faq = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FaqTile(
                        faq: faq,
                        isExpanded: _expandedIndex == i,
                        onTap: () => setState(() {
                          _expandedIndex = _expandedIndex == i ? null : i;
                        }),
                      ).animate().fadeIn(delay: Duration(milliseconds: 200 + i * 60)),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Contact form
                  Text(
                    'Contact Support',
                    style: AppTypography.titleLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 8),
                  Text(
                    'We typically respond within 24 hours.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ).animate().fadeIn(delay: 650.ms),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowCard,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            labelText: 'Subject',
                            prefixIcon: const Icon(Icons.subject_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Message',
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 64),
                              child: Icon(Icons.message_outlined),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send_rounded),
                            label: const Text('Send Message'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),

                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in subject and message.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _subjectController.clear();
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message sent! We\'ll be in touch shortly.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FaqTile({
    required this.faq,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isExpanded ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? AppColors.primaryBorder : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.question_mark_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              title: Text(
                faq.q,
                style: AppTypography.titleSmall.copyWith(
                  color: isExpanded ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              trailing: AnimatedRotation(
                duration: const Duration(milliseconds: 250),
                turns: isExpanded ? 0.5 : 0,
                child: const Icon(Icons.expand_more_rounded,
                    color: AppColors.textTertiary),
              ),
            ),
            if (isExpanded)
              Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  faq.a,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
