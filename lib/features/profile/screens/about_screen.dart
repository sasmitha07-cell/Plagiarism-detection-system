import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.0.0 (Build 1)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About'),
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
                  const SizedBox(height: 24),

                  // App logo / hero
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientHero,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Academic Writing Coach',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Version $_version',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryBorder),
                          ),
                          child: Text(
                            'Powered by Gemini AI',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).scale(curve: Curves.easeOutBack),

                  const SizedBox(height: 40),

                  // Mission statement
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF8EC), Color(0xFFF9F6F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentLighter),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.accent, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Empowering students and researchers to write '
                            'with integrity, clarity, and confidence.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // Key features
                  Text(
                    'What We Offer',
                    style: AppTypography.titleLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 16),

                  ..._features.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FeatureTile(feature: e.value)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 300 + e.key * 60))
                          .slideX(begin: 0.1),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Legal links
                  Text(
                    'Legal',
                    style: AppTypography.titleLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 12),

                  _LinkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showNotImpl(context),
                  ).animate().fadeIn(delay: 650.ms),
                  const SizedBox(height: 8),
                  _LinkTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => _showNotImpl(context),
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 8),
                  _LinkTile(
                    icon: Icons.integration_instructions_outlined,
                    title: 'Open Source Licences',
                    onTap: () => showLicensePage(context: context),
                  ).animate().fadeIn(delay: 750.ms),

                  const SizedBox(height: 48),

                  Center(
                    child: Text(
                      '© 2025 Academic Writing Coach.\nAll rights reserved.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textDisabled,
                        height: 1.8,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showNotImpl(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening in browser…'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

const _features = [
  _Feature(
    icon: Icons.plagiarism_rounded,
    color: AppColors.secondary,
    title: 'AI Plagiarism Detection',
    description: 'Detect exact copies, paraphrased content, and AI-generated text.',
  ),
  _Feature(
    icon: Icons.psychology_rounded,
    color: AppColors.tertiary,
    title: 'AI Content Detection',
    description: 'Identify GPT-generated sections with confidence scores.',
  ),
  _Feature(
    icon: Icons.auto_fix_high_rounded,
    color: AppColors.accent,
    title: 'Writing Coach',
    description: 'Get personalised suggestions to improve grammar, tone, and style.',
  ),
  _Feature(
    icon: Icons.compare_arrows_rounded,
    color: AppColors.primary,
    title: 'Document Comparison',
    description: 'Compare two documents side-by-side with semantic matching.',
  ),
  _Feature(
    icon: Icons.format_quote_rounded,
    color: Color(0xFF4A3F78),
    title: 'Citation Generator',
    description: 'Generate APA, MLA, IEEE, Harvard, and Chicago citations instantly.',
  ),
];

class _Feature {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  const _FeatureTile({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title, style: AppTypography.titleSmall),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _LinkTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: AppTypography.titleSmall),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
