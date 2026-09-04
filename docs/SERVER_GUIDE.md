# Questory optional server guide

**No server is required before `lib/main.dart`.** Explore, routes, Free Run,
tracking, photo quests, History, achievements, Story Studio, PNG export, and the
Android share sheet are local features.

Supabase is used only for anonymous, expiring completed-route links. Without
both Supabase Dart defines, the online button is hidden and the offline app is
unchanged.

## Choose a mode

- **Offline production:** start no server and run Questory on Android.
- **Hosted sharing:** recommended when a share link must open on another device.
- **Local development:** Supabase CLI plus Docker, used only while developing
  the Edge Function.

## Local development server

Install Docker Desktop and the Supabase CLI, then start Docker. From the
repository root, initialize once if `supabase/config.toml` does not exist:

```powershell
supabase init
```

Start the stack, apply the committed migration, and serve the function:

```powershell
supabase start
supabase db reset --local
supabase functions serve share-run --no-verify-jwt
```

Keep the function terminal open. In a second terminal, obtain the local API URL
and anonymous key:

```powershell
supabase status
```

For the standard Android emulator, replace host loopback with `10.0.2.2`:

```powershell
flutter run -d <android-emulator-id> `
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 `
  --dart-define=SUPABASE_ANON_KEY=<local-anon-key>
```

The debug manifest permits local cleartext HTTP. A physical phone cannot use
`10.0.2.2`; prefer hosted HTTPS for phone testing. Stop local services with:

```powershell
supabase stop
```

## Hosted Supabase

Create a Supabase project, install the CLI, and run:

```powershell
supabase login
supabase link --project-ref <project-ref>
supabase db push
supabase functions deploy share-run --no-verify-jwt
```

Run the app with the public project URL and public anonymous key:

```powershell
flutter run -d <android-device-id> `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<public-anon-key>
```

Never put the service-role key in Flutter, documentation, screenshots, chat, or
source control. Supabase supplies it directly to the function environment.

## End-to-end sharing check

1. Complete and save a non-sensitive demo run.
2. Open Run Summary and select `SHARE ROUTE ONLINE`.
3. Confirm the disclosure appears before any upload.
4. Select `SHARE` and wait for `Share link copied`.
5. Open the link and verify metrics, quests, captions, and evidence images.
6. Disable networking and confirm the local run, story, and export still work.
7. Revoke the link or allow its default 24-hour expiry.

If the button is missing, both Dart defines were not supplied to the build being
tested. If the function fails, inspect the serving terminal, run
`supabase status`, and confirm the URL and key belong to the same stack.

## API and privacy behavior

- `POST /functions/v1/share-run` creates a link. Expiry is limited to between
  five minutes and seven days.
- Multipart `POST` with `shareId` uploads evidence up to 10 MB.
- `GET` with a share ID and token returns the shared preview.
- `DELETE` with `X-Share-Token` revokes the link.
- Route data and selected evidence leave the device only after confirmation.
- Local filesystem paths are never uploaded. Tokens are stored as SHA-256
  hashes, and private images use one-hour signed URLs.

Official references: [Supabase local development](https://supabase.com/docs/guides/local-development/cli-workflows)
and [Edge Function development](https://supabase.com/docs/guides/functions/development-environment).
