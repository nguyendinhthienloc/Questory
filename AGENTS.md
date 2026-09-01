# AGENTS.md - Questory engineering contract

Read this file before modifying the repository. `README.md` defines the product, `TODO.md` defines priorities and owners, and this file defines safe parallel development.

## Product invariant

Questory is an offline-first Vietnam running/travel diary. Users select a curated route or free run, record GPS points, complete location-aware photo quests, and produce an editable 1080 x 1920 story infographic.

The release demo must work offline after installation and permission grant. Live sharing, weather, remote content, and Canva are optional adapters, never prerequisites.

## Current repository reality

The current Flutter camera prototype is baseline material, not the target architecture:

- The Questory package/application identity migration is complete; inherited camera-screen debt remains.
- Photo history is an in-memory global list of temporary paths.
- Permission and camera failures are not represented safely.
- UI, business logic, and state are mixed.
- The generated test does not describe Questory.
- API 24 is not explicitly enforced.
- Flutter is not currently on this machine's `PATH`.

Do not preserve baseline design merely because it exists. Preserve the MIT attribution in `LICENSE` and never erase unrelated user work.

## Non-negotiable decisions

- Flutter/Dart unless the whole team changes it.
- Installable Android app with minimum API 24.
- Nha Trang and Ho Chi Minh City launch packs.
- Curated-route and free-run modes.
- English-first and local source of truth.
- No account required for MVP.
- Templates plus freeform Story Studio.
- Colorful film/sticker design with solid colors and no gradients.
- Personal achievements; no public leaderboard.
- PNG export and Android share sheet.
- Online behavior isolated behind interfaces and disabled gracefully.

## Architecture

```text
lib/
  app/                    # navigation, theme, dependency assembly
  core/
    domain/               # immutable shared models
    contracts/            # repository/device interfaces
    fixtures/             # deterministic fakes and examples
    platform/             # permission/platform abstractions
    errors/
  features/
    destinations/
      presentation/
      application/
    tracking/
      presentation/
      application/
    quest_camera/
      presentation/
      application/
    story_studio/
      presentation/
      application/
    history/
      presentation/
      application/
  data/
    local/
    repositories/
    optional_remote/
assets/
  destinations/
  story/
```

Rules:

- Presentation depends on `core/domain` and `core/contracts`, not concrete storage.
- One feature must not import another feature's private UI or implementation.
- `data` implements contracts; contracts never depend on `data`.
- Wrap platform plugins behind small services where practical.
- Optional remote code must not leak networking concerns into domain models.
- Do not use mutable globals or direct filesystem access from widgets.

## Shared domain language

Create immutable shared objects before feature-specific variants:

- `GeoPoint`: latitude, longitude, timestamp, optional accuracy/altitude.
- `DestinationPack`: city metadata, version, routes, and quests.
- `RoutePlan`: identity, expected polyline, distance, landmarks, quest IDs.
- `Quest`: prompt, point/radius, evidence requirement, fallback rule.
- `QuestEvidence`: local photo reference, point, timestamp, caption, quest ID.
- `RunSession`: run lifecycle represented by immutable snapshots.
- `RunSummary`: final track, duration, distance, pace, evidence, derived metrics.
- `StoryProject`: canvas, ordered elements, transforms, styles, source run.
- `Achievement`: stable ID, criteria, progress, unlock timestamp.

Use stable string IDs. Store timestamps in UTC and display local time. Store distances in meters and convert only in presentation.

## Parallel-work contracts

Initial interfaces:

- `DestinationRepository`
- `RunRepository`
- `StoryRepository`
- `AchievementRepository`
- `LocationTracker`
- `PhotoStore`
- `StoryRenderer`
- `ShareService`
- `Clock`
- Optional `LiveShareService`, `WeatherService`, `CanvaHandoffService`

Every interface needs a deterministic fake. A feature owner must not wait for a database, device, backend, or other screen.

When a contract changes:

1. Explain the use case.
2. Identify affected owners.
3. Update fake and real implementations together where possible.
4. Temporarily preserve behavior needed by parallel branches.
5. Update this file if architectural meaning changes.

## Ownership

| Owner | Module | Primary write scope |
| --- | --- | --- |
| Nguyen Trong Van Viet | Destinations/quests | `features/destinations`, `assets/destinations` |
| Nguyen Hong Tan Tai | Tracking/location | `features/tracking`, tracking platform adapter |
| Nguyen Dinh Thien Loc | Story Studio/export | `features/story_studio`, `assets/story` |
| Tran Le Anh Tuan | Persistence/history/integration | `data`, `features/history`, `app` |

`pubspec.yaml`, Android manifests, `core/domain`, `core/contracts`, and navigation are integration hotspots. Coordinate before changing them. Ownership means responsibility, not exclusivity; review across modules, but do not silently redesign another owner's interface.

## Workflow

Before work:

1. Read this file and the relevant README/TODO sections.
2. Inspect existing changes and preserve others' work.
3. Identify the owning module and contracts.
4. Use fixtures for unfinished dependencies.
5. Keep the change independently reviewable.

