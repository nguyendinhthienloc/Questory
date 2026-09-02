# Dependency and asset review

Reviewed: 2 September 2026

Questory deliberately uses small device/storage plugins rather than a large
application framework. `pubspec.lock` is the reproducible source for the full
resolved graph.

| Direct package | Resolved | Purpose | License reviewed | Offline behavior |
| --- | ---: | --- | --- | --- |
| `camera` | 0.10.6 | Quest evidence capture | BSD 3-Clause | Device only |
| `geolocator` | 14.0.3 | Foreground GPS points and permission state | MIT | Device only |
| `path_provider` | 2.1.6 | App-controlled photo/export locations | BSD 3-Clause | Local only |
| `sqflite` | 2.4.2+1 | Runs, checkpoints, stories, achievements | BSD 2-Clause | Local only |
| `cupertino_icons` | 1.0.9 | Flutter icons | MIT | Bundled |

The Android app explicitly sets minimum SDK 24. A release APK compiled and ran
on API 37, but a clean API 24 installation remains a release verification item.
No package requires a network request for the offline MVP.

The Story Studio bundles Noto Sans and Space Grotesk variable fonts. Their OFL
license texts are stored beside the font files under `assets/story/fonts/`.
Destination packs contain team-authored JSON content and no third-party image
assets. The app uses Flutter's bundled Material icons. The inherited MIT
attribution remains in the repository `LICENSE`.
