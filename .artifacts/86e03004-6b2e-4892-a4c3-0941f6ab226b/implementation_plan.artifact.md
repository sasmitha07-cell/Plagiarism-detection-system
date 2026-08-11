# Implementation Plan - Upgrade Build Tools and Migrate to Built-in Kotlin

The goal is to resolve the build failures by upgrading Gradle, Android Gradle Plugin (AGP), and Kotlin to the versions required by the latest Flutter environment, and to migrate the project to use "Built-in Kotlin".

## User Review Required

> [!IMPORTANT]
> **Version Upgrades**: I am upgrading the build tools to very recent versions as required by your environment:
> - Gradle: **8.14.0**
> - AGP: **8.11.1**
> - Kotlin: **2.2.20**
> These versions are necessary to satisfy the dependencies (like `androidx.browser`) and Flutter's own requirements.

> [!WARNING]
> **Plugin Compatibility**: The build log indicates that several plugins (`file_picker`, `google_mlkit_text_recognition`, etc.) are still using the legacy Kotlin Gradle Plugin (KGP) application method. While I am updating the app's configuration, you may still see warnings about these plugins until they are updated by their respective authors.

## Proposed Changes

### Build Configuration (Migration to Built-in Kotlin)

#### [MODIFY] [gradle.properties](file:///D:/Plagiarism%20detection%20mobile%20app/android/gradle.properties)
- Set `android.newDsl=true`
- Set `android.builtInKotlin=true`

#### [MODIFY] [gradle-wrapper.properties](file:///D:/Plagiarism%20detection%20mobile%20app/android/gradle/wrapper/gradle-wrapper.properties)
- Upgrade `distributionUrl` to Gradle **8.14.0**.

#### [MODIFY] [settings.gradle.kts](file:///D:/Plagiarism%20detection%20mobile%20app/android/settings.gradle.kts)
- Upgrade `com.android.application` to **8.11.1**.
- Upgrade `org.jetbrains.kotlin.android` to **2.2.20**.

#### [MODIFY] [build.gradle.kts](file:///D:/Plagiarism%20detection%20mobile%20app/android/app/build.gradle.kts)
- Remove `id("org.jetbrains.kotlin.android")` from the `plugins` block, as it is now handled by Flutter's built-in Kotlin support when the flags are enabled.
- Ensure the `kotlin` block remains if needed for `jvmTarget` configuration, or adjust as necessary for the new DSL.

## Verification Plan

### Automated Tests
- Run `flutter clean` and `flutter pub get`.
- Run `flutter analyze` to ensure no configuration errors.
- Run `flutter run` (or `flutter build apk --debug`) to verify the build completes successfully.

### Manual Verification
- Verify the app launches correctly on the connected device.
