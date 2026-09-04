# Questory completion checklist

Last updated: 5 September 2026

This file is the live handoff record for the final pre-video pass. A box is
checked only after the related output has been inspected or verified. The target
is to leave only video recording, upload, and insertion of the final video link.

## 1. Requirements and repository audit

- [x] Read `AGENTS.md`, `README.md`, `TODO.md`, and `final_project_requirements.txt`.
- [x] Distinguish submission requirements from repository instructions.
- [x] Review the production bootstrap, navigation, persistence, tracking,
      camera, History, Story Studio, optional sharing, Android configuration,
      tests, and team Git history.
- [x] Identify the reported startup failure as an unsupported desktop/browser
      target for the production SQLite bootstrap, not a missing backend.
- [x] Confirm that the offline-first Android application requires no server.
- [x] Record code risks that need correction before the release build.

## 2. Documentation first

- [x] Remove obsolete optional agent-tooling setup and planning material.
- [x] Rewrite `README.md` with explicit Android production commands and explain
      why running `lib/main.dart` on Windows or Edge shows the storage error.
- [x] Consolidate the production flow into `docs/APP_GUIDE.md`.
- [x] Consolidate optional sharing into `docs/SERVER_GUIDE.md` to separate
      offline mode, hosted Supabase, and local Supabase testing.
- [x] Consolidate Story Studio testing into `docs/APP_GUIDE.md` so the browser
      target is clearly a focused editor harness, not the complete application.
- [x] Consolidate the final checklist and signing instructions into `docs/RELEASE_GUIDE.md`.
- [x] Recheck every documented command against the final code and build output.
- [x] Run a final documentation link, stale-text, formatting, and diff check.

## 3. Academic report

- [x] Produce an initial 26-page report with `latexmk` and inspect its compiler
      log and page contact sheet.
- [x] Remove the monolithic source in response to the formatting review.
- [x] Complete modular report files under `report/sections`, `report/tables`,
      `report/figures`, and `report/images`.
- [x] Keep the report focused on the product, implementation, architecture,
      testing, collaboration, and self-assessment; omit filming plans and
      submission-management checklists.
- [x] Generate authentic screenshots from actual Flutter widgets after the
      final code corrections.
- [x] Insert and caption screenshots and original engineering diagrams.
- [x] Compile the final PDF with `latexmk`.
- [x] Confirm 10--30 pages and zero LaTeX errors, missing glyphs, unresolved
      references, or overfull boxes.
- [x] Render and visually inspect every final PDF page.

## 4. Code corrections

- [x] Fix tracker active-time accounting so permission-dialog time is excluded.
- [x] Add a regression test for delayed location permission.
- [x] Add release Internet permission for optional Supabase sharing.
- [x] Permit cleartext HTTP only in the Android debug manifest for local-server
      testing; keep release traffic secure.
- [x] Make locally served share links reachable from the caller-facing origin.
- [x] Add production-bootstrap coverage that catches unsupported platform setup.
- [x] Resolve or clearly contain legacy fixture/demo entry-point confusion.
- [x] Review remaining cross-feature presentation imports and move shared visual
      constants or navigation ownership where a safe focused change is possible.
- [x] Review photo cleanup, History deletion recovery, and Story Studio template
      switching; fix release-impacting failure paths and test them.

## 5. Verification and release artifact

- [x] Run the initial static analysis: no issues.
- [x] Run the initial automated suite and preserve its results as a baseline.
- [x] Confirm the web target compiles, while documenting that production web
      runtime is unsupported because persistence is mobile-only.
- [x] Confirm no Android emulator or connected Android device is currently
      available on this computer.
- [x] Format every changed Dart file.
- [x] Run final static analysis: no issues.
- [x] Run the complete final test suite: all 58 tests passed.
- [x] Build the Android debug APK.
- [x] Build the signed release APK using the repository's private ignored
      signing configuration, without exposing credentials.
- [x] Copy the verified release output to `apk/app-release.apk`.
- [x] Inspect APK metadata, including application ID and minimum API 24.
- [x] Record the hardware limitation explicitly: no Android target is available
      on this computer for a fresh install; prior repository evidence covers an
      emulator install, while the recording device will provide the final live
      smoke test.

## 6. Screenshots and visual assets

- [x] Generate screenshots for Explore, route details, active tracking,
      History/run summary, and Story Studio using real app widgets.
- [x] Preserve the reviewed screenshots in the report and remove the
      platform-sensitive screenshot comparison tests from the CI suite.
- [x] Add only original or license-compatible app assets after code verification.
- [x] Record the source/license or generation prompt for each new asset.
- [x] Re-run asset-loading tests and the Android build after asset integration.

## 7. Submission readiness

- [x] Ensure the required source, Git history, README, report PDF, and release APK
      are present in their expected locations.
- [x] Prepare and dry-run the required ZIP packaging helper without caches,
      secrets, temporary render files, or private location/photo data.
- [x] Confirm all four members remain credited in the report and Git evidence.
- [ ] Replace the video placeholder and run `tools/package_submission.ps1` to
      create the final ZIP after the recording is uploaded.
- [ ] Leave only: record the 5--10 minute video with all four members, upload it
      with accessible permissions, insert the final link, and submit once.

## Known ownership and preservation notes

- `pubspec.lock` was already modified before this pass and must not be discarded.
- Existing team commits and MIT attribution must remain intact.
- Never add Supabase service-role keys, signing secrets, private tracks, or
  retained user photos to Git or the submission archive.
