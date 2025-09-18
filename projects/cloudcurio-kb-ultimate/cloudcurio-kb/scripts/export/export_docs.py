#!/usr/bin/env python3
import os, sys, json, csv, argparse, anyio
from terminus_client import TerminusClient

async def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--format", choices=["ndjson","csv"], default="ndjson")
    ap.add_argument("--out", required=True)
    ap.add_argument("--limit", type=int, default=100000)
    ap.add_argument("--batch", type=int, default=1000)
    ap.add_argument("--cursor", type=int, default=0)
    args = ap.parse_args()

    t = TerminusClient()
    total = 0
    if args.format == "ndjson":
        with open(args.out, "w", encoding="utf-8") as f:
            cur = args.cursor
            while total < args.limit:
                batch = await t.list_documents(start=cur, count=min(args.batch, args.limit-total), document_type="Document")
                if not batch: break
                for row in batch:
                    f.write(json.dumps(row, ensure_ascii=False) + "\n")
                total += len(batch); cur += len(batch)
        print(f"Wrote {total} docs -> {args.out}")
    else:
        with open(args.out, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=["@id","id","title","source_uri","published_at"])
            w.writeheader()
            cur = args.cursor
            while total < args.limit:
                batch = await t.list_documents(start=cur, count=min(args.batch, args.limit-total), document_type="Document")
                if not batch: break
                for row in batch:
                    w.writerow({k: row.get(k) for k in ["@id","id","title","source_uri","published_at"]})
                total += len(batch); cur += len(batch)
        print(f"Wrote {total} docs -> {args.out}")

if __name__ == "__main__":
    anyio.run(main)
