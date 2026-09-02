# Questory implementation plan

Deadline: **September 5, 2026 at 23:59**. The offline demonstration takes priority over incomplete online integrations.

Legend: `[ ]` not started, `[-]` in progress, `[x]` verified, `[!]` blocked.

## Frozen decisions

- Vietnam running/travel diary for casual users
- Nha Trang and Ho Chi Minh City launch packs
- Curated routes and free-run mode
- English-first, offline-first Android app
- Template-assisted freeform Story Studio
- Colorful film/sticker style with solid colors and no gradients
- No account required; Android export and sharing
- Personal achievements rather than a public leaderboard
- Code-Graph-RAG configuration included but optional per member

## Scope guardrail

Do not begin live sharing, Canva OAuth, live weather, remote content, or extra cities until the complete offline flow works on Android. The demo must pass in airplane mode after installation and permission grant.

## Day zero - whole team

- [ ] Confirm the four module assignments.
- [x] Make Flutter available and record `flutter --version`.
- [x] Run the baseline and record known failures.
- [x] Set Android minimum SDK to API 24.
- [x] Rename the Dart package, Android namespace/application ID, and app label.
- [x] Create the feature-first skeleton in `AGENTS.md`.
- [x] Agree on immutable models: destination, route, quest, point, run, evidence, story, achievement.
- [x] Freeze repository/device interfaces for the first development pass.
- [x] Add deterministic city, run, and story fixtures.
- [x] Add the solid-color app theme.
- [x] Verify that every feature can run with fake repositories.

## A - destinations and quests

**Owner:** Nguyen Trong Van Viet (24125023)

**Scope:** `lib/features/destinations/`, `assets/destinations/`

- [x] Define a versioned destination-pack JSON schema.
- [x] Build one Nha Trang and one Ho Chi Minh City pack.
- [x] Include at least one safe, plausible route per city.
- [x] Mix popular and lesser-known photo quests.
- [x] Give each quest a prompt, coordinates, radius, caption requirement, and GPS fallback.
- [x] Build Explore Vietnam using fixtures/repository contracts.
- [x] Build Route Details with landmarks, distance, duration, quests, and offline status.
- [x] Build free-run discovery from bundled points of interest.
- [x] Show completed, skipped, inaccurate-GPS, and empty states.
- [x] Test proximity logic with injected coordinates.
- [x] Review route text and public pedestrian access.

**Done when:** both cities and their details work in airplane mode, quest logic is testable without real GPS, and small-screen layouts do not overflow.

**Report/video:** target users, problem, originality, destination content, and Explore/Route demonstration.

## B - run and location tracking

**Owner:** Nguyen Hong Tan Tai (24125078)

**Scope:** `lib/features/tracking/`, location platform adapter

- [x] Implement idle, acquiring, active, paused, finishing, completed, and failed states.
- [x] Request location permission with an in-context explanation.
- [x] Handle approximate/denied/permanently denied permission and disabled GPS.
- [x] Record timestamped points during an active run.
- [x] Filter clearly invalid GPS jumps and document the rule.
- [x] Calculate active duration, distance, and average pace.
- [x] Checkpoint active state through the persistence contract.
- [x] Implement pause, resume, finish, and discard confirmation.
- [x] Render the recorded polyline on an offline tracker surface.
- [x] Expose nearby bundled quest progress.
- [ ] Implement/verify Android foreground tracking behavior.
- [x] Test calculations with a prerecorded point fixture.
- [x] Verify temporary GPS loss does not crash or silently finish a run.

**Done when:** a deterministic fixture test passes, paused time is excluded, interruption preserves a checkpoint, and a demo run can finish offline.

**Stretch:** anonymous expiring live-location sharing with visible stop and expiry controls.

**Report/video:** tracking architecture, permissions, calculations, offline behavior, and tracker demonstration.

## C - Story Studio and export

**Owner:** Nguyen Dinh Thien Loc (24125093)

**Scope:** `lib/features/story_studio/`, `assets/story/`

- [x] Define a serializable 1080 x 1920 story document.
- [x] Create at least three original starting templates.
- [x] Support photo, text, route, statistic, quest-list, sticker, and location elements.
- [x] Support select, drag, resize, rotate, reorder, duplicate, and delete.
- [x] Support photo crop/focal-position editing.
- [x] Add alignment guides or snapping.
- [x] Add undo and redo.
- [x] Add solid palettes and a small licensed font selection.
- [x] Populate a story from fixture or real `RunSummary`.
- [x] Support route, distance, duration, pace, landmarks, quests, photos, captions, and date.
- [x] Add clearly labeled estimated calories when configured.
- [x] Add cached weather only when available.
- [x] Export exactly 1080 x 1920 without editor controls.
- [-] Invoke Android sharing. Implementation is complete; device verification is pending.
- [x] Save and reopen an editable project.

