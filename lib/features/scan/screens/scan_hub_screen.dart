import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/scan_method_card.dart';

class ScanHubScreen extends StatelessWidget {
  const ScanHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Scan'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Input Method',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 8),
              
              Text(
                'How would you like to provide the text for analysis?',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 150.ms),
              
              const SizedBox(height: 32),
              
              // Grid of methods
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  ScanMethodCard(
                    icon: Icons.edit_document,
                    title: 'Paste Text',
                    description: 'Type or paste content directly',
                    color: AppColors.primary,
                    onTap: () => context.go('/scan/text'),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  
                  ScanMethodCard(
                    icon: Icons.upload_file_rounded,
                    title: 'Upload File',
                    description: 'PDF, DOCX, TXT, or RTF',
                    color: AppColors.tertiary,
                    onTap: () => context.go('/scan/upload'),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
                  
                  ScanMethodCard(
                    icon: Icons.mic_rounded,
                    title: 'Voice Input',
                    description: 'Speak and transcribe live',
                    color: AppColors.accent,
                    onTap: () => context.go('/scan/voice'),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  
                  ScanMethodCard(
                    icon: Icons.document_scanner_rounded,
                    title: 'Scan Image',
                    description: 'Extract text from photos',
                    color: AppColors.secondary,
                    onTap: () => context.go('/scan/ocr'),
                  ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
