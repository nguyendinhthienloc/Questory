# Questory pre-demo and submission checklist

This checklist proves that Questory is a complete Android app, not only an
editor mockup. Finish it using the exact APK that will be copied into the final
ZIP.

## 1. Freeze documentation and report

- [ ] `README.md` contains all four names and student IDs, build/run steps, no
      test credentials requirement, and the final video link.
- [ ] `docs/USER_FLOW.md` matches the production Android navigation.
- [ ] `docs/ONLINE_SHARING.md` clearly separates the offline app from optional
      Supabase sharing.
- [ ] `report/report.pdf` is between 10 and 30 pages and covers every required
      section.
- [ ] The report does not claim pending device checks are complete.

## 2. Verify the repository

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed `
  lib/app lib/core lib/data lib/features lib/main.dart test
flutter analyze
flutter test
```

Expected current baseline: analysis has no issues and all 62 tests pass.

## 3. Build the production Android app

`lib/main.dart` is the production entry point. Do not select Windows, Chrome,
or Edge; those targets do not initialize the production SQLite factory.

```powershell
flutter devices
flutter run -d <android-device-id>
```

For the release artifact, configure the ignored private signing file and run:

```powershell
flutter build apk --release
```

Copy only the verified result:

```text
build/app/outputs/flutter-apk/app-release.apk
    -> apk/app-release.apk
```

## 4. Complete-app smoke test

- [ ] Clean install launches to Explore without a storage error.
- [ ] Nha Trang and Ho Chi Minh City both open in airplane mode.
- [ ] Route Details shows metrics, landmarks, quests, safety, and route shape.
- [ ] Free Run discovery opens from both cities.
- [ ] Location explanation appears before the Android permission prompt.
- [ ] Denial and disabled GPS show recoverable errors.
- [ ] Start, pause, resume, and finish update time, distance, and pace.
- [ ] Foreground notification remains visible during a real 20-minute run.
- [ ] A nearby or fallback quest opens the real camera.
- [ ] Required caption validation prevents an empty save.
- [ ] Restart during a run offers resume/discard and excludes downtime.
- [ ] Finished run appears in Journey after process restart.
- [ ] Story Studio can edit, undo, save, reopen, and switch templates.
- [ ] Export opens the Android share sheet.
- [ ] Exported PNG is exactly 1080 by 1920 and has no selection controls.
- [ ] Deleting one run removes only its stories/photos, not another run.

## 5. Optional server test

The offline smoke test above needs no server. If online sharing will appear in
the demo, finish the hosted Supabase setup in `docs/ONLINE_SHARING.md`, rebuild
with both Dart defines, and verify an expiring link in a private browser.

## 6. Screenshot set

Capture clean portrait screenshots on Android with no debug banner or personal
data:

1. Explore showing both city packs.
2. Route Details with landmarks and safety notes.
3. Active Run Tracker with foreground notification visible in a second image.
4. Quest Camera caption step.
5. Run Summary with metrics and quest result.
6. Journey with a saved run, story, and achievement.
7. Story Studio before export.
8. Final 1080 by 1920 exported PNG.

Use these images in the report or presentation only after checking that no
private location, key, email notification, or unrelated device content appears.

## 7. Final ZIP

Required name:

```text
24125023_24125078_24125093_24125107.zip
```

Required contents:

```text
README.md
src/    (source and .git, excluding caches/build/IDE state)
apk/app-release.apk
report/report.pdf
video/demo-link.txt
```

- [ ] All four members speak in the 5-10 minute recording.
- [ ] Video access is `Anyone with the link can view` and works in incognito.
- [ ] The APK installs from the extracted final ZIP.
- [ ] One representative submits once and keeps the confirmation email.
