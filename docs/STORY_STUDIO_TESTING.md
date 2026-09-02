# Story Studio testing guide

This guide tests Nguyen Dinh Thien Loc's Story Studio and export module through
the connected Questory demo journey. The demo uses the bundled Nha Trang run
fixture and one app-scoped in-memory story repository, so unfinished tracking
or durable persistence cannot block the presentation.

## Prerequisites

- Flutter 3.44.8 and Dart 3.12.2, or a compatible Flutter 3 release.
- Project dependencies installed with `flutter pub get`.
- For the Android share-sheet check, an API 24+ emulator or physical Android
  device.

Run all commands from the repository root.

## Fast automated verification

```shell
dart format --output=none --set-exit-if-changed lib/core lib/features/story_studio test/features/story_studio
flutter analyze lib/core lib/features/story_studio test/features/story_studio
flutter test
```

Expected result:

- Formatting exits successfully.
- Focused analysis reports `No issues found`.
- All tests pass. The suite includes document serialization, editing commands,
  snapping, undo/redo, conditional run data, screen behavior, error feedback,
  a 360 x 640 layout, and a decoded PNG that is exactly 1080 x 1920.

To run only this module's tests:

```shell
flutter test test/features/story_studio
```

## Launch the connected demo

List available targets, then run the normal Questory entry point:

```shell
flutter devices
flutter run -d <device-id>
```

For Edge:

```shell
flutter run -d edge
```

Follow `Explore → View run recap → Create story`. You can also enter through the
Studio or Runs bottom-navigation destinations. Edge downloads the exported PNG;
Android opens the native share sheet.

The focused development entry point remains available when only the editor is
needed:

```shell
flutter run -d <device-id> -t lib/features/story_studio/story_studio_demo.dart
```

## Manual editor checklist

1. Confirm the screen opens with the `City Sprint`, `Film Roll`, and
   `Postcard Trail` templates.
2. Switch between all three templates and confirm each canvas remains visible.
3. Select text, photo, route, statistic, quest, sticker, and location elements.
4. Drag an element. Pinch to resize and rotate it. Confirm alignment guides
   appear when moving near the canvas center or another element.
5. Use rotate, bring forward, send backward, duplicate, and delete. Confirm the
   selected layer changes as expected.
6. Use undo and redo after movement, duplication, deletion, text edits, and
   style changes.
7. Select a text element and change its content, color, and font. Confirm only
   solid colors are offered.
8. Select a photo and adjust zoom and horizontal/vertical focal position.
9. Save the editable project, make another change, then reopen it. Confirm the
   saved text, transforms, crop, and layer order return.
10. Confirm the fixture fills route, distance, duration, pace, landmarks,
    quests, photo captions, date, estimated calories, and cached weather.

## Android export and sharing

Perform this check on an API 24+ Android device or emulator:

1. Enable airplane mode after the app is installed.
2. Launch the standalone demo and make a visible edit.
3. Tap the export action.
4. Confirm Android's share chooser opens.
5. Share or save the PNG, then inspect it with an image viewer.
6. Confirm its dimensions are exactly 1080 x 1920.
7. Confirm selection borders, alignment guides, and editor controls do not
   appear in the exported image.
8. Confirm the visible story edit is present in the PNG.

The native handler accepts only existing files inside the app cache and exposes
them through a read-only `FileProvider` grant to the selected receiving app.

## Edge export

1. Run the connected demo with `flutter run -d edge`.
2. Open the completed run and enter Story Studio.
3. Make a visible edit and select `EXPORT`.
4. Confirm Edge downloads a PNG and the editor reports
   `Export ready: 1080 x 1920 PNG downloaded.`
5. Open the downloaded image and confirm its size is 1080 x 1920 with no editor
   controls.

Edge DevTools changes viewport size and touch emulation but does not create a
camera device. Questory's demo fixture already contains deterministic photo
evidence, so the Story Studio presentation never depends on browser camera
availability.

## Offline and failure checks

- Keep airplane mode enabled while changing templates, editing, saving,
  reopening, and exporting. None of those actions should require network data.
- Cancel the Android share chooser; the editor should remain usable.
- The automated screen test injects a failed renderer and verifies that the UI
  reports `Export failed` instead of crashing.
- Cached weather is shown only when the supplied run contains it. Calories are
  omitted unless configured and are always labeled as estimated.

## Current integration boundary

The main app now uses fixture data and an app-scoped in-memory repository for a
complete presentation flow. Connecting a newly recorded real run, real camera
evidence, durable story storage across process restarts, and final team-owned
navigation remains tracked separately in `TODO.md`.

If Gradle reports `Unable to establish loopback connection`, Android compilation
is being blocked by the host environment before Kotlin compilation begins. Try a
normal external terminal, restart the machine's networking/Java environment, or
use CI or another development host. Automated Flutter tests can still validate
the platform-independent Story Studio behavior.
