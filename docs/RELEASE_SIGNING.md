# Questory Android release signing

The checked-in project never contains a signing password or private key.
`android/app/build.gradle` deliberately stops a release build when the ignored
`android/key.properties` file is missing or incomplete.

## Current computer

This computer is configured with:

- private keystore: `%USERPROFILE%\.questory\release\questory-upload.jks`
- private Gradle properties: `android/key.properties`
- key alias: `questory-upload`

Both private files are excluded from Git and from the submission packaging
script. Do not paste their contents into documentation, chat, screenshots, or
the ZIP. Back up both files together in a team-controlled secure location. The
same key is required to publish an update under the same Android application
identity.

## Build and verify

From the repository root:

```powershell
flutter build apk --release
```

The signed output is
`build/app/outputs/flutter-apk/app-release.apk`. Copy that exact file to
`apk/app-release.apk` only after a successful build. Android's `apksigner`
should report `Verifies`, and `aapt dump badging` should report:

- package: `com.nguyendinhthienloc.questory`
- application label: `Questory`
- minimum SDK: `24`
- version name: `1.0.0`

The release generated on 5 September 2026 was signed with one RSA 2048-bit
signer and APK Signature Scheme v2. Its submission-copy SHA-256 is:

```text
9BA83EE47A9CE4F0D7E0714F9E57ECE0D3F5A9C1075D539E6202A88EFD574D6F
```

Rebuilding the app can legitimately change the APK hash. Re-run signature and
manifest verification after every rebuild.
