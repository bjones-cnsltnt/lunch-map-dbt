#!/usr/bin/env python3
"""Pull the public restaurant feed from the Tulsa Lunch Map app into a dbt seed.

No credentials: the feed is the same JSON the public web app loads. Rows are
sorted by place_id so re-extracts produce a stable, reviewable diff. The nested
metadata object is kept as a JSON string; dbt staging models unpack it in SQL
so the parsing logic is versioned, tested and visible in lineage.

Usage:  python scripts/extract_spots.py [--url URL] [--out seeds/raw_spots.csv]
"""
import argparse
import csv
import datetime as dt
import json
import sys
import urllib.request

DEFAULT_URL = "https://lunch.jonesgroup.dev/api/spots"
COLUMNS = ["id", "place_id", "name", "price_label", "lat", "lng", "metadata", "extracted_at"]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default=DEFAULT_URL)
    ap.add_argument("--out", default="seeds/raw_spots.csv")
    args = ap.parse_args()

    with urllib.request.urlopen(args.url, timeout=30) as resp:
        payload = json.load(resp)
    rows = payload if isinstance(payload, list) else payload.get("spots") or payload.get("data")
    if not rows:
        print("no rows returned", file=sys.stderr)
        return 1

    today = dt.date.today().isoformat()
    with open(args.out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, quoting=csv.QUOTE_MINIMAL)
        w.writeheader()
        for r in sorted(rows, key=lambda r: r["place_id"]):
            w.writerow({
                "id": r["id"],
                "place_id": r["place_id"],
                "name": r["name"],
                "price_label": r["price_label"],
                "lat": r["lat"],
                "lng": r["lng"],
                "metadata": json.dumps(r.get("metadata") or {}, sort_keys=True, separators=(",", ":")),
                "extracted_at": today,
            })
    print(f"wrote {len(rows)} rows to {args.out} (extracted {today})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
