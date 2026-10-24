# Training Record App

Personal endurance + calisthenics tracker.

## Stack

- **iOS:** SwiftUI (`apps/mobile`)
- **API:** NestJS in-memory store + cache (`apps/api`)
- **Programs:** seed JSON from PDFs (`packages/programs`)

## Run the API

```bash
cd apps/api
npm install
npm run start:dev
```

API listens on `http://127.0.0.1:3000`.

## Run the iOS app

1. Start the API first.
2. Open `apps/mobile/TrainingRecordApp.xcodeproj` in Xcode.
3. Select an iPhone simulator and Run.

The app talks to `http://127.0.0.1:3000` (see `API_CONFIG`).

## Regenerate program seeds

```bash
pip install pymupdf
python3 apps/api/scripts/extract-programs.py
```

PDFs are expected under `~/Desktop/marathon/`.

## Features

- Home: 5-day calendar strip + Endurance / Calisthenics hero cards
- Program detail: vertical schedule, today’s checkboxes, status colors
- Feedback bottom sheet after completing an exercise (good / so-so / missed + edits)
- Move a session to another weekday
