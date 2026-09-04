# Questory release guide

Use this guide for CI-equivalent checks, Android signing, device verification,
screenshots, and submission packaging.

## Repository verification

From the repository root:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib/features test
flutter analyze --no-fatal-infos
flutter test --coverage
flutter build apk --debug --no-pub
```

Expected baseline: formatting is unchanged, analysis has no issues, all 58 tests
pass, and the debug APK builds. GitHub Actions uses the same sequence.

## Android release signing

The repository does not contain signing passwords or a private key. Gradle
stops release builds when the ignored `android/key.properties` is missing or
incomplete.

This computer currently uses:

- keystore: `%USERPROFILE%\.questory\release\questory-upload.jks`
- properties: `android/key.properties`
- alias: `questory-upload`

Keep the keystore and properties private and outside the submission ZIP. Back
them up together; the same key is required for future updates.

```powershell
flutter build apk --release
```

Verify `build/app/outputs/flutter-apk/app-release.apk`, then copy it to
`apk/app-release.apk`. `apksigner` must report `Verifies`; `aapt dump badging`
must report package `com.nguyendinhthienloc.questory`, label `Questory`, minimum
SDK 24, and version name `1.0.0`.

The signed submission copy verified on 5 September 2026 uses APK Signature
Scheme v2 and has SHA-256:

```text
9BA83EE47A9CE4F0D7E0714F9E57ECE0D3F5A9C1075D539E6202A88EFD574D6F
```

A rebuild may change the hash, so repeat signature and manifest checks after
every rebuild.

If Gradle reports `Unable to establish loopback connection` on Windows:

```powershell
New-Item -ItemType Directory -Path .gradle-tmp -Force | Out-Null
$env:TEMP = (Resolve-Path .gradle-tmp).Path
$env:TMP = $env:TEMP
flutter build apk --release
```

## Complete-app device check

- [ ] Clean install opens Explore without a storage error.
- [ ] Both cities and Route Details work in airplane mode.
- [ ] Free Run opens from both cities.
- [ ] Location explanation appears before the Android prompt.
- [ ] Denied permission and disabled GPS show recovery guidance.
- [ ] Start, pause, resume, finish, and discard behave correctly.
- [ ] A real run keeps the foreground notification visible.
- [ ] A nearby or fallback quest opens the camera and validates captions.
- [ ] Interrupted runs offer resume or discard without counting downtime.
- [ ] Finished runs survive restart and appear in Journey.
- [ ] Story Studio edits, saves, reopens, switches templates, and undoes changes.
- [ ] Export opens Android sharing and produces a clean 1080 x 1920 PNG.
- [ ] Deleting one run does not remove unrelated work.

## Documentation and screenshot check

- [ ] `README.md` contains all members, IDs, and current run instructions.
- [ ] `docs/APP_GUIDE.md` matches production navigation.
- [ ] `docs/SERVER_GUIDE.md` keeps online sharing explicitly optional.
- [ ] `report/report.pdf` contains 10-30 pages and no unverified claims.
- [ ] Screenshots contain no private route, key, notification, or account data.

Recommended screenshot set: Explore, Route Details, active Run Tracker,
foreground notification, Quest Camera caption, Run Summary, Journey, Story
Studio, and the exported story PNG.

## Final submission package

Required archive name:

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

- [ ] Put the public-view video URL on the first line of `video/demo-link.txt`.
- [ ] Confirm all four members speak during the 5-10 minute recording.
- [ ] Confirm the link opens in a private browser window.
- [ ] Run `tools/package_submission.ps1`.
- [ ] Extract the ZIP and install the included APK.
- [ ] One representative submits once and retains the confirmation email.
