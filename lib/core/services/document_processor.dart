import 'document_extraction_service.dart';

class DocumentChunk {
  final String text;
  final int startOffset;
  final int endOffset;
  final int pageNumber;
  final int paragraphNumber;
  final int sentenceNumber;
  List<double>? embedding;

  DocumentChunk({
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.pageNumber,
    required this.paragraphNumber,
    required this.sentenceNumber,
    this.embedding,
  });
}

class DocumentProcessor {
  DocumentProcessor._();
  static final instance = DocumentProcessor._();

  /// Splits a document into granular chunks (sentences) while preserving
  /// exact character offsets relative to the original untouched text.
  List<DocumentChunk> chunkDocument(String text) {
    final List<DocumentChunk> chunks = [];
    
    // 1. Identify paragraph boundaries using regex to find their offsets
    final paragraphRegex = RegExp(r'(?:[^\n]+(?:\n[^\n]+)*)', multiLine: true);
    final paragraphMatches = paragraphRegex.allMatches(text);
    
    int pIdx = 1;
    for (final pMatch in paragraphMatches) {
      final paragraphText = pMatch.group(0)!;
      final pStart = pMatch.start;

      // 2. Identify sentence boundaries within each paragraph
      // We use a regex that matches the sentence content AND its trailing punctuation/space.
      final sentenceRegex = RegExp(r'[^.!?]+[.!?]*\s*');
      final sentenceMatches = sentenceRegex.allMatches(paragraphText);
      
      int sIdx = 1;
      for (final sMatch in sentenceMatches) {
        final rawSentence = sMatch.group(0)!;
        final sentence = rawSentence.trim();
        
        if (sentence.isEmpty) continue;

        final trimStartOffset = rawSentence.indexOf(sentence);
        final startOffset = pStart + sMatch.start + trimStartOffset;
        final endOffset = startOffset + sentence.length;

        chunks.add(DocumentChunk(
          text: sentence,
          startOffset: startOffset,
          endOffset: endOffset,
          pageNumber: 1, 
          paragraphNumber: pIdx,
          sentenceNumber: sIdx++,
        ));
      }
      pIdx++;
    }
    
    return chunks;
  }
}
