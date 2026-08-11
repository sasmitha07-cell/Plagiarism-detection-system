# Task List - Build Tool Upgrade & Auth Fixes

- [x] **Phase 1: Build Configuration (Built-in Kotlin)**
    - [x] Enable `newDsl` and `builtInKotlin` in `gradle.properties` (Standardized)
    - [x] Upgrade Gradle to 8.12.0 in `gradle-wrapper.properties`
    - [x] Upgrade AGP to 8.9.2 and Kotlin to 2.1.0 in `settings.gradle.kts`
    - [x] Migrate `app/build.gradle.kts` to Built-in Kotlin (Standard Plugin Application)
- [x] **Phase 2: Authentication Button Logic**
    - [x] Inspect `login_screen.dart` sign-in logic
    - [x] Inspect `register_screen.dart` sign-up logic
    - [x] Inspect `forgot_password_screen.dart` logic
    - [x] Verify `GradientButton` and `AppTextField` integration (Improved responsiveness with `onTap`)
- [x] **Phase 3: Verification**
    - [x] Run `flutter clean`
    - [x] Run `flutter pub get`
    - [x] Run `flutter analyze`
    - [x] Run `flutter build apk --debug` (Verified version alignment)
