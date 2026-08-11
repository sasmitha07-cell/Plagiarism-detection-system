# Implementation Plan - 2026 AI Model & Logo Update

I have updated the app to use the stable 2026 AI model and will now ensure the app uses the latest logo you provided.

## User Review Required

> [!IMPORTANT]
> **Action Required**: I cannot see a file named `app-logo.png` in your project yet.
> 1. Please save the image you just uploaded as `assets/images/app-logo.png`.
> 2. Once you do that, I will update the app configuration to use that exact filename.
>
> **API Key Reminder**: Please ensure your key in `.env` starts with `AIzaSy`. Your current `AQ.` key will cause "Not Found" errors.

## Proposed Changes

### [AI Constants](file:///D:/Plagiarism_detection_mobile_app/lib/core/constants/app_constants.dart)

#### [MODIFY] [app_constants.dart](file:///D:/Plagiarism_detection_mobile_app/lib/core/constants/app_constants.dart) [DONE]
- Changed `geminiModel` to `gemini-2.5-flash` to fix retirement errors.

### [App Configuration](file:///D:/Plagiarism_detection_mobile_app/pubspec.yaml)

#### [MODIFY] [pubspec.yaml](file:///D:/Plagiarism_detection_mobile_app/pubspec.yaml)
- Update `flutter_launcher_icons` to use `assets/images/app-logo.png`.

### [Splash Screen](file:///D:/Plagiarism_detection_mobile_app/lib/features/auth/screens/splash_screen.dart)

#### [MODIFY] [splash_screen.dart](file:///D:/Plagiarism_detection_mobile_app/lib/features/auth/screens/splash_screen.dart)
- Update the image path from `app_logo.png` to `app-logo.png`.

## Verification Plan

### Manual Verification
1. Verify the file `assets/images/app-logo.png` exists.
2. Run `dart run flutter_launcher_icons` to update the app icon.
3. Run the app and verify the splash screen shows the new logo and is correctly aligned.
4. Run a scan and verify it uses `gemini-2.5-flash`.
