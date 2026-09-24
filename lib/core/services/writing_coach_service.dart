import 'dart:math';
import 'document_extraction_service.dart';
import 'citation_detector.dart';

enum WritingIssueType {
  grammar,
  spelling,
  clarity,
  academicTone,
  vocabulary,
  style,
  conciseness,
  structure,
  citationNeeded,
}

class WritingIssue {
  final String id;
  final WritingIssueType type;
  final String title;
  final String originalText;
  final String suggestedReplacement;
  final String explanation;
  final int startOffset;
  final int endOffset;
  final String severity; // low, medium, high
  bool isAccepted;
  bool isRejected;

  WritingIssue({
    required this.id,
    required this.type,
    required this.title,
    required this.originalText,
    required this.suggestedReplacement,
    required this.explanation,
    required this.startOffset,
    required this.endOffset,
    this.severity = 'medium',
    this.isAccepted = false,
    this.isRejected = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'original_text': originalText,
        'suggested_replacement': suggestedReplacement,
        'explanation': explanation,
        'start_offset': startOffset,
        'end_offset': endOffset,
        'severity': severity,
      };

  factory WritingIssue.fromJson(Map<String, dynamic> j) => WritingIssue(
        id: j['id'] as String? ?? 'iss_${DateTime.now().microsecondsSinceEpoch}',
        type: WritingIssueType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => WritingIssueType.clarity,
        ),
        title: j['title'] as String? ?? 'Writing Suggestion',
        originalText: j['original_text'] as String? ?? '',
        suggestedReplacement: j['suggested_replacement'] as String? ?? '',
        explanation: j['explanation'] as String? ?? '',
        startOffset: (j['start_offset'] as num?)?.toInt() ?? 0,
        endOffset: (j['end_offset'] as num?)?.toInt() ?? 0,
        severity: j['severity'] as String? ?? 'medium',
      );
}

class WritingAnalysisReport {
  final double overallScore;
  final double grammarScore;
  final double clarityScore;
  final double academicToneScore;
  final double vocabularyScore;
  final double structureScore;
  final double citationQualityScore;
  final double readabilityScore; // Flesch Reading Ease (0 - 100)
  final double gradeLevel; // Flesch-Kincaid Grade Level
  final double avgSentenceLength;
  final double passiveVoicePercentage;
  final double academicWordPercentage;
  final int totalWordCount;
  final int totalSentenceCount;
  final List<WritingIssue> issues;
  final List<String> strengthPoints;
  final List<String> improvementTips;

  const WritingAnalysisReport({
    required this.overallScore,
    required this.grammarScore,
    required this.clarityScore,
    required this.academicToneScore,
    required this.vocabularyScore,
    this.structureScore = 80.0,
    this.citationQualityScore = 85.0,
    required this.readabilityScore,
    required this.gradeLevel,
    required this.avgSentenceLength,
    required this.passiveVoicePercentage,
    required this.academicWordPercentage,
    required this.totalWordCount,
    required this.totalSentenceCount,
    required this.issues,
    required this.strengthPoints,
    required this.improvementTips,
  });
}

class WritingCoachService {
  WritingCoachService._();
  static final instance = WritingCoachService._();

