class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? institution;
  final String? department;
  final String? academicLevel;
  final String? avatarUrl;
  final String? bio;
  final int totalScans;
  final int totalDocuments;
  final double averageSimilarityScore;
  final double averageWritingScore;
  final int zeroPlagiarismStreak;
  final bool isAdmin;
  final bool onboardingCompleted;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.institution,
    this.department,
    this.academicLevel,
    this.avatarUrl,
    this.bio,
    this.totalScans = 0,
    this.totalDocuments = 0,
    this.averageSimilarityScore = 0,
    this.averageWritingScore = 0,
    this.zeroPlagiarismStreak = 0,
    this.isAdmin = false,
    this.onboardingCompleted = false,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      institution: json['institution'] as String?,
      department: json['department'] as String?,
      academicLevel: json['academic_level'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      totalScans: json['total_scans'] as int? ?? 0,
      totalDocuments: json['total_documents'] as int? ?? 0,
      averageSimilarityScore:
          (json['average_similarity_score'] as num?)?.toDouble() ?? 0,
      averageWritingScore:
          (json['average_writing_score'] as num?)?.toDouble() ?? 0,
      zeroPlagiarismStreak: json['zero_plagiarism_streak'] as int? ?? 0,
      isAdmin: json['is_admin'] as bool? ?? false,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'institution': institution,
      'department': department,
      'academic_level': academicLevel,
      'avatar_url': avatarUrl,
      'bio': bio,
      'is_admin': isAdmin,
      'onboarding_completed': onboardingCompleted,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? institution,
    String? department,
    String? academicLevel,
    String? avatarUrl,
    String? bio,
    bool? onboardingCompleted,
    int? totalScans,
    int? totalDocuments,
    double? averageSimilarityScore,
    double? averageWritingScore,
    int? zeroPlagiarismStreak,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      institution: institution ?? this.institution,
      department: department ?? this.department,
      academicLevel: academicLevel ?? this.academicLevel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      totalScans: totalScans ?? this.totalScans,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      averageSimilarityScore:
          averageSimilarityScore ?? this.averageSimilarityScore,
      averageWritingScore: averageWritingScore ?? this.averageWritingScore,
      zeroPlagiarismStreak:
          zeroPlagiarismStreak ?? this.zeroPlagiarismStreak,
      isAdmin: isAdmin,
      onboardingCompleted:
          onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
    );
  }

  String get displayName => (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email.split('@').first;
  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }

  String get academicLevelFormatted {
    switch (academicLevel?.toLowerCase()) {
      case 'high_school':
        return 'High School';
      case 'undergraduate':
        return 'Undergraduate';
      case 'graduate':
        return 'Graduate';
      case 'doctorate':
        return 'Doctorate / PhD';
      case 'faculty':
        return 'Faculty';
      case 'researcher':
        return 'Researcher';
      case 'other':
        return 'Other';
      default:
        return academicLevel ?? 'Undergraduate';
    }
  }
}
