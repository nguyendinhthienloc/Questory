# Questory - Final Project Submission

Course: TT2526HK3_CS426_24A - Android Mobile Development

## Team

| Student ID | Full name |
| --- | --- |
| 24125023 | Nguyen Trong Van Viet |
| 24125078 | Nguyen Hong Tan Tai |
| 24125093 | Nguyen Dinh Thien Loc (Team Leader) |
| 24125107 | Tran Le Anh Tuan |

## Demo video

DEMO_VIDEO_LINK_PLACEHOLDER

Replace the placeholder with a Google Drive or YouTube link viewable by anyone with the link. The video must be 5-10 minutes, with all four members speaking. The package is not ready to submit until this is filled in.

## Files

- `apk/app-release.apk`: current signed Android release.
- `report/report.pdf`: project report with screenshots and team contributions.
- `src/`: full application source; `src/git-log.txt` preserves commit history.
- `video/demo-link.txt`: demo URL, pending completion.

Build outputs, IDE caches, local SDK paths, and private signing credentials are excluded. `src/android/gradle/wrapper` contains required build inputs, not a generated Gradle cache.

## Install and use

Install `apk/app-release.apk` on Android API 24 or newer. Allow installation from the app used to open the APK, then open Questory. With Android platform tools, installation is also available through:

```shell
adb install -r apk/app-release.apk
```

Choose a city, choose a curated route or Free Run, and begin tracking. Grant location when requested; grant camera access when taking quest photos. Completed runs appear in Journey and can be opened in Story Studio for PNG export and Android sharing.

No account or test credentials are required for the offline MVP. Tracks friend accounts are local demo data. The core app needs no backend. Optional online route sharing is disabled in this build.

## Build and run from source

Use Flutter 3.44.8 / Dart 3.12.2, Java 17, an Android SDK, and an API 24+ device or emulator. From the package directory:

```shell
cd src
flutter pub get
flutter devices
flutter run -d <android-device-id>
```

The production entry point supports Android; do not select Windows or a browser.

```shell
flutter analyze
flutter test
flutter build apk --debug
```

Debug output: `src/build/app/outputs/flutter-apk/app-debug.apk`.

To create your own signed release, copy `src/android/key.properties.example` to `src/android/key.properties` and provide your own keystore path, alias, and passwords. Then run `flutter build apk --release` from `src`. The submitted APK is already signed; private signing keys are intentionally omitted.

See [the app guide](src/docs/APP_GUIDE.md), [release guide](src/docs/RELEASE_GUIDE.md), and [optional server guide](src/docs/SERVER_GUIDE.md) for details.