Before handoff:

1. Format changed Dart files.
2. Run analysis and relevant tests when Flutter is available.
3. Exercise offline and denied-permission behavior when relevant.
4. State what was and was not verified.
5. Check TODO items only when acceptance criteria pass.

## Offline and reliability rules

- Never require map tiles to start, record, finish, or review a run.
- Bundled city packs load without network access.
- Checkpoint active runs incrementally.
- Copy retained photos into app-controlled storage.
- Treat camera capture paths as temporary until copied.
- Network failure never rolls back local run or story data.
- Provide recovery for denied permission and disabled GPS.
- Keep image export, storage, and long tracks off blocking UI paths.
- Clearly label estimated calories and unavailable/cached weather.

## Location, privacy, and safety

- Request only permissions needed by a user-visible feature.
- Explain location access immediately before requesting it.
- Background tracking uses a compliant foreground service and notification.
- Begin tracking only after explicit action.
- Make pause, finish, discard, and stop-sharing controls obvious.
- Do not unnecessarily log precise tracks, image paths, or captions.
- Live sharing is opt-in, visible, revocable, and time-limited.
- Never commit backend credentials, map keys, or private routes.
- Validate public access, but never promise that a route is safe.

## Story Studio

- Canonical output is 1080 x 1920.
- Persist a serializable document, not only widget state.
- Export must be deterministic from the saved document.
- Selection controls and guides never appear in output.
- Templates are original story documents, not hard-coded screens.
- Use solid colors only; do not add gradients.
- Keep gestures discoverable and touch targets usable.
- Fonts, stickers, icons, and textures require compatible licenses.
- Online templates may inspire principles but cannot be copied.

## Minimum testing

Pure logic:

- Distance calculation and invalid GPS jump filtering
- Active versus paused duration
- Pace and zero-distance handling
- Quest proximity/fallback completion
- Achievement evaluation
- Story serialization, transforms, undo/redo

UI:

- Explore populated/empty states
- Location permission denial
- Tracker start/pause/resume/finish
- Quest caption requirement
- History empty state
- Story export readiness/error state

Before release, test a full airplane-mode flow and install the APK on a clean API 24+ target.

## Dependencies

Before adding a package, verify Dart/Flutter and API 24 support, maintenance, licensing, offline behavior, permissions, and transitive minimum-SDK effects. Do not add a large framework for a small utility.

Pin dependencies with `pubspec.lock` for reproducible application builds. Revisit the baseline `.gitignore`, which currently excludes that lockfile.

## Code-Graph-RAG

Code-Graph-RAG is optional agent infrastructure. It supplements this document; it does not replace contracts, tests, or direct source inspection.

Prerequisites: Python 3.12+, Docker, CMake, ripgrep, `uv`, and a supported model provider or local model. This machine currently has all listed system prerequisites except `uv`.

Install outside the Flutter application source:

```shell
uv tool install "code-graph-rag[treesitter-full,semantic]"
cgr daemon up
cgr start --repo-path . --update-graph
cgr start --repo-path .
```

For MCP, use the server command documented by Code-Graph-RAG and set `TARGET_REPO_PATH` to the absolute checkout. Provider endpoints and keys belong in private environment/client configuration.

When available:

1. Update the graph incrementally before trusting it.
2. Use semantic search for intent and graph queries for relationships.
3. Confirm retrieved code in the working tree; indexes may be stale.
4. Preview structural replacements and inspect diffs.
5. Never delete projects or wipe the database during routine work.
6. If unavailable, continue with source search, fixtures, and tests.

Never commit `.env`, provider keys, Memgraph/Qdrant data, indexes, logs, or graph exports unless the team explicitly approves a small reviewed artifact.

## Git collaboration

- Preserve each member's visible commit history.
- Use focused commits describing behavior.
- Do not mix unrelated formatting and feature changes.
- Never commit secrets, caches, build output, graph data, or private tracks.
- Never rewrite shared history or discard another person's changes.
- Agree on shared contracts before resolving implementation conflicts.
- Keep the main branch buildable after the initial migration.

Suggested branches:

- `feature/destinations-quests`
- `feature/run-tracking`
- `feature/story-studio`
- `feature/history-persistence`

Use the `codex/` prefix when creating branches through a Codex workflow that requires it.

## Documentation and submission

Update the closest source of truth:

- Product/setup: `README.md`
- Work status/acceptance: `TODO.md`
- Architecture/team process: `AGENTS.md`
- Route/quest content: versioned destination assets

The final package requires the working APK, source/history, 10-30 page report, and accessible 5-10 minute demo with all four members speaking. Never report an incomplete stretch feature as completed.

## Safe agent change

A change is ready when it is scoped, respects ownership, preserves unrelated work, includes proportionate tests, handles offline/error cases, and states verification limits. Stop for team approval before introducing a backend, paid API, external account, destructive migration, or new permission outside this agreed scope.
