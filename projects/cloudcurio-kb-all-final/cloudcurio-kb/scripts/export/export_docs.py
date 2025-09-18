#!/usr/bin/env python3
import os, sys, json, csv, argparse, anyio

async def fetch_batch(offset: int, limit: int):
    return [{"id": f"doc_{i}", "title": f"Title {i}"} for i in range(offset, offset+limit)]

async def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--format", choices=["ndjson","csv"], default="ndjson")
    ap.add_argument("--out", required=True)
    ap.add_argument("--limit", type=int, default=10000)
    ap.add_argument("--batch", type=int, default=1000)
    args = ap.parse_args()
    if args.format == "ndjson":
        with open(args.out, "w", encoding="utf-8") as f:
            for start in range(0, args.limit, args.batch):
                batch = await fetch_batch(start, min(args.batch, args.limit-start))
                for row in batch:
                    f.write(json.dumps(row, ensure_ascii=False)+"\n")
        print("NDJSON export complete:", args.out)
    else:
        with open(args.out, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=["id","title"])
            w.writeheader()
            for start in range(0, args.limit, args.batch):
                batch = await fetch_batch(start, min(args.batch, args.limit-start))
                w.writerows(batch)
        print("CSV export complete:", args.out)

if __name__ == "__main__":
    anyio.run(main)