  // Academic dictionary mapping informal words/phrases to elevated scholarly equivalents
  static const Map<String, (String, String)> _academicReplacements = {
    'a lot of': ('numerous / substantial', 'Use precise academic quantifiers rather than conversational terms.'),
    'lots of': ('numerous / extensive', 'Replace casual quantifier with academic alternative.'),
    'kids': ('children / adolescents', 'Use formal demographic terminology in scholarly writing.'),
    'huge': ('immense / substantial', 'Elevate casual adjectives to formal academic vocabulary.'),
    'get': ('acquire / obtain', 'Use formal transitive verbs instead of informal "get".'),
    'show': ('demonstrate / indicate', '"Demonstrate" or "indicate" conveys scientific precision.'),
    'bad': ('detrimental / adverse', 'Use precise evaluative vocabulary in academic contexts.'),
    'good': ('beneficial / advantageous', 'Use specific qualitative descriptors.'),
    'thing': ('factor / concept / variable', '"Thing" is vague; specify the exact subject or phenomenon.'),
    'things': ('factors / concepts / variables', 'Specify concrete subject matter rather than using "things".'),
    'look into': ('investigate / examine', 'Use formal academic verbs instead of phrasal verbs.'),
    'find out': ('determine / ascertain', 'Use formal academic verbs for research outcomes.'),
    'make sure': ('ensure / verify', 'Use formal academic terminology for procedural rigor.'),
    'big': ('substantial / significant', 'Quantify or use precise descriptive terms.'),
    'really': ('exceptionally / markedly', 'Avoid informal intensifiers; use precise academic qualifiers.'),
    'very': ('substantially / notably', 'Avoid weak intensifiers; choose stronger descriptive adjectives.'),
    'totally': ('entirely / completely', 'Avoid conversational colloquial adverbs.'),
    'kind of': ('moderately / to some extent', 'Express degree with precise academic nuance.'),
    'sort of': ('partially / to a degree', 'Express degree with formal hedging.'),
    'in my opinion': ('the evidence indicates', 'Avoid subjective first-person declarations in objective research.'),
    'i think': ('it is hypothesized / evidence suggests', 'Anchor claims to literature or observable evidence.'),
    'i believe': ('the data suggests', 'Frame statements around empirical data rather than personal belief.'),
    'crazy': ('unprecedented / anomalous', 'Use clinical, objective terminology.'),
    'stuff': ('material / components / data', 'Use specific domain-appropriate nouns.'),
    'deal with': ('address / manage', 'Use formal academic verb phrases.'),
    'put together': ('synthesize / compile', 'Use scholarly terminology for assembly of ideas or datasets.'),
  };

  // Conciseness & Redundancy dictionary
  static const Map<String, (String, String)> _concisenessReplacements = {
    'in order to': ('to', 'Concise phrasing: "to" carries the exact same meaning with zero redundancy.'),
    'due to the fact that': ('because', '"Because" is direct and eliminates wordy clutter.'),
    'at this point in time': ('currently / now', 'Simplify time expressions for clarity and rhythm.'),
    'for the purpose of': ('for / to', 'Simplify verbose prepositional phrases.'),
    'in spite of the fact that': ('although', '"Although" is more concise and reads smoothly.'),
    'a majority of': ('most', 'Direct phrasing strengthens sentence cadence.'),
    'has the capability to': ('can', 'Use direct modal verbs instead of circumlocution.'),
    'is able to': ('can', 'Direct verbs strengthen academic authority.'),
    'take into consideration': ('consider', 'Replace nominalization with a direct active verb.'),
    'make an assumption': ('assume', 'Use the direct verb form for crisp delivery.'),
    'conduct an investigation': ('investigate', 'Avoid bloated verb-noun compounds.'),
  };

  // Grammar & spelling rules
  static final List<({RegExp pattern, String title, String replacement, String explanation, WritingIssueType type})> _grammarRules = [
    (
      pattern: RegExp(r'\b(could|should|would)\s+of\b', caseSensitive: false),
      title: 'Grammar: Incorrect auxiliary verb',
      replacement: r'$1 have',
      explanation: 'Use auxiliary "have" instead of preposition "of" (e.g. "should have").',
      type: WritingIssueType.grammar,
    ),
    (
      pattern: RegExp(r'\b(\w+)\s+\1\b', caseSensitive: false),
      title: 'Grammar: Duplicate consecutive word',
      replacement: r'$1',
      explanation: 'Repeated duplicate word detected. Remove the redundant word.',
      type: WritingIssueType.grammar,
    ),
    (
      pattern: RegExp(r'\bdata\s+is\b', caseSensitive: false),
      title: 'Academic Tone: Plural noun agreement',
      replacement: 'data are',
      explanation: 'In formal scientific and academic writing, "data" is treated as plural ("data are").',
      type: WritingIssueType.academicTone,
    ),
    (
      pattern: RegExp(r'\bthese\s+kind\b', caseSensitive: false),
      title: 'Grammar: Plural demonstrative mismatch',
      replacement: 'these kinds / this kind',
      explanation: 'Match plural demonstrative "these" with plural noun "kinds".',
      type: WritingIssueType.grammar,
    ),
    (
      pattern: RegExp(r"\b(their|there|they're)\s+going\s+to\s+be\b", caseSensitive: false),
      title: 'Spelling/Grammar: Homophone check',
      replacement: 'there going to be',
      explanation: 'Ensure correct homophone "there" is used for existence/location.',
      type: WritingIssueType.spelling,
    ),
    (
      pattern: RegExp(r'\bits\s+(a|an|the|clear|evident|important|crucial)\b', caseSensitive: false),
      title: 'Grammar: Contraction vs Possessive',
      replacement: r"it's $1",
      explanation: 'Use "it\'s" (contraction of "it is") rather than possessive "its".',
      type: WritingIssueType.grammar,
    ),
  ];

