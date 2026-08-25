class AppConstants {
  AppConstants._();

  // Supabase — populated from .env at app startup in main.dart
  static const supabaseUrl = 'https://nzawcebunfbwhrwfyrjz.supabase.co';
  static String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56YXdjZWJ1bmZid2hyd2Z5cmp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyODUzNDksImV4cCI6MjEwMDg2MTM0OX0.Ew3eJIyvdOHMTWttpEXqFif5TqOXSkWKi4PPybZobrM';
  static const authRedirectUrl = 'academiccoach://auth-callback';

  // Hive boxes
  static const cacheBoxName = 'awc_cache';
  static const draftsBoxName = 'awc_drafts';

  // Storage buckets
  static const documentsBucket = 'documents';
  static const avatarsBucket = 'avatars';
  static const reportsBucket = 'reports';
  static const ocrImagesBucket = 'ocr-images';

  // Plagiarism thresholds
  static const lowRiskThreshold = 15.0;
  static const mediumRiskThreshold = 30.0;
  static const highRiskThreshold = 50.0;
  static const criticalRiskThreshold = 70.0;

  // AI detection thresholds
  static const aiDetectionThreshold = 60.0;
  static const mixedContentThreshold = 30.0;

  // Animation durations
  static const animFast = Duration(milliseconds: 150);
  static const animNormal = Duration(milliseconds: 300);
  static const animSlow = Duration(milliseconds: 600);
  static const animXSlow = Duration(milliseconds: 1000);

  // Max file size (50 MB)
  static const maxFileSizeBytes = 52428800;

  // Pagination
  static const pageSize = 20;
}
