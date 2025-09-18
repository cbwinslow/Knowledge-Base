# Profile Trades Tracker (Backend)

A production‑minded starter to follow high‑profile people and list their trades, surface leaders (YTD performance), generate per‑profile RSS feeds, allow alert subscriptions, and simulate “mirror” paper portfolios. Ships with Docker Compose and Postgres (SQLite optional for local dev).

> **Disclaimer:** Disclosures publish with delays and may be amended. This app is for research/education only and is **not** investment advice.

---

## Repo Layout

```
.
├─ backend/
│  ├─ app.py
│  ├─ requirements.txt
│  ├─ Dockerfile
│  └─ .env.example
├─ docker-compose.yml
└─ README.md
```

---

## backend/app.py

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script: app.py
Author: CBW + GPT-5 Thinking
Date: 2025-09-18
Summary:
  FastAPI backend for "Profile Trades Tracker":
  - Profiles & trades API (create/list)
  - YTD leaders ranking (toy backtest)
  - Paper-portfolio backtest per profile
  - RSS feed per profile
  - Alert subscriptions (storage only; delivery via worker to be added)
Inputs:
  HTTP requests
Outputs:
  JSON API + RSS XML
Env:
  Python 3.11+, FastAPI, SQLAlchemy
Security:
  - Input validation via Pydantic
  - Basic CORS allowlist (configure env CORS_ORIGINS)
  - JWT/OAuth planned
Modification Log:
  - 2025-09-16: Initial minimal FastAPI version
  - 2025-09-18: Dockerized; Postgres support; CORS env; APScheduler stub
