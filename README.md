# Questory

[![CI](https://github.com/nguyendinhthienloc/Questory/actions/workflows/ci.yml/badge.svg)](https://github.com/nguyendinhthienloc/Questory/actions/workflows/ci.yml)

> Run the city. Capture the story.

Questory is an offline-first Android travel-running companion for casual users in Vietnam. Users follow a curated route or start a free run, record their path, complete location-based photo quests, and turn the route, statistics, places, and photos into an editable 1080 x 1920 Instagram Story infographic.

This is the final project for **TT2526HK3_CS426_24A - Android Mobile Development**.

## Status

The repository contains the inherited camera prototype plus the first Questory Story Studio foundation. Local development and CI use Flutter 3.44.8; the automated checks verify formatting, analysis, tests, and an Android debug APK.

## Team and modular ownership

| Student ID | Member | Independent module |
| --- | --- | --- |
| 24125023 | Nguyen Trong Van Viet | Destinations and quests |
| 24125078 | Nguyen Hong Tan Tai | Running and location tracking |
| 24125093 | Nguyen Dinh Thien Loc | Story Studio and export |
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

- Anonymous, expiring live-location sharing
- Live weather
- Editable Canva handoff
- Remotely updated destination packs

The demo must not depend on these. Canva OAuth, live sharing, and weather begin only after the offline flow is reliable.

## Initial destination packs

**Nha Trang:** a coastal route mixing recognizable destinations with local details. Candidate places include Tram Huong Tower, Tran Phu Beach, and Hon Chong, subject to pedestrian-safety validation.

**Ho Chi Minh City:** an urban route through public architecture, parks, street details, and cultural landmarks. Exact paths must be checked for safe public access.

Destination data is bundled and versioned. GPS proximity can verify a quest, but poor accuracy must never trap the user; allow a documented fallback or skip.

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
- The offline demo uses bundled stylized city data and a recorded polyline, not live map tiles.
- Local data is the source of truth; synchronization is not an MVP requirement.

## Planned structure

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

Technology direction: Flutter/Dart, Android API 24+, SQLite-based local persistence, private media storage, camera/photo picker, location tracking, local canvas rendering, and Android sharing. Packages must be checked for maintenance, licensing, API 24 support, and offline behavior.

## Build and run

Prerequisites are Flutter, Android SDK, and an API 24+ device or emulator.

```shell
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

GitHub Actions runs on every push and pull request to `main`, and can also be started manually from the Actions page. It uses the committed `pubspec.lock`, rejects formatting changes in `lib/features/` and `test/`, fails on analyzer errors or warnings, runs the test suite with coverage, builds a debug APK, and retains that APK as a workflow artifact for 14 days.

The inherited camera screens still contain informational lint notices. CI displays those notices but does not fail on them; new feature code should remain clean.

## Agent context

`AGENTS.md` is the durable source of engineering context. Code-Graph-RAG is optional supporting infrastructure for agents that can use MCP. It must be installed outside the app source; generated graph data and provider secrets are not committed.

## Requirements coverage

| Requirement | Coverage |
| --- | --- |
| Android API 24+ APK | Flutter Android release with explicit minimum SDK |
| 3-4 connected screens | Seven planned screens |
| Persistent local data | Runs, points, quests, photos, stories, achievements |
| Device integration | Camera, location, foreground tracking, Android sharing |
| UI/UX quality | Offline, loading, empty, error, and permission states |
| Collaboration | Four owned modules, fixtures, tests, and Git evidence |

## Submission placeholders

- Demo video: `TBD`
- Test credentials: not required for the offline MVP
- APK: `apk/app-release.apk`
- Report: `report/report.pdf`
- Demo link: `video/demo-link.txt`

## Provenance

This repository began from the MIT-licensed “Locket Clone” camera prototype by Nasr Al-Rahbi. Its copyright and license remain in [LICENSE](LICENSE). Questory's domain, routes, quests, architecture, persistence, editor, assets, tests, and documentation will be the team's own work.
