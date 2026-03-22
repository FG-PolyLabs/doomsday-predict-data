#!/usr/bin/env bash
# seed_markets.sh — Create the doomsday.markets BQ table and seed it from data/markets.jsonl.
#
# Usage:
#   bash scripts/seed_markets.sh              # create table (if absent) + seed from JSONL
#   bash scripts/seed_markets.sh --export-csv # export current BQ table to data/markets.csv
#   bash scripts/seed_markets.sh --import-csv # load data/markets.csv into BQ (replaces table)
#
# Requirements: bq CLI, python3, pyyaml

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$REPO_ROOT/config.yaml"
SCHEMA="$REPO_ROOT/schema/markets.json"
JSONL="$REPO_ROOT/data/markets.jsonl"
CSV="$REPO_ROOT/data/markets.csv"

PROJECT=$(python3 -c "import yaml; c=yaml.safe_load(open('$CONFIG')); print(c['gcp']['project_id'])")
DATASET=$(python3 -c "import yaml; c=yaml.safe_load(open('$CONFIG')); print(c['bigquery']['dataset'])")
TABLE="$DATASET.markets"

case "${1:-}" in

  --export-csv)
    echo "Exporting $PROJECT:$TABLE -> $CSV"
    bq query \
      --project_id="$PROJECT" \
      --format=csv \
      --use_legacy_sql=false \
      "SELECT id, slug, tag, slug_prefix, category, active, created_at, updated_at
       FROM \`$PROJECT.$TABLE\`
       ORDER BY category, id" \
      > "$CSV"
    echo "Exported $(( $(wc -l < "$CSV") - 1 )) rows to $CSV"
    ;;

  --import-csv)
    echo "Importing $CSV -> $PROJECT:$TABLE"
    bq load \
      --project_id="$PROJECT" \
      --source_format=CSV \
      --skip_leading_rows=1 \
      --replace \
      "$TABLE" \
      "$CSV" \
      "$SCHEMA"
    echo "Done."
    ;;

  *)
    # Create table if it doesn't already exist
    if ! bq show --project_id="$PROJECT" "$TABLE" &>/dev/null; then
      echo "Creating $PROJECT:$TABLE"
      bq mk \
        --project_id="$PROJECT" \
        --table \
        "$TABLE" \
        "$SCHEMA"
    else
      echo "Table $PROJECT:$TABLE already exists — data will be replaced"
    fi

    echo "Loading $JSONL -> $PROJECT:$TABLE"
    bq load \
      --project_id="$PROJECT" \
      --source_format=NEWLINE_DELIMITED_JSON \
      --replace \
      "$TABLE" \
      "$JSONL" \
      "$SCHEMA"

    COUNT=$(wc -l < "$JSONL")
    echo "Done. $COUNT markets seeded into $PROJECT:$TABLE"
    ;;

esac