**Verification (September 1, 2026):** 21 Flutter tests pass, including connected Explore/Run recap/Studio navigation, an app-scoped mock repository, a real 1080 x 1920 PNG decode, serialization/reopen coverage, editor operations, conditional recap data, export errors, and 360 x 640 layouts. Focused analysis is clean and the Edge/web build succeeds with browser PNG download. Android build and share-sheet verification remain blocked on this host because Gradle cannot establish its required local loopback connection and no Android target is connected.

**Done when:** the editor works from fixtures, export dimensions are exact, projects reopen without losing transforms/order/text, and all visual assets are original or properly licensed.

**Stretch:** Canva OAuth/create/edit handoff after the local editor and export pass.

**Report/video:** UI/UX, visual system, Story Studio, export, and editing demonstration.

## D - persistence, history, achievements, integration

**Owner:** Tran Le Anh Tuan (24125107)

**Scope:** `lib/data/`, `lib/features/history/`, `lib/app/`

- [x] Select and document a maintained SQLite-based Flutter package.
- [x] Implement repositories behind the frozen contracts.
- [x] Store runs, points, evidence metadata, stories, and achievements.
- [x] Copy retained photos into application-controlled storage.
- [x] Handle missing media safely.
- [x] Define safe deletion and cascading behavior.
- [x] Build History empty/populated/error states.
- [x] Build Run Summary and saved-story entry points.
- [x] Define and evaluate personal achievements.
- [x] Assemble navigation and dependency injection.
- [x] Add app-level recovery/error presentation.
- [x] Add a storage migration/version strategy.
- [ ] Prepare and verify release configuration.

**Done when:** data survives restart, temporary image paths are not retained, deletion cannot damage unrelated records, real repositories replace fakes without feature rewrites, and the APK installs on API 24+.

**Report/video:** persistence, tests, collaboration, setup, self-assessment, History/achievement demonstration.

## Parallel integration contract

- [x] Each workstream supplies fixture/demo data.
- [ ] Shared interface changes are agreed with affected owners.
- [x] Features never import another feature's private UI or data files.
- [x] Integration uses `core/contracts` and immutable domain objects.
- [x] Online adapters remain optional and disabled in the offline demo.
- [ ] Members make small, descriptive commits in their owned modules.

No member waits for storage, GPS, backend, or another screen: use fakes until integration.

## Quality gate before stretch work

- [x] `flutter analyze` has no errors.
- [x] Unit tests cover distance, duration, pace, proximity, achievements, and story serialization.
- [x] Widget tests cover Explore, permission denial, tracker controls, History empty state, and export state.
- [x] Camera, location, storage, and sharing failures do not cause unhandled exceptions.
- [x] Loading, success, empty, offline, and error feedback are visible.
- [x] A small API 24+ device layout is usable.
- [ ] Airplane-mode flow passes from launch to exported story.

## Code-Graph-RAG

- [ ] Install `uv` only on machines opting into the tool.
- [ ] Install Code-Graph-RAG outside the Flutter source tree.
- [ ] Start its Memgraph/Qdrant services with Docker.
- [ ] Index this repository without committing generated data.
- [ ] Configure MCP with `TARGET_REPO_PATH` set to the local checkout.
- [ ] Keep provider keys in private environment/client configuration.
- [ ] Verify Dart structural queries after the feature skeleton exists.
- [ ] Document the selected provider without exposing secrets.

Code-Graph-RAG must never block development with `AGENTS.md`, source search, fixtures, and tests.

## September 4 integration target

- [x] Connect real repositories to every module.
- [x] Connect completed runs to Story Studio.
- [x] Connect quest-camera evidence to the active run.
- [x] Verify curated and free-run paths.
- [x] Verify both destination packs.
- [ ] Test permission combinations on at least two Android versions if available.
- [ ] Run a 20-30 minute tracking smoke test.
- [x] Review dependency and asset licenses.
- [ ] Capture final screenshots.

## September 5 submission

- [ ] Freeze features.
- [x] Update README with verified versions and commands.
- [ ] Build/install `apk/app-release.apk` on a clean target.
- [ ] Produce the 10-30 page report with work division and self-assessment.
- [ ] Record a 5-10 minute demo with all four members speaking.
- [ ] Verify the public demo link.
- [ ] Preserve Git history or export `src/git-log.txt`.
- [ ] Assemble `README.md`, `src/`, `apk/`, `report/`, and `video/`.
- [ ] Name the ZIP with ascending student IDs and inspect its contents.
- [ ] Submit once through the designated representative.

## Deferred backlog

- Anonymous live route viewer
- Canva Connect integration
- Live weather
- More Vietnamese cities
- Community-created route packs
- Friend challenges, public profiles, leaderboards
- Cloud synchronization and turn-by-turn navigation

## Definition of done

A task is done only when it works on Android, relevant tests pass, offline/permission behavior is handled, English text is understandable, no secrets/generated databases are committed, documentation is current, and the owner's Git contribution is visible.
