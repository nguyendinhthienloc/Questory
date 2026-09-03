# Online route sharing

Questory keeps local SQLite as the source of truth. Online sharing is an
optional Supabase adapter and is disabled when the app is built without the
Supabase defines.

## Deploy

1. Create a Supabase project and install the Supabase CLI.
2. Link the project, then apply the migration and deploy the function:

```shell
supabase db push
supabase functions deploy share-run
```

The Edge Function uses `SUPABASE_SERVICE_ROLE_KEY` internally. Never put that
key in Flutter or commit it. The Flutter app only receives the project URL and
anon key:

```shell
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Without both defines, the online button is hidden and the complete offline
flow remains available.

## API

- `POST /functions/v1/share-run` creates a link. The default expiry is 24
  hours; the server clamps expiry to 5 minutes through 7 days.
- `GET /functions/v1/share-run?shareId=...&token=...` returns the public run
  preview as JSON. The app client uses the `X-Share-Token` header instead of
  putting the token in its request URL.
- `DELETE /functions/v1/share-run?shareId=...` revokes a link and requires
  `X-Share-Token`.

Route metrics, GPS points, landmarks, quest status, and quest photos are
uploaded. Local photo paths are never uploaded. Photos are stored in a private
Storage bucket, limited to 10 MB each, and exposed only through signed URLs
valid for one hour. Tokens are random, stored only as SHA-256 hashes, and
expire or can be revoked.

The current first version shares a browser-readable JSON endpoint. A polished
public map/viewer and app deep link can be added later without changing the
local run model or the server contract.