  /// Performs a complete structured writing analysis of the input text
  Future<WritingAnalysisReport> analyzeText(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return const WritingAnalysisReport(
        overallScore: 100,
        grammarScore: 100,
        clarityScore: 100,
        academicToneScore: 100,
        vocabularyScore: 100,
        structureScore: 100,
        citationQualityScore: 100,
        readabilityScore: 100,
        gradeLevel: 10,
        avgSentenceLength: 15,
        passiveVoicePercentage: 0,
        academicWordPercentage: 20,
        totalWordCount: 0,
        totalSentenceCount: 0,
        issues: [],
        strengthPoints: [],
        improvementTips: [],
      );
    }

    final issues = <WritingIssue>[];

    // 1. Academic Tone & Vocabulary Replacements
    for (final entry in _academicReplacements.entries) {
      final phrase = entry.key;
      final (replacement, explanation) = entry.value;
      final regex = RegExp(r'\b' + RegExp.escape(phrase) + r'\b', caseSensitive: false);
      for (final match in regex.allMatches(cleanText)) {
        issues.add(WritingIssue(
          id: 'tone_${match.start}_${issues.length}',
          type: WritingIssueType.academicTone,
          title: 'Academic Formality',
          originalText: match.group(0)!,
          suggestedReplacement: replacement,
          explanation: explanation,
          startOffset: match.start,
          endOffset: match.end,
          severity: 'medium',
        ));
      }
    }

    // 2. Conciseness & Redundancy Replacements
    for (final entry in _concisenessReplacements.entries) {
      final phrase = entry.key;
      final (replacement, explanation) = entry.value;
      final regex = RegExp(r'\b' + RegExp.escape(phrase) + r'\b', caseSensitive: false);
      for (final match in regex.allMatches(cleanText)) {
        issues.add(WritingIssue(
          id: 'concise_${match.start}_${issues.length}',
          type: WritingIssueType.conciseness,
          title: 'Wordy Phrasing',
          originalText: match.group(0)!,
          suggestedReplacement: replacement,
          explanation: explanation,
          startOffset: match.start,
          endOffset: match.end,
          severity: 'low',
        ));
      }
    }

    // 3. Grammar Rules
    for (final rule in _grammarRules) {
      for (final match in rule.pattern.allMatches(cleanText)) {
        issues.add(WritingIssue(
          id: 'gram_${match.start}_${issues.length}',
          type: rule.type,
          title: rule.title,
          originalText: match.group(0)!,
          suggestedReplacement: rule.replacement,
          explanation: rule.explanation,
          startOffset: match.start,
          endOffset: match.end,
          severity: 'high',
        ));
      }
    }

    // 4. Citation Assistance: Detect uncited claims
    final uncitedClaims = CitationDetector.instance.findUncitedClaims(cleanText);
    for (final claim in uncitedClaims) {
      issues.add(WritingIssue(
        id: 'cite_${claim.startOffset}_${issues.length}',
        type: WritingIssueType.citationNeeded,
        title: 'Evidence / Citation Needed',
        originalText: claim.text,
        suggestedReplacement: '${claim.text} [Citation]',
        explanation: claim.reason,
        startOffset: claim.startOffset,
        endOffset: claim.endOffset,
        severity: 'high',
      ));
    }

