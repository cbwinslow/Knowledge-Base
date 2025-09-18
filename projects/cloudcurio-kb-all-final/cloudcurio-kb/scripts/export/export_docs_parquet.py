#!/usr/bin/env python3
import argparse, pandas as pd
def fetch_dataframe(limit: int = 10000):
    return pd.DataFrame([{"id": f"doc_{i}", "title": f"Title {i}"} for i in range(limit)])
if __name__ == "__main__":
    ap = argparse.ArgumentParser(); ap.add_argument("--out", required=True); ap.add_argument("--limit", type=int, default=100000)
    args = ap.parse_args()
    df = fetch_dataframe(args.limit)
    df.to_parquet(args.out, engine="pyarrow", index=False)
    print("Parquet export complete:", args.out)
