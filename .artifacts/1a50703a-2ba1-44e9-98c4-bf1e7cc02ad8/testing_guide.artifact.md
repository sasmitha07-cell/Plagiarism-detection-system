# Testing Guide: Hybrid Evidence-Based Detection Engine

This guide provides step-by-step instructions to verify the full detection pipeline, from document upload to AI-powered rewriting.

## 1. Environment Setup (Critical)

The engine requires server-side secrets to be configured in your Supabase project.

### Required Supabase Secrets
Go to your **Supabase Dashboard > Project Settings > Edge Functions > Secrets** and add:

| Secret Key | Description |
| :--- | :--- |
| `GEMINI_API_KEY` | Your Google Gemini API Key (Must support Gemini 3.5 Flash). |
| `SEARCH_API_KEY` | Your Google Cloud JSON Search API Key. |
| `SEARCH_ENGINE_ID` | Your Programmable Search Engine ID (CX). |

> [!WARNING]
> **Zero-Key Security**: Ensure these keys are **NOT** in your `.env` file or Flutter code. The app will securely invoke them via Edge Functions.

---

## 2. End-to-End Testing Workflow

### Step 1: Prepare Test Document
Create a `.txt` or `.docx` file containing three specific sections to test the different "signals":
1.  **Exact Match**: Copy a paragraph verbatim from a recent news article or Wikipedia.
2.  **Semantic Match**: Lightly rephrase a paragraph from a known book or website.
3.  **Original Text**: Write 2-3 original sentences about your day.

### Step 2: Perform the Scan
1.  Launch the app and navigate to the **Scan** tab.
2.  Upload your prepared document.
3.  Monitor the "Step" indicator (e.g., "Analyzing content...", "Generating comprehensive report...").

### Step 3: Verify the Result Screen
- **Scores**: Check that the **Plagiarism** and **AI Content** gauges reflect the document's composition.
- **Breakdown**: Verify the Pie Chart shows a mix of "Exact", "Semantic", and "Web" signals.
- **Summary**: Read the **Executive Summary**. It should be a human-readable assessment written by Gemini 3.5 Flash based on the evidence.

### Step 4: Verify the Writing Coach
1.  Tap **"Open Writing Coach"**.
2.  Check the **Signal Labels**: Verbatim matches should be labeled "Exact Match", while rephrased web content should show "Web Match".
3.  **Source URLs**: Ensure you can see the URL of the discovered source and that tapping it opens the website.

### Step 5: Test the Rewrite Assistant
1.  On any flagged issue, tap **"Open Rewrite Assistant"**.
2.  Select a tone (e.g., **"Academic"**).
3.  Verify that the "AI Suggestion" preserves your meaning but significantly changes the phrasing to reduce similarity.
4.  Tap **"Apply Fix"** and verify you are returned to the coach.

---

## 3. Technical Verification (Backend)

If you encounter issues, verify the raw data flow in the **Supabase Dashboard**:

1.  **Edge Function Logs**: Check `web-search` and `gemini-reasoning` logs to ensure they are returning valid JSON.
2.  **Database Tables**:
    - Check the `flagged_sections` table. It should contain rows with `start_position`, `end_position`, and a JSON array of `signals`.
    - Check the `similarity_sources` table to see if the web URLs were correctly persisted.

---

## 4. Test Case Matrix

| Scenario | Expected Result |
| :--- | :--- |
| **Offline Scan** | App detects "Local" matches (if comparing two docs) but skips Web Search without crashing. |
| **Common Phrases** | "The study found that" should NOT be flagged (The Smart Ranker should filter out short/common phrases). |
| **Quota Reached** | If the Search API hits its daily limit, the scan should complete using only Local/Semantic data. |
| **Self-Plagiarism** | If you upload the same document twice, the second scan should flag the first as a "Internal" match. |