    // 5. Sentence Level Checks (Clarity & Length)
    final sentences = DocumentExtractionService.instance.splitIntoSentences(cleanText);
    int passiveCount = 0;

    for (final sentence in sentences) {
      final words = sentence.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final wordCount = words.length;

      // Long sentence check (> 36 words)
      if (wordCount > 36) {
        final startPos = cleanText.indexOf(sentence);
        if (startPos != -1) {
          issues.add(WritingIssue(
            id: 'long_${startPos}_${issues.length}',
            type: WritingIssueType.clarity,
            title: 'Overly Complex Sentence',
            originalText: sentence.length > 80 ? '${sentence.substring(0, 80)}…' : sentence,
            suggestedReplacement: 'Break into 2 shorter, direct sentences',
            explanation: 'This sentence is $wordCount words long. Long sentences increase reader cognitive load and obscure key arguments.',
            startOffset: startPos,
            endOffset: startPos + sentence.length,
            severity: 'medium',
          ));
        }
      }

      // Passive voice detector (is/are/was/were/been/being + ed verb)
      final passiveRegex = RegExp(
        r'\b(is|are|was|were|been|being|be)\s+(\w+ed|\w+en|shown|found|seen|given|made|taken)\b',
        caseSensitive: false,
      );
      if (passiveRegex.hasMatch(sentence)) {
        passiveCount++;
      }
    }

    // 6. Calculate Readability & Metrics
    final totalWords = max(1, DocumentExtractionService.instance.countWords(cleanText));
    final totalSentences = max(1, sentences.length);
    final avgSentenceLength = totalWords / totalSentences;

    int totalSyllables = 0;
    final allWords = cleanText.toLowerCase().split(RegExp(r'[^a-zA-Z]+')).where((w) => w.isNotEmpty);
    for (final w in allWords) {
      totalSyllables += _countSyllables(w);
    }
    final avgSyllablesPerWord = totalSyllables / max(1, allWords.length);

    // Flesch Reading Ease: 206.835 - 1.015 * (words/sentences) - 84.6 * (syllables/words)
    final fleschScore = (206.835 - (1.015 * avgSentenceLength) - (84.6 * avgSyllablesPerWord)).clamp(0.0, 100.0);

    // Flesch-Kincaid Grade: 0.39 * (words/sentences) + 11.8 * (syllables/words) - 15.59
    final gradeLevel = ((0.39 * avgSentenceLength) + (11.8 * avgSyllablesPerWord) - 15.59).clamp(1.0, 20.0);

    final passiveVoicePercentage = (passiveCount / totalSentences * 100).clamp(0.0, 100.0);

    final scholarlyWords = allWords.where((w) => w.length >= 8 || _isAcademicWord(w)).length;
    final academicWordPercentage = (scholarlyWords / totalWords * 100).clamp(0.0, 100.0);

    // Sub-Scores
    final grammarErrors = issues.where((i) => i.type == WritingIssueType.grammar || i.type == WritingIssueType.spelling).length;
    final grammarScore = (100.0 - (grammarErrors * 10.0)).clamp(30.0, 100.0);

    final clarityErrors = issues.where((i) => i.type == WritingIssueType.clarity || i.type == WritingIssueType.conciseness).length;
    final clarityScore = (100.0 - (clarityErrors * 8.0) - (avgSentenceLength > 30 ? 12 : 0)).clamp(35.0, 100.0);

    final toneErrors = issues.where((i) => i.type == WritingIssueType.academicTone).length;
    final academicToneScore = (100.0 - (toneErrors * 7.0) + (academicWordPercentage > 15 ? 10 : 0)).clamp(40.0, 100.0);

    final vocabularyScore = (academicWordPercentage * 3.5 + 40.0).clamp(40.0, 98.0);
    final citationQualityScore = uncitedClaims.isEmpty ? 95.0 : (100.0 - uncitedClaims.length * 15.0).clamp(30.0, 100.0);
    final structureScore = (100.0 - (avgSentenceLength > 32 ? 20 : 0) - (passiveVoicePercentage > 35 ? 15 : 0)).clamp(40.0, 100.0);