"""

from __future__ import annotations
from datetime import datetime, timedelta, date
from typing import List, Optional, Dict, Literal
import math
import os
import uuid
import logging

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel, Field, HttpUrl
from sqlalchemy import (
    create_engine, Column, String, DateTime, Float, Integer, ForeignKey, Text, Date, Boolean
)
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
from sqlalchemy.sql import func

# -----------------------------------------------------------------------------
# Config & Logging
# -----------------------------------------------------------------------------
APP_NAME = "profile-trades-tracker"
DB_URL = os.getenv("DB_URL", "sqlite:///./tracker.db")
CORS_ALLOW_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]

logging.basicConfig(
    level=getattr(logging, os.getenv("LOG_LEVEL", "INFO").upper(), logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s :: %(message)s"
)
log = logging.getLogger(APP_NAME)

# -----------------------------------------------------------------------------
# DB Setup
# -----------------------------------------------------------------------------
Base = declarative_base()
engine = create_engine(DB_URL, future=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)

class Profile(Base):
    __tablename__ = "profiles"
    id = Column(String, primary_key=True)
    name = Column(String, index=True, unique=True)
    category = Column(String, index=True)  # e.g., "US-Congress", "Insider", "Fund", "Exec"
    source_url = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    trades = relationship("Trade", back_populates="profile", cascade="all,delete-orphan")

class Security(Base):
    __tablename__ = "securities"
    id = Column(String, primary_key=True)
    ticker = Column(String, index=True, unique=True)
    name = Column(String, nullable=True)

class Trade(Base):
    __tablename__ = "trades"
    id = Column(String, primary_key=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"))
    security_id = Column(String, ForeignKey("securities.id", ondelete="CASCADE"))
    direction = Column(String)  # "BUY" or "SELL"
    quantity = Column(Float)    # normalized shares (approx if disclosure uses ranges)
    price = Column(Float)       # fill price assumption (for backtests)
    filed_at = Column(DateTime) # when publicly filed/disclosed
    effective_date = Column(Date)  # when trade likely occurred (if known/estimated)
    note = Column(Text, nullable=True)

    profile = relationship("Profile", back_populates="trades")
    security = relationship("Security")

class Portfolio(Base):
    __tablename__ = "portfolios"
    id = Column(String, primary_key=True)
    label = Column(String, index=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"))
    created_at = Column(DateTime, server_default=func.now())
    initial_cash = Column(Float, default=10000.0)
    mirror_mode = Column(Boolean, default=True)  # mirror trades as they appear

class Subscription(Base):
    __tablename__ = "subscriptions"
    id = Column(String, primary_key=True)
    email = Column(String, index=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=True)
    rule = Column(String, nullable=True)  # e.g., "new_trade", "rank_change"
    created_at = Column(DateTime, server_default=func.now())

Base.metadata.create_all(engine)

# -----------------------------------------------------------------------------
# Pydantic Schemas
# -----------------------------------------------------------------------------
class ProfileIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=128)
    category: Literal["US-Congress","Insider","Fund","Exec","Other"] = "Other"
    source_url: Optional[HttpUrl] = None

class ProfileOut(ProfileIn):
    id: str
    created_at: datetime

class SecurityIn(BaseModel):
    ticker: str = Field(..., min_length=1, max_length=10)
    name: Optional[str] = None

class SecurityOut(SecurityIn):
    id: str

class TradeIn(BaseModel):
    profile_id: str
    ticker: str
    direction: Literal["BUY","SELL"]
    quantity: float = Field(..., gt=0)
    price: float = Field(..., gt=0)
    filed_at: datetime
    effective_date: date
    note: Optional[str] = None

class TradeOut(BaseModel):
    id: str
    profile_id: str
    ticker: str
    direction: str
    quantity: float
    price: float
    filed_at: datetime
    effective_date: date
    note: Optional[str] = None

class SubscriptionIn(BaseModel):
    email: str
    profile_id: Optional[str] = None
    rule: Optional[str] = "new_trade"

class PortfolioRequest(BaseModel):
    profile_id: str
    initial_cash: float = 10000.0

class BacktestResult(BaseModel):
    portfolio_value: float
    cash: float
    positions: Dict[str, float]
    pnl_percent: float
    trades_executed: int

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

def get_or_create_security(db, ticker: str) -> Security:
    sec = db.query(Security).filter_by(ticker=ticker.upper()).one_or_none()
    if sec:
        return sec
    s = Security(id=str(uuid.uuid4()), ticker=ticker.upper(), name=None)
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


def simple_price_series(ticker: str, start: date, end: date) -> Dict[date, float]:
    """Deterministic toy price series. Replace with real OHLCV provider."""
    days = (end - start).days + 1
    base = 100.0 + (hash(ticker) % 20)
    series = {}
    for i in range(days):
        d = start + timedelta(days=i)
        if d.weekday() >= 5:
            continue
        series[d] = base * (1 + 0.001 * math.sin(i/5.0)) * (1 + 0.0005 * ((i % 13) - 6))
    return series


def backtest_profile(db, profile_id: str, initial_cash: float = 10000.0) -> BacktestResult:
    trades = (
        db.query(Trade)
        .filter(Trade.profile_id == profile_id)
        .order_by(Trade.filed_at.asc())
        .all()
    )
    if not trades:
        return BacktestResult(
            portfolio_value=initial_cash, cash=initial_cash, positions={}, pnl_percent=0.0, trades_executed=0
        )

    start = min(t.effective_date for t in trades)
    end = date.today()
    cash = initial_cash
    positions: Dict[str, float] = {}

    for t in trades:
        px = t.price
        if t.direction == "BUY":
            spend = px * t.quantity
            if spend <= cash:
                cash -= spend
                positions[t.security.ticker] = positions.get(t.security.ticker, 0.0) + t.quantity
        else:
            have = positions.get(t.security.ticker, 0.0)
            qty = min(have, t.quantity)
            cash += px * qty
            positions[t.security.ticker] = have - qty

    m2m = 0.0
    for ticker, qty in positions.items():
        if qty <= 0:
            continue
        series = simple_price_series(ticker, start, end)
        if not series:
            continue
        last_px = list(series.values())[-1]
        m2m += qty * last_px

    value = cash + m2m
    pnl_pct = (value / initial_cash - 1.0) * 100.0
    return BacktestResult(
        portfolio_value=round(value, 2),
        cash=round(cash, 2),
        positions={k: round(v, 4) for k, v in positions.items()},
        pnl_percent=round(pnl_pct, 2),
        trades_executed=len(trades),
    )


def compute_ytd_perf(db, profile_id: str) -> float:
    jan1 = date(date.today().year, 1, 1)
    trades_ytd = (
        db.query(Trade)
        .filter(Trade.profile_id == profile_id, Trade.effective_date >= jan1)
        .count()
    )
    if trades_ytd == 0:
        return 0.0
    res = backtest_profile(db, profile_id, initial_cash=10000.0)
    return res.pnl_percent

# -----------------------------------------------------------------------------
# App
# -----------------------------------------------------------------------------
app = FastAPI(title="Profile Trades Tracker", version="0.2.0", description="Follows high-profile people and their trades.")

# CORS
if CORS_ALLOW_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=CORS_ALLOW_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# -----------------------------------------------------------------------------
# Routes
# -----------------------------------------------------------------------------
@app.get("/health")
def health():
    return {"ok": True, "app": APP_NAME, "time": datetime.utcnow().isoformat()}

@app.post("/profiles", response_model=ProfileOut)
def create_profile(p: ProfileIn):
    with SessionLocal() as db:
        if db.query(Profile).filter_by(name=p.name).first():
            raise HTTPException(400, "Profile already exists")
        prof = Profile(id=str(uuid.uuid4()), name=p.name, category=p.category, source_url=str(p.source_url) if p.source_url else None)
        db.add(prof)
        db.commit()
        db.refresh(prof)
        return ProfileOut(id=prof.id, name=prof.name, category=prof.category, source_url=prof.source_url, created_at=prof.created_at)

@app.get("/profiles", response_model=List[ProfileOut])
def list_profiles(q: Optional[str] = Query(None, description="Search by name")):
    with SessionLocal() as db:
        qry = db.query(Profile)
        if q:
            qry = qry.filter(Profile.name.ilike(f"%{q}%"))
        rows = qry.order_by(Profile.name.asc()).all()
        return [ProfileOut(id=r.id, name=r.name, category=r.category, source_url=r.source_url, created_at=r.created_at) for r in rows]

@app.post("/trades", response_model=TradeOut)
def add_trade(t: TradeIn):
    with SessionLocal() as db:
        prof = db.query(Profile).filter_by(id=t.profile_id).one_or_none()
        if not prof:
            raise HTTPException(404, "Profile not found")
        sec = get_or_create_security(db, t.ticker)
        tr = Trade(
            id=str(uuid.uuid4()),
            profile_id=prof.id,
            security_id=sec.id,
            direction=t.direction,
            quantity=t.quantity,
            price=t.price,
            filed_at=t.filed_at,
            effective_date=t.effective_date,
            note=t.note
        )
        db.add(tr)
        db.commit()
        db.refresh(tr)
        return TradeOut(
            id=tr.id, profile_id=tr.profile_id, ticker=sec.ticker, direction=tr.direction,
            quantity=tr.quantity, price=tr.price, filed_at=tr.filed_at,
            effective_date=tr.effective_date, note=tr.note
        )

@app.get("/profiles/{profile_id}/trades", response_model=List[TradeOut])
def get_profile_trades(profile_id: str):
    with SessionLocal() as db:
        prof = db.query(Profile).filter_by(id=profile_id).one_or_none()
        if not prof:
            raise HTTPException(404, "Profile not found")
        rows = (
            db.query(Trade).filter_by(profile_id=profile_id).order_by(Trade.filed_at.desc()).all()
        )
        result = []
        for r in rows:
            result.append(TradeOut(
                id=r.id, profile_id=r.profile_id, ticker=r.security.ticker, direction=r.direction,
                quantity=r.quantity, price=r.price, filed_at=r.filed_at, effective_date=r.effective_date, note=r.note
            ))
        return result

@app.get("/leaders/ytd")
def leaders_ytd(top: int = 10):
    with SessionLocal() as db:
        data = []
        for prof in db.query(Profile).all():
            ytd = compute_ytd_perf(db, prof.id)
            data.append({"profile_id": prof.id, "name": prof.name, "category": prof.category, "ytd_pct": round(ytd, 2)})
        data.sort(key=lambda x: x["ytd_pct"], reverse=True)
        return {"leaders": data[:max(1, min(top, 100))]}

@app.post("/subscriptions")
def subscribe(s: SubscriptionIn):
    with SessionLocal() as db:
        sub = Subscription(id=str(uuid.uuid4()), email=s.email, profile_id=s.profile_id, rule=s.rule)
        db.add(sub)
        db.commit()
        return {"ok": True, "subscription_id": sub.id}

@app.post("/portfolios/backtest", response_model=BacktestResult)
def portfolio_backtest(req: PortfolioRequest):
    with SessionLocal() as db:
        prof = db.query(Profile).filter_by(id=req.profile_id).one_or_none()
        if not prof:
            raise HTTPException(404, "Profile not found")
        return backtest_profile(db, req.profile_id, req.initial_cash)

@app.get("/rss/profile/{profile_id}", response_class=PlainTextResponse)
def rss_profile(profile_id: str):
    with SessionLocal() as db:
        prof = db.query(Profile).filter_by(id=profile_id).one_or_none()
        if not prof:
            raise HTTPException(404, "Profile not found")
        items = db.query(Trade).filter_by(profile_id=profile_id).order_by(Trade.filed_at.desc()).limit(50).all()
        now = datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S GMT")
        xml_items = []
        for t in items:
            title = f"{prof.name} {t.direction} {t.quantity} {t.security.ticker} @ {t.price}"
            pub = t.filed_at.strftime("%a, %d %b %Y %H:%M:%S GMT")
            xml_items.append(
                f"""<item>
