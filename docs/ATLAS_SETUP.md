# Atlas setup for Training Record (no Nest server)

## Credentials (do not push to GitHub)

Put the URI only in **`apps/mobile/.env`** (gitignored):

```bash
cp apps/mobile/.env.example apps/mobile/.env
# edit MONGODB_URI → training-record DB (not tutorfroggy-production)
```

Xcode runs `apps/mobile/scripts/generate-mongo-secrets.sh` before compile. It writes  
`TrainingRecordApp/Generated/MONGODB_SECRETS.swift` (also gitignored).

Never commit:

- `apps/mobile/.env`
- `TrainingRecordApp/Generated/MONGODB_SECRETS.swift`

Committed placeholders: `apps/mobile/.env.example`

## Temporary approach

The app connects **directly** with that URI (MongoKitten) for private TestFlight / solo testing.

**Before a public App Store release:** rotate the DB password, stop using a cluster URI in the client, switch to App Services (API key / Device SDK).

## Database

Same Atlas cluster as TutorFroggy, different DB: **`training-record`**.

Collections (see `scripts/setup-training-record-db.mjs`): `programs`, `sessions`, `_meta`.
