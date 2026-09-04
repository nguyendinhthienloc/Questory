# Optional online route sharing

Questory keeps local SQLite as the source of truth. Supabase is an optional
adapter used only for anonymous, expiring completed-route links. Without both
Supabase Dart defines, the online button is hidden and every core feature still
works.

## Which server setup should be used?

- For the complete offline Android app: start no server. Run the APK or
  `flutter run -d <android-device-id>`.
- For the optional share-link button during filming: use a hosted Supabase
  project over HTTPS. This is the most reliable Android setup.
- For Edge Function development: use the local Supabase stack and Docker. Do
  not expose the local stack publicly; it is a development environment.

Official references: [Supabase CLI local development](https://supabase.com/docs/guides/local-development/cli-workflows)
and [Edge Function development](https://supabase.com/docs/guides/functions/development-environment).

## Recommended: hosted Supabase

Prerequisites:

- A Supabase project.
- Supabase CLI installed and available as `supabase`.
- The project reference from the Supabase dashboard URL.

From the Questory repository root:

```powershell
supabase login
supabase link --project-ref <project-ref>
supabase db push
supabase functions deploy share-run
```

The migration creates `shared_run_links` and the private
`shared-run-images` bucket. The function receives `SUPABASE_URL` and
`SUPABASE_SERVICE_ROLE_KEY` from its hosted environment. Never place the
service-role key in Flutter or commit it.

Get the project URL and public anon key from Supabase project settings, then
run Questory on Android:

```powershell
flutter run -d <android-device-id> `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<public-anon-key>
```

For a release build with the optional button enabled:

```powershell
flutter build apk --release `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<public-anon-key>
```

Install the newly built APK and test the exact artifact that will be submitted.
If either define is missing, the app intentionally stays in offline-only mode.

## Local server for development

Local Supabase requires Docker Desktop or another Docker-compatible runtime.
The repository already contains the migration and `share-run` function. If
`supabase/config.toml` does not exist, initialize the local project once:

```powershell
supabase init
```

Start the stack, apply all migrations from a clean local database, and serve
the function with hot reload:

```powershell
supabase start
supabase db reset --local
supabase functions serve share-run
```

Keep the function terminal open. In another terminal, print the local URL and
keys:

```powershell
supabase status
```

For an Android emulator, replace the host loopback address with
`10.0.2.2`. For example, if `supabase status` reports
`http://127.0.0.1:54321`, launch the debug app with:

```powershell
flutter run -d <android-emulator-id> `
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 `
  --dart-define=SUPABASE_ANON_KEY=<local-anon-key>
```

The debug Android manifest permits cleartext traffic only for local testing.
Do not add cleartext permission to the release manifest. A physical phone
cannot use `10.0.2.2`; use the development computer's reachable LAN address
and an appropriate debug-only network configuration, or use hosted Supabase.

Stop the local stack when finished:

```powershell
supabase stop
```

## Functional test

1. Complete and save a run locally.
2. Open Run Summary and verify `SHARE ROUTE ONLINE` is visible.
3. Tap it, read the data disclosure, and choose `SHARE` only for a non-sensitive
   demo run.
4. Wait for `Share link copied`, then paste the link into a private browser
   window.
5. Confirm route metrics, quests, captions, and signed evidence images load.
6. Disable networking and confirm the saved run, History, and Story Studio
   remain available.
7. Do not show private keys, precise personal routes, or sensitive captions in
   the recording.

## API and privacy behavior

- `POST /functions/v1/share-run` creates a link. Expiry is clamped from five
  minutes to seven days; the app defaults to 24 hours.
- Multipart `POST` with `shareId` uploads one evidence image, limited to 10 MB.
- `GET` with a share ID and token returns the shared preview.
- `DELETE` with `X-Share-Token` revokes the link.
- GPS points, metrics, landmarks, quest status, captions, and selected photos
  are uploaded only after the user confirms the app's disclosure dialog.
- Local file paths are never uploaded. Tokens are stored as SHA-256 hashes,
  and images stay in a private bucket behind one-hour signed URLs.