<title>{title}</title>
<description>{t.note or ''}</description>
<pubDate>{pub}</pubDate>
<guid>{t.id}</guid>
</item>"""
            )
        feed = f"""<?xml version="1.0"?>
<rss version="2.0">
<channel>
<title>Trades for {prof.name}</title>
<link>https://cloudcurio.cc</link>
<description>Latest trades for {prof.name}</description>
<lastBuildDate>{now}</lastBuildDate>
{''.join(xml_items)}
</channel>
</rss>"""
        return feed

# -----------------------------------------------------------------------------
# Admin seed (demo data)
# -----------------------------------------------------------------------------
@app.post("/_admin/seed")
def seed_demo():
    """Seeds sample profiles and trades for testing."""
    with SessionLocal() as db:
        names = [("Jane Doe", "US-Congress"), ("Fund X", "Fund")]
        for n, cat in names:
            if not db.query(Profile).filter_by(name=n).one_or_none():
                p = Profile(id=str(uuid.uuid4()), name=n, category=cat, source_url=None)
                db.add(p)
                db.commit()
        # add trades
        for p in db.query(Profile).all():
            for (ticker, dirn, qty, px, days_ago) in [
                ("AAPL","BUY", 20, 180.0, 200),
                ("MSFT","BUY", 10, 320.0, 170),
                ("MSFT","SELL", 5, 330.0, 120),
                ("NVDA","BUY", 3,  800.0, 90),
                ("AAPL","BUY", 5,  190.0, 30),
            ]:
                sec = get_or_create_security(db, ticker)
                when = datetime.utcnow() - timedelta(days=days_ago)
                tr = Trade(
                    id=str(uuid.uuid4()),
                    profile_id=p.id,
                    security_id=sec.id,
                    direction=dirn,
                    quantity=qty,
                    price=px,
                    filed_at=when,
                    effective_date=(when.date()),
                    note="seed"
                )
                db.add(tr)
        db.commit()
    return {"ok": True}
```

---

## backend/requirements.txt

```text
fastapi==0.112.2
uvicorn[standard]==0.30.6
SQLAlchemy==2.0.34
pydantic==2.9.2
python-multipart==0.0.9
psycopg2-binary==2.9.9
```

> For SQLite-only local dev, `psycopg2-binary` isn’t required.

---

## backend/Dockerfile

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py /app/
EXPOSE 8000

# DB_URL provided by docker-compose env
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## backend/.env.example

```env
# Database
# For Postgres via docker-compose
DB_URL=postgresql+psycopg2://tracker:tracker@db:5432/tracker
# For local dev fallback (comment above, uncomment below)
# DB_URL=sqlite:///./tracker.db

# CORS (comma-separated, e.g., https://cloudcurio.cc,https://app.cloudcurio.cc)
CORS_ORIGINS=

# Logging
LOG_LEVEL=INFO
```

---

## docker-compose.yml

```yaml
version: "3.9"
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: tracker
      POSTGRES_USER: tracker
      POSTGRES_PASSWORD: tracker
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U tracker -d tracker"]
      interval: 10s
      timeout: 5s
      retries: 5

  api:
    build:
      context: ./backend
    environment:
      - DB_URL=postgresql+psycopg2://tracker:tracker@db:5432/tracker
      - CORS_ORIGINS=${CORS_ORIGINS-}
      - LOG_LEVEL=${LOG_LEVEL-INFO}
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8000:8000"
    command: ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]

volumes:
  pgdata:
```

---

## README.md

```markdown
# Profile Trades Tracker (Backend)

Follow high-profile people and list their trades, rank leaders (YTD), generate per-profile RSS, subscribe to alerts, and simulate mirror portfolios.

## Quick Start (Docker)

```bash
git clone <this-repo-url> trades-tracker && cd trades-tracker
# optional: export CORS for your UI domain(s)
export CORS_ORIGINS=https://cloudcurio.cc
docker compose up -d --build
# seed demo data
curl -X POST http://127.0.0.1:8000/_admin/seed
```

Open:
- `GET /profiles` — list profiles
- `GET /leaders/ytd` — top performers
- `GET /rss/profile/{profile_id}` — RSS feed
- `POST /portfolios/backtest` — simulate mirror portfolio

## Local Dev (SQLite)

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export DB_URL=sqlite:///./tracker.db
uvicorn app:app --reload
```

## API Sketch

- `POST /profiles` `{name, category, source_url?}` → profile
- `GET /profiles?q=name` → list
- `POST /trades` `{profile_id, ticker, direction, quantity, price, filed_at, effective_date, note?}` → trade
- `GET /profiles/{id}/trades` → list trades for profile
- `GET /leaders/ytd?top=10` → leaders
- `POST /subscriptions` `{email, profile_id?, rule?}` → subscription id
- `POST /portfolios/backtest` `{profile_id, initial_cash?}` → P&L snapshot
- `GET /rss/profile/{id}` → RSS XML

## Cloudflare Tunnels (Optional)

Expose `api` safely without opening ports:

```bash
cloudflared tunnel run <tunnel-name>
# Map public subdomain like api.cloudcurio.cc → http://api:8000 in CF Zero Trust
```

## Roadmap / Next Steps

1. **Real Data Ingestion**: SEC Form 4 (insiders), 13F (funds), House/Senate disclosures with normalization + dedup + amendments.
2. **Market Data Provider**: Replace toy price model with OHLCV; execution rules (next open/close), slippage, dividends, benchmark vs SPY.
3. **Alerts Delivery**: Worker + provider (email/webhook/Telegram/Push). Add unsubscribe and digest modes.
4. **Auth & RBAC**: JWT/OAuth; rate limiting; per-user watchlists and private alerts.
5. **UI**: Next.js app (Profiles/Trades/Leaders/Alerts/Portfolios) with charts and RSS subscribe buttons.
6. **Backtest Engine**: Vectorized simulation, fractional shares, fees, cash drag; daily performance series.
7. **Compliance**: Prominent disclaimers; timestamps for `filed_at` vs `effective_date`; provenance links.
```

---

### Three immediate improvements you can choose to implement next

1. **Provider adapters**: Create `/ingestors/*` modules with common interface; add a queue for fetch/parse/store.
2. **Portfolio series endpoint**: `GET /portfolios/{id}/timeseries` returning daily equity curve for charts.
3. **RSS cache/edge**: Cloudflare Worker that caches RSS responses and serves quickly at the edge.

