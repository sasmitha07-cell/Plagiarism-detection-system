# Implementation Plan - Final Polish & Verification

This plan finalizes all remaining tasks in the `task.artifact.md`, specifically focusing on speed benchmarks, parallel status updates, and diagnostic robustness.

## User Review Required

> [!NOTE]
> **Parallel Status Tracking**: I will implement a "Parallel Status Tracker" in the scan service. Instead of the progress bar hanging on "Analyzing...", you will see it update in real-time as each AI component (AI detection, Writing Quality, Plagiarism) finishes its task.

## 1. Speed & Diagnostics (The "Speed Checking" Goal)

### Stage 1: Parallel Progress Tracking
- **Flutter**: Update `ScanService` to call `onStepChanged` independently as each AI future completes.
- **Flutter**: Add a `Stopwatch` to accurately log the end-to-end performance of the detection engine.

### Stage 2: Robust Timeouts
- **Flutter**: Standardize all Gemini AI calls to a **25-second timeout**. This prevents the "Infinite Loading" hang if the server is under heavy load.

## 2. Accuracy & Reliability (The "Perfect Analysis" Goal)

### Stage 3: Batch Safety Limits
- **DetectionEngine**: Add a check to ensure we never exceed Gemini's **100-content batch limit** for embeddings (though we currently chunk at a much lower rate, this is critical for production stability).

### Stage 4: Auditor v3 Prompt Finalization
- **Edge Function**: Perform a final sweep of the `gemini-reasoning` prompt to ensure the "No Hallucination" rule is the highest priority.

## 3. Proposed Changes

### [MODIFY] [scan_provider.dart](file:///D:/Plagiarism_detection_mobile_app/lib/features/scan/providers/scan_provider.dart)
- Implement `Future.wait` with individual `.then()` status updates.
- Add performance logging.

### [MODIFY] [detection_engine.dart](file:///D:/Plagiarism_detection_mobile_app/lib/core/services/detection_engine.dart)
- Add batch size safeguards.
- Enhance overlap calculation for more clinical "Verified" status.

### [MODIFY] [rewrite_screen.dart](file:///D:/Plagiarism_detection_mobile_app/lib/features/coach/screens/rewrite_screen.dart)
- Add a post-fix navigation hint: "Re-scan to update your score."

## 4. Final Verification Checklist
- [ ] Scan speed < 12 seconds for standard document.
- [ ] Zero-wait transition from 100% progress to Results.
- [ ] "Apply Fix" updates Supabase successfully.
- [ ] Paraphrased web content is correctly identified (Recalibrated keyword search).
