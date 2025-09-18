#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Auto-topic discovery using UMAP dimensionality reduction and HDBSCAN clustering.
Produces a list of topic clusters with representative keywords and member chunks.
"""
from __future__ import annotations
from pathlib import Path
from typing import List, Dict, Any
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
import umap
import hdbscan

def discover_topics(embeddings: List[List[float]], chunk_meta: List[Dict[str,Any]]):
    if not embeddings: return []
    X = np.array(embeddings, dtype=np.float32)
    reducer = umap.UMAP(n_neighbors=15, min_dist=0.1, n_components=10, random_state=42)
    Xr = reducer.fit_transform(X)
    clusterer = hdbscan.HDBSCAN(min_cluster_size=8, metric='euclidean')
    labels = clusterer.fit_predict(Xr)
    clusters: Dict[int, List[int]] = {}
    for i, lbl in enumerate(labels):
        if lbl == -1:  # noise
            continue
        clusters.setdefault(int(lbl), []).append(i)
    topics = []
    for cid, idxs in clusters.items():
        texts = [chunk_meta[i]['text'] for i in idxs]
        vec = TfidfVectorizer(max_features=50, stop_words='english')
        tf = vec.fit_transform(texts)
        scores = tf.sum(axis=0).A1
        vocab = vec.get_feature_names_out()
        top_idx = scores.argsort()[-10:][::-1]
        keywords = [str(vocab[i]) for i in top_idx]
        members = [{k:v for k,v in chunk_meta[i].items() if k!='text'} for i in idxs]
        topics.append({"cluster": int(cid), "keywords": keywords, "members": members})
    return topics

def write_topics_markdown(out_dir: Path, topics: List[Dict[str,Any]]):
    out = Path(out_dir) / "topics.md"
    lines = ["# Auto-Discovered Topics",""]
    for t in topics:
        lines.append(f"## Cluster {t['cluster']}")
        lines.append("**Keywords:** " + ", ".join(t['keywords']))
        lines.append("")
        for m in t['members'][:50]:
            lines.append(f"- {m.get('title','(untitled)')} — {m.get('url','')} (chunk {m.get('chunk_index')})")
        lines.append("")
    out.write_text("\n".join(lines), encoding='utf-8')
    return out
