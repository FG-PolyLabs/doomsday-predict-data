# doomsday-predict-data

Published data files for the **doomsday-predict** system. This repo is the static snapshot layer — data is written here by the backend and read by the frontend.

## Multi-Repo Project

This is one of three repos:

| Repo | Purpose |
|------|---------|
| [doomsday-predict-frontend-admin](https://github.com/FG-PolyLabs/doomsday-predict-frontend-admin) | Admin UI (Hugo + Firebase Auth) |
| [doomsday-predict-analytics](https://github.com/FG-PolyLabs/doomsday-predict-analytics) | Backend: Cloud Run API + scheduled jobs |
| [doomsday-predict-data](https://github.com/FG-PolyLabs/doomsday-predict-data) | This repo — published JSON data files |

## Contents

```
.
├── data/
│   └── markets.jsonl       # Market configs (one JSON object per line)
└── schema/
    ├── markets.json         # BigQuery schema for the markets table
    └── items.json           # BigQuery schema for the items table
```

## Data Flow

Data in this repo is **written by the backend** and **read by the frontend** — it is never edited manually.

```
BigQuery (doomsday.markets)
    │
    │  POST /api/v1/markets/export  (Cloud Run API)
    ▼
gs://fg-polylabs-doomsday/data/markets.jsonl   (GCS)
    │
    │  GitHub commit (via GitHub API)
    ▼
data/markets.jsonl   (this repo)
    │
    │  jsDelivr CDN  →  frontend GitHub source
    │  GCS           →  frontend GCS source
    ▼
Admin UI (doomsday-predict-frontend-admin)
```

To trigger an export, click **Sync GitHub/GCS** in the admin UI or call:

```
POST /api/v1/markets/export
```

## GCS CORS

The `gs://fg-polylabs-doomsday` bucket has CORS configured to allow `GET` from any origin so the frontend can fetch directly from the browser.

## License

GPL-3.0 — see [LICENSE](LICENSE).
