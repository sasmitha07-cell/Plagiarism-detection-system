# Audit Report: Phase 8 - Live Web Evidence Discovery

This report summarizes the implementation audit of the web discovery layer and candidate selection logic.

## 1. Audit Summary

| Component | Status | Findings |
| :--- | :--- | :--- |
| **Search Abstraction** | ✅ PASS | `DetectionEngine` is decoupled via the `SearchProvider` interface. |
| **Edge Function Security**| ✅ PASS | Secrets are server-side only. Grep search confirmed zero keys in Flutter. |
| **Candidate Ranking** | ✅ PASS | Chunks are correctly ranked by similarity and length before searching. |
| **Search Limits** | ✅ PASS | `maxWebSearchChunks` correctly restricts searches to the Top 5. |
| **Evidence Merging** | ✅ PASS | `MatchEvidence` signals are merged (EXACT + SEMANTIC + WEB) for single passages. |
| **Deduplication** | ✅ PASS | URL-based deduplication is active in the Edge Function. |
| **Failure Fallback** | ✅ PASS | Engine gracefully falls back to local evidence if web search fails or is offline. |
| **Model Verification** | ✅ PASS | `gemini-3.5-flash` and `gemini-embedding-2` are correctly configured. |

## 2. Detailed Verification

### Search Result Integrity
Every `SearchResult` now captures:
- **Title & URL**: Preserved for UI display and navigation.
- **Domain**: Extracted from URL.
- **Snippet**: Stored as discovery evidence.
- **Rank & Query**: Preserved for traceability.

### Security Scan (grep result)
- `SEARCH_API_KEY`: 0 matches in lib/
- `SEARCH_ENGINE_ID`: 0 matches in lib/
- `GEMINI_API_KEY`: 0 matches in lib/
- `AIzaSy`: 0 matches in lib/

### Discovery vs. Proof logic
The `MatchEvidence` model now uses the `DiscoveryStatus` enum:
- `internal`: For local/semantic hits.
- `discovered`: Set when a web result is found but not yet fully content-verified.
- `verified`: Reserved for future content-retrieval validation.

## 3. Regression Testing Results

- **PDF/TXT Upload**: Remains functional; uses the same `analyzeDocument` pipeline.
- **A/B Comparison**: ✅ Verified. Since `compareWithDocumentId` is passed, the engine prioritizes the target document search over the open web.
- **Authentication**: Remains strictly required for Edge Function invocation.
- **Offline Matcher**: Verified that `ExactMatcher.findMatches` executes before any network calls, ensuring verbatim local matches are found even without internet.

## 4. Corrected Implementation Order (Phase 11)

With Phase 8 verified, the next phase is **Evidence Aggregation**. This will involve:
1.  **Context Extraction**: Retrieving snippets and surrounding text for verified sources.
2.  **Weighted Scoring**: Calculating a final Plagiarism Risk Level based on the strength of all signals (Exact vs Semantic vs Web).
3.  **Gemini Evidence Review**: Feeding the *entire* evidence array to Gemini for a human-readable explanation.

> [!TIP]
> **Highlighting Status**: Highlighting is now 100% data-ready. Every `MatchEvidence` object contains `startOffset` and `endOffset` mapping back to the original text.

**Audit Complete. Ready to proceed to Phase 11.**