    final overallWritingScore = (
      (grammarScore * 0.25) +
      (clarityScore * 0.20) +
      (academicToneScore * 0.20) +
      (vocabularyScore * 0.15) +
      (structureScore * 0.10) +
      (citationQualityScore * 0.10)
    ).clamp(10.0, 100.0);

    // Strengths & Recommendations
    final strengths = <String>[];
    final tips = <String>[];

    if (grammarScore >= 85) strengths.add('Strong grammatical precision and clean syntax mechanics.');
    if (academicToneScore >= 80) strengths.add('Scholarly voice with formal objective framing.');
    if (vocabularyScore >= 75) strengths.add('Diverse and domain-appropriate academic terminology.');
    if (fleschScore >= 50 && fleschScore <= 70) strengths.add('Optimal readability balance for scholarly discourse.');
    if (uncitedClaims.isEmpty) strengths.add('No unsupported empirical claims detected.');

    if (issues.isNotEmpty) {
      tips.add('Address the ${issues.length} flagged suggestions to elevate your paper.');
    }
    if (uncitedClaims.isNotEmpty) {
      tips.add('${uncitedClaims.length} statements make empirical assertions without citations. Add supporting references.');
    }
    if (passiveVoicePercentage > 28) {
      tips.add('Passive voice is present in ${passiveVoicePercentage.toStringAsFixed(0)}% of sentences. Convert key verbs to active voice for stronger argumentative authority.');
    }
    if (avgSentenceLength > 28) {
      tips.add('Average sentence length is high (${avgSentenceLength.toStringAsFixed(1)} words/sent). Introduce shorter declarative sentences to enhance rhythm.');
    }

    if (strengths.isEmpty) strengths.add('Solid foundation — ready for iterative academic polishing.');
    if (tips.isEmpty) tips.add('Your draft meets high academic standards. Review citations before final submission.');

    return WritingAnalysisReport(
      overallScore: double.parse(overallWritingScore.toStringAsFixed(1)),
      grammarScore: double.parse(grammarScore.toStringAsFixed(1)),
      clarityScore: double.parse(clarityScore.toStringAsFixed(1)),
      academicToneScore: double.parse(academicToneScore.toStringAsFixed(1)),
      vocabularyScore: double.parse(vocabularyScore.toStringAsFixed(1)),
      structureScore: double.parse(structureScore.toStringAsFixed(1)),
      citationQualityScore: double.parse(citationQualityScore.toStringAsFixed(1)),
      readabilityScore: double.parse(fleschScore.toStringAsFixed(1)),
      gradeLevel: double.parse(gradeLevel.toStringAsFixed(1)),
      avgSentenceLength: double.parse(avgSentenceLength.toStringAsFixed(1)),
      passiveVoicePercentage: double.parse(passiveVoicePercentage.toStringAsFixed(1)),
      academicWordPercentage: double.parse(academicWordPercentage.toStringAsFixed(1)),
      totalWordCount: totalWords,
      totalSentenceCount: totalSentences,
      issues: issues,
      strengthPoints: strengths,
      improvementTips: tips,
    );
  }

  int _countSyllables(String word) {
    String w = word.toLowerCase().trim();
    if (w.length <= 3) return 1;
    w = w.replaceAll(RegExp(r'(?:[^laeiouy]|ed|es|e)$'), '');
    w = w.replaceAll(RegExp(r'^y'), '');
    final matches = RegExp(r'[aeiouy]{1,2}').allMatches(w);
    return max(1, matches.length);
  }

  bool _isAcademicWord(String w) {
    const list = {
      'analysis', 'approach', 'assessment', 'concept', 'context', 'data', 'definition',
      'evidence', 'factor', 'framework', 'hypothesis', 'impact', 'indicate', 'methodology',
      'perspective', 'principle', 'procedure', 'process', 'research', 'significant', 'structure',
      'theoretical', 'variable', 'demonstrate', 'establish', 'evaluate', 'investigate', 'synthesize',
      'correlation', 'quantitative', 'qualitative', 'substantiate', 'paradigm', 'empirical'
    };
    return list.contains(w.toLowerCase());
  }
}
