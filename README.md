# Questory

[![CI](https://github.com/nguyendinhthienloc/Questory/actions/workflows/ci.yml/badge.svg)](https://github.com/nguyendinhthienloc/Questory/actions/workflows/ci.yml)

> Run the city. Capture the story.

Questory is an offline-first Android travel-running companion for casual users in Vietnam. Users follow a curated route or start a free run, record their path, complete location-based photo quests, and turn the route, statistics, places, and photos into an editable 1080 x 1920 Instagram Story infographic.

This is the final project for **TT2526HK3_CS426_24A - Android Mobile Development**.

## Status

The Android offline MVP is connected: Explore, two bundled city packs, route details, free-run discovery, foreground-capable GPS tracking, location-aware photo quests, retained photos, SQLite history, achievements, Run Summary, Story Studio, exact-size PNG export, and Android sharing. The inherited camera prototype remains only as unused baseline source; the production entry point is `lib/main.dart`.

The final automated review on 5 September 2026 used Flutter 3.44.8 and Dart
3.12.2. All 58 tests passed, `flutter analyze` reported no issues, and the
privately signed release APK passed signature and manifest verification. A
debug web build also compiled, but that does not make the production app
web-compatible: `lib/main.dart` opens the mobile SQLite database during
startup, so the complete app must currently be run on Android. Earlier Android
verification recorded a release APK installing and launching on an API 24+
emulator and retaining local data after an airplane-mode restart. A real
foreground GPS session and testing on an exact API 24 system image still
require hands-on verification.

## Team and modular ownership

| Student ID | Member | Independent module |
| --- | --- | --- |
| 24125023 | Nguyen Trong Van Viet | Destinations and quests |
| 24125078 | Nguyen Hong Tan Tai | Running and location tracking |
| 24125093 | Nguyen Dinh Thien Loc | Team leader; Story Studio and export |
| 24125107 | Tran Le Anh Tuan | Persistence, history, achievements, integration |

Every module develops against shared interfaces and fixture data, so unfinished storage, GPS, or UI work does not block another member. See [TODO.md](TODO.md) and [AGENTS.md](AGENTS.md).

## Product flow

1. Explore Nha Trang or Ho Chi Minh City.
2. Select a curated route or begin a free run.
3. Record GPS points, elapsed time, distance, and pace.
4. Complete photo quests at popular and lesser-known places.
5. Add a location and short caption to each photo.
6. Arrange the run in Story Studio.
7. Export a PNG and share it through Android.

Unlike the original camera-first social prototype, Questory has a new user problem, data model, navigation, architecture, and creative output.

## Offline MVP

- English-first interface.
- Bundled Nha Trang and Ho Chi Minh City packs.
- At least one curated route per city plus free-run mode.
- GPS route recording with duration, distance, and average pace.
- Foreground tracking notification while a run is active.
- Location-aware photo quests with captions.
- Persistent runs, track points, photos, progress, achievements, and stories.
- Run history and details.
- Personal achievements; no public leaderboard.
- Story templates with freeform drag, resize, rotate, crop, reorder, and delete.
- Solid-color palettes, typography, and original film/sticker decorations.
- Local 1080 x 1920 PNG export and Android sharing.
- Loading, empty, permission-denied, GPS-unavailable, and error states.

The recap may contain the route, distance, duration, average pace, estimated calories, landmarks, quest checklist, photos, captions, date, location, and cached weather. Core route and run data must work offline. Calories must be labeled as estimates; live weather may be omitted when unavailable.

## Optional online features

- Anonymous, expiring completed-route sharing via the optional Supabase Edge
  Function (see [Server guide](docs/SERVER_GUIDE.md))
- Live weather
- Editable Canva handoff
- Remotely updated destination packs

The demo must not depend on these. Canva OAuth, live sharing, and weather begin only after the offline flow is reliable.

## Initial destination packs

**Nha Trang:** an approximately 3.1 km out-and-back along the central Trần Phú waterfront, mixing Trầm Hương Tower and Trần Phú Beach with smaller promenade details.

**Ho Chi Minh City:** an approximately 1.6 km out-and-back linking Nguyễn Huệ Walking Street with Bạch Đằng Park, with an explicit warning to use the currently designated crossing or pedestrian bridge at Tôn Đức Thắng.

Destination data is bundled and versioned. GPS proximity can verify a quest, but poor accuracy must never trap the user; allow a documented fallback or skip.

The route text and approximate public-space access were desk-reviewed against
tourism and local-government sources. See the [Technical reference](docs/TECHNICAL_REFERENCE.md#destination-content-review).
This is not a field safety certification; current signs, closures, crossings,
traffic, weather, and events always take priority.

## Visual direction

Questory uses a colorful film-and-sticker travel-journal style:

- Solid off-white, ink, coral, cobalt, teal, and sun-yellow colors
- Film frames, paper pieces, stamps, route lines, and location labels
- No gradients and no generic AI-looking effects
- Templates as starting points, followed by freeform editing
- Original layouts and assets; online templates are inspiration only

## Screens

1. **Explore Vietnam** - destinations, route packs, progress, and free run.
2. **Route Details** - distance, expected duration, landmarks, and quests.
3. **Run Tracker** - time, distance, pace, path, quest progress, pause, and finish.
4. **Quest Camera** - evidence, location confirmation, and caption.
5. **Run Summary** - metrics, completed quests, and achievements.
6. **Story Studio** - templates, freeform composition, preview, and export.
7. **History** - saved runs and editable story projects.

## Offline-first rules

- Bundled routes, quests, and visual assets load without network access.
- Active runs are checkpointed so interruption does not silently lose them.
- Retained photos are copied from temporary camera paths to app storage.
- Network adapters never block local saving.
- Online route sharing is opt-in and disabled unless Supabase build defines are
  provided. A confirmation explains that route coordinates, run time,
  captions, and evidence photos will be uploaded; local filesystem paths are
  never sent.
- The offline demo uses bundled stylized city data and a recorded polyline, not live map tiles.
- Local data is the source of truth; synchronization is not an MVP requirement.

## Project structure

```text
lib/
  app/                 # navigation, theme, dependency assembly
  core/
    domain/            # shared immutable models
    contracts/         # repository and device interfaces
    fixtures/          # deterministic parallel-development data
    platform/          # permission and platform abstractions
  features/
    destinations/
    tracking/
    quest_camera/
    story_studio/
    history/
  data/                # local implementations and optional online adapters
assets/
  destinations/
  story/
```

Technology direction: Flutter/Dart, Android API 24+, SQLite-based local persistence, private media storage, camera capture, location tracking, local canvas rendering, and Android sharing. Packages must be checked for maintenance, licensing, API 24 support, and offline behavior.

## Build and run

The production app targets Android API 24 or newer. It does not require a
backend: destination packs, runs, photos, achievements, and stories are local.
Supabase is used only when the optional online-sharing build defines are
provided.

Prerequisites are Flutter, the Android SDK, and a running API 24+ Android
device or emulator.

The [App guide](docs/APP_GUIDE.md) contains the production user flow, platform
boundaries, Story Studio harness, and feature checks. The
[Server guide](docs/SERVER_GUIDE.md) covers the optional local and hosted
sharing service. Use the [Release guide](docs/RELEASE_GUIDE.md) for CI, signing,
device verification, screenshots, and submission packaging.

```shell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <android-device-id>
flutter build apk --release
```

On a machine with no connected Android target, `flutter devices` may list only
Windows and browsers. Do not choose those targets for `lib/main.dart`: its
SQLite startup path is mobile-only. Start an emulator or connect a phone with
USB debugging, confirm it appears in `flutter devices`, and then pass that
Android device ID explicitly.

The platform-independent Story Studio sample can still be run in Edge:

```shell
flutter run -d edge -t lib/features/story_studio/story_studio_demo.dart
```

If the screen says `databaseFactory not initialized`, the app was launched on
an unsupported desktop or browser target. Retrying cannot fix that target
mismatch. No server needs to be started; select an Android device instead.

To include the optional online route-sharing feature, follow the
[Server guide](docs/SERVER_GUIDE.md). The recommended filming setup uses
a hosted Supabase project over HTTPS. Local Supabase is also documented for
development, but it is not required for the graded offline journey.

Release builds require a private upload keystore. Copy
`android/key.properties.example` to the ignored `android/key.properties`, set
the absolute keystore path and private credentials, and keep both files outside
Git. Gradle intentionally refuses to create a release build when signing is not
configured instead of silently signing a release artifact with the debug key.
The current machine is already configured; see the
[Release guide](docs/RELEASE_GUIDE.md#android-release-signing) before moving or rebuilding the
release on another computer.

If Gradle reports `Unable to establish loopback connection` on Windows, use a
short writable temporary directory for that terminal, then rebuild:

```powershell
New-Item -ItemType Directory -Path .gradle-tmp -Force | Out-Null
$env:TEMP = (Resolve-Path .gradle-tmp).Path
$env:TMP = $env:TEMP
flutter build apk --release
```

If Flutter is installed outside `PATH`, add your Flutter SDK's `bin` directory
to `PATH`, then use the same commands. For PowerShell:

```powershell
$env:Path += ";C:\path\to\flutter\bin"
flutter run
```

APKs are generated at `build/app/outputs/flutter-apk/app-debug.apk` and `build/app/outputs/flutter-apk/app-release.apk`. A release build must use the team's private upload keystore; never distribute a debug-signed artifact as the release package. Questory uses `sqflite` for a versioned local database, `path_provider` for app-controlled evidence photos, `geolocator` for foreground location updates, and `camera` for quest evidence. Database schema version 1 stores active checkpoints, completed summaries, editable story documents, and achievements. Future schema changes must increment the database version and add an `onUpgrade` migration rather than replacing user data.

The first Android run may download the required SDK platform or CMake. The Java restricted-method and Kotlin Gradle Plugin messages currently shown by Gradle are migration warnings; they did not prevent the verified build.

See the [Technical reference](docs/TECHNICAL_REFERENCE.md) for dependency,
license, offline, bundled-asset, and destination-source notes.

GitHub Actions runs on every push and pull request to `main`, and can also be started manually from the Actions page. It uses the committed `pubspec.lock`, rejects formatting changes in `lib/features/` and `test/`, fails on analyzer errors or warnings, runs the test suite with coverage, builds a debug APK, and retains that APK as a workflow artifact for 14 days.

The inherited camera screens still contain informational lint notices. CI displays those notices but does not fail on them; new feature code should remain clean.

## Requirements coverage

| Requirement | Coverage |
| --- | --- |
| Android API 24+ APK | Flutter Android release with explicit minimum SDK |
| 3-4 connected screens | Seven connected screens |
| Persistent local data | Runs, points, quests, photos, stories, achievements |
| Device integration | Camera, location, foreground tracking, Android sharing |
| UI/UX quality | Offline, loading, empty, error, and permission states |
| Collaboration | Four owned modules, fixtures, tests, and Git evidence |

## Submission placeholders

- Demo video: `DEMO_VIDEO_LINK_PLACEHOLDER`
- Test credentials: not required for the offline MVP
- APK: `apk/app-release.apk`
- Report: `report/report.pdf`
- Demo link: `video/demo-link.txt`

After uploading the recording, put its public-view URL on the first line of
`video/demo-link.txt`, then run `tools/package_submission.ps1`. The script
validates the required files, inserts the same URL into the packaged README,
excludes caches and secrets, and creates the correctly named ZIP.

## Provenance

This repository began from the MIT-licensed “Locket Clone” camera prototype by Nasr Al-Rahbi. Its copyright and license remain in [LICENSE](LICENSE). Questory's domain, routes, quests, architecture, persistence, editor, assets, tests, and documentation will be the team's own work.
