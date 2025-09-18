#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script: app.py
Author: CBW + GPT-5 Thinking
Date: 2025-09-18
Summary:
  FastAPI backend for "Profile Trades Tracker" with improvements:
  - JWT auth (register/login)
  - Watchlists per user
  - Leaders YTD
  - Paper-portfolio backtest + time-series endpoint
  - Per-profile RSS
  - Subscriptions (storage)
Inputs: HTTP requests
Outputs: JSON API + RSS XML
Security:
  - Pydantic validation
  - CORS allowlist via env CORS_ORIGINS
  - JWT secret via env JWT_SECRET (dev default fallback)
"""

from __future__ import annotations
from datetime import datetime, timedelta, date
from typing import List, Optional, Dict, Literal
import math
import os
import uuid
import logging
import hashlib

from fastapi import FastAPI, HTTPException, Query, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel, Field, HttpUrl
from sqlalchemy import (
    create_engine, Column, String, DateTime, Float, Integer, ForeignKey, Text, Date, Boolean, UniqueConstraint
)
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
from sqlalchemy.sql import func
import jwt

# -----------------------------------------------------------------------------
# Config & Logging
# -----------------------------------------------------------------------------
APP_NAME = "profile-trades-tracker"
DB_URL = os.getenv("DB_URL", "sqlite:///./tracker.db")
CORS_ALLOW_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-change-me")
JWT_ALG = "HS256"
TOKEN_TTL_MIN = int(os.getenv("TOKEN_TTL_MIN", "1440"))  # 24h

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

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True)
    email = Column(String, unique=True, index=True)
    password_hash = Column(String)
    created_at = Column(DateTime, server_default=func.now())

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
    quantity = Column(Float)    # normalized shares
    price = Column(Float)       # assumed fill price (for backtests)
    filed_at = Column(DateTime) # public disclosure time
    effective_date = Column(Date)  # when trade occurred (if known/estimated)
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
    mirror_mode = Column(Boolean, default=True)  # mirror trades

class Subscription(Base):
    __tablename__ = "subscriptions"
    id = Column(String, primary_key=True)
    email = Column(String, index=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=True)
    rule = Column(String, nullable=True)  # e.g., "new_trade", "rank_change"
    created_at = Column(DateTime, server_default=func.now())

class Watchlist(Base):
    __tablename__ = "watchlists"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"))
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"))
    created_at = Column(DateTime, server_default=func.now())
    __table_args__ = (UniqueConstraint('user_id','profile_id', name='_user_profile_uc'),)

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

class BacktestSeries(BaseModel):
    dates: List[str]
    equity: List[float]

class RegisterIn(BaseModel):
    email: str
    password: str

class LoginIn(BaseModel):
    email: str
    password: str

class TokenOut(BaseModel):
    token: str
    expires_at: str

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def hash_password(pw: str) -> str:
    # simple SHA256 for demo; swap to passlib+bcrypt in production
    return hashlib.sha256(pw.encode("utf-8")).hexdigest()

def verify_password(pw: str, hashed: str) -> bool:
    return hash_password(pw) == hashed

def make_token(user_id: str) -> str:
    exp = datetime.utcnow() + timedelta(minutes=TOKEN_TTL_MIN)
    payload = {"sub": user_id, "exp": exp}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALG)

def parse_token(token: str) -> Optional[str]:
    try:
        data = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALG])
        return data.get("sub")
    except Exception:
        return None

def auth_user(token: Optional[str]) -> Optional[str]:
    if not token:
        return None
    if token.lower().startswith("bearer "):
        token = token.split(" ",1)[1]
    return parse_token(token)

def get_or_create_security(db, ticker: str):
    from sqlalchemy import select
    t = ticker.upper()
    sec = db.execute(select(Security).where(Security.ticker==t)).scalars().one_or_none()
    if sec: return sec
    sec = Security(id=str(uuid.uuid4()), ticker=t, name=None)
    db.add(sec); db.commit(); db.refresh(sec); return sec

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
    from sqlalchemy import select
    trades = db.execute(select(Trade).where(Trade.profile_id==profile_id).order_by(Trade.filed_at.asc())).scalars().all()
    if not trades:
        return BacktestResult(portfolio_value=initial_cash, cash=initial_cash, positions={}, pnl_percent=0.0, trades_executed=0)
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
        if qty <= 0: continue
        series = simple_price_series(ticker, start, end)
        if not series: continue
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

def backtest_series(db, profile_id: str, initial_cash: float = 10000.0) -> BacktestSeries:
    """Very simple daily equity curve using toy prices and naive fills on effective_date."""
    from sqlalchemy import select
    trades = db.execute(select(Trade).where(Trade.profile_id==profile_id).order_by(Trade.filed_at.asc())).scalars().all()
    if not trades:
        return BacktestSeries(dates=[], equity=[])
    start = min(t.effective_date for t in trades)
    end = date.today()
    # Precompute price series per ticker
    tickers = sorted({t.security.ticker for t in trades})
    series_map = {tic: simple_price_series(tic, start, end) for tic in tickers}
    equity_curve = []
    dates = sorted({d for s in series_map.values() for d in s.keys()})
    cash = initial_cash
    positions: Dict[str, float] = {}
    for d in dates:
        # execute trades effective today
        todays = [t for t in trades if t.effective_date == d]
        for t in todays:
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
        # mark-to-market
        m2m = 0.0
        for tic, qty in positions.items():
            if qty <= 0: continue
            px = series_map[tic].get(d)
            if px is not None:
                m2m += qty * px
        equity_curve.append(cash + m2m)
    return BacktestSeries(dates=[d.isoformat() for d in dates], equity=[round(v,2) for v in equity_curve])

def compute_ytd_perf(db, profile_id: str) -> float:
    from sqlalchemy import select
    jan1 = date(date.today().year, 1, 1)
    trades_ytd = db.execute(select(Trade).where(Trade.profile_id==profile_id, Trade.effective_date >= jan1)).scalars().all()
    if not trades_ytd:
        return 0.0
    res = backtest_profile(db, profile_id, initial_cash=10000.0)
    return res.pnl_percent

# -----------------------------------------------------------------------------
# App
# -----------------------------------------------------------------------------
app = FastAPI(title="Profile Trades Tracker", version="0.3.0", description="Follows high-profile people and their trades.")

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

# --- Auth ---
@app.post("/auth/register", response_model=TokenOut)
def register(body: RegisterIn):
    with SessionLocal() as db:
        if db.query(User).filter_by(email=body.email.lower()).first():
            raise HTTPException(400, "User exists")
        u = User(id=str(uuid.uuid4()), email=body.email.lower(), password_hash=hash_password(body.password))
        db.add(u); db.commit()
        token = make_token(u.id)
        exp = (datetime.utcnow() + timedelta(minutes=TOKEN_TTL_MIN)).isoformat()
        return TokenOut(token=token, expires_at=exp)

@app.post("/auth/login", response_model=TokenOut)
def login(body: LoginIn):
    with SessionLocal() as db:
        u = db.query(User).filter_by(email=body.email.lower()).first()
        if not u or not verify_password(body.password, u.password_hash):
            raise HTTPException(401, "Invalid credentials")
        token = make_token(u.id)
        exp = (datetime.utcnow() + timedelta(minutes=TOKEN_TTL_MIN)).isoformat()
        return TokenOut(token=token, expires_at=exp)

# --- Profiles / Trades ---
@app.post("/profiles", response_model=ProfileOut)
def create_profile(p: ProfileIn):
    with SessionLocal() as db:
        if db.query(Profile).filter_by(name=p.name).first():
            raise HTTPException(400, "Profile already exists")
        prof = Profile(id=str(uuid.uuid4()), name=p.name, category=p.category, source_url=str(p.source_url) if p.source_url else None)
        db.add(prof); db.commit(); db.refresh(prof)
        return ProfileOut(id=prof.id, name=prof.name, category=prof.category, source_url=prof.source_url, created_at=prof.created_at)

@app.get("/profiles", response_model=List[ProfileOut])
def list_profiles(q: Optional[str] = Query(None, description="Search by name")):
    with SessionLocal() as db:
        qry = db.query(Profile)
        if q: qry = qry.filter(Profile.name.ilike(f"%{q}%"))
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
            id=str(uuid.uuid4()), profile_id=prof.id, security_id=sec.id,
            direction=t.direction, quantity=t.quantity, price=t.price,
            filed_at=t.filed_at, effective_date=t.effective_date, note=t.note
        )
        db.add(tr); db.commit(); db.refresh(tr)
        return TradeOut(id=tr.id, profile_id=tr.profile_id, ticker=sec.ticker, direction=tr.direction,
                        quantity=tr.quantity, price=tr.price, filed_at=tr.filed_at,
                        effective_date=tr.effective_date, note=tr.note)

@app.get("/profiles/{profile_id}/trades", response_model=List[TradeOut])
def get_profile_trades(profile_id: str):
    with SessionLocal() as db:
        prof = db.query(Profile).filter_by(id=profile_id).one_or_none()
        if not prof: raise HTTPException(404, "Profile not found")
        rows = db.query(Trade).filter_by(profile_id=profile_id).order_by(Trade.filed_at.desc()).all()
        result = []
        for r in rows:
            result.append(TradeOut(
                id=r.id, profile_id=r.profile_id, ticker=r.security.ticker, direction=r.direction,
                quantity=r.quantity, price=r.price, filed_at=r.filed_at, effective_date=r.effective_date, note=r.note
            ))
        return result

# --- Leaders ---
@app.get("/leaders/ytd")
def leaders_ytd(top: int = 10):
    with SessionLocal() as db:
        data = []
        for prof in db.query(Profile).all():
            ytd = compute_ytd_perf(db, prof.id)
            data.append({"profile_id": prof.id, "name": prof.name, "category": prof.category, "ytd_pct": round(ytd, 2)})
        data.sort(key=lambda x: x["ytd_pct"], reverse=True)
        return {"leaders": data[:max(1, min(top, 100))]}

# --- Alerts ---
@app.post("/subscriptions")
def subscribe(s: SubscriptionIn):
    with SessionLocal() as db:
        sub = Subscription(id=str(uuid.uuid4()), email=s.email, profile_id=s.profile_id, rule=s.rule)
        db.add(sub); db.commit()
        return {"ok": True, "subscription_id": sub.id}

# --- Portfolios ---
@app.post("/portfolios/backtest", response_model=BacktestResult)
def portfolio_backtest(req: PortfolioRequest):
    with SessionLocal() as db:
        prof = db.query(Profile).filter_by(id=req.profile_id).one_or_none()
        if not prof: raise HTTPException(404, "Profile not found")
        return backtest_profile(db, req.profile_id, req.initial_cash)

@app.post("/portfolios/backtest_series", response_model=BacktestSeries)
def portfolio_backtest_series(req: PortfolioRequest):
    with SessionLocal() as db:
        prof = db.query(Profile).filter_by(id=req.profile_id).one_or_none()
        if not prof: raise HTTPException(404, "Profile not found")
        return backtest_series(db, req.profile_id, req.initial_cash)

# --- Watchlists ---
class WatchlistIn(BaseModel):
    profile_id: str
class WatchlistOut(BaseModel):
    profile_id: str
    name: str
    category: str

@app.get("/watchlist", response_model=List[WatchlistOut])
def list_watchlist(authorization: Optional[str] = None):
    user_id = auth_user(authorization or "")
    if not user_id: raise HTTPException(401, "Unauthorized")
    with SessionLocal() as db:
        rows = db.query(Watchlist, Profile).join(Profile, Watchlist.profile_id==Profile.id).filter(Watchlist.user_id==user_id).all()
        return [WatchlistOut(profile_id=p.id, name=p.name, category=p.category) for _, p in rows]

@app.post("/watchlist", response_model=WatchlistOut)
def add_watchlist(item: WatchlistIn, authorization: Optional[str] = None):
    user_id = auth_user(authorization or "")
    if not user_id: raise HTTPException(401, "Unauthorized")
    with SessionLocal() as db:
        prof = db.query(Profile).filter_by(id=item.profile_id).one_or_none()
        if not prof: raise HTTPException(404, "Profile not found")
        if db.query(Watchlist).filter_by(user_id=user_id, profile_id=item.profile_id).first():
            return WatchlistOut(profile_id=prof.id, name=prof.name, category=prof.category)
        w = Watchlist(id=str(uuid.uuid4()), user_id=user_id, profile_id=item.profile_id)
        db.add(w); db.commit()
        return WatchlistOut(profile_id=prof.id, name=prof.name, category=prof.category)

# --- RSS ---
@app.get("/rss/profile/{profile_id}", response_class=PlainTextResponse)
def rss_profile(profile_id: str):
    with SessionLocal() as db:
        prof = db.query(Profile).filter_by(id=profile_id).one_or_none()
        if not prof: raise HTTPException(404, "Profile not found")
        items = db.query(Trade).filter_by(profile_id=profile_id).order_by(Trade.filed_at.desc()).limit(50).all()
        now = datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S GMT")
        xml_items = []
        for t in items:
            title = f"{prof.name} {t.direction} {t.quantity} {t.security.ticker} @ {t.price}"
            pub = t.filed_at.strftime("%a, %d %b %Y %H:%M:%S GMT")
            xml_items.append(f"<item><title>{title}</title><description>{t.note or ''}</description><pubDate>{pub}</pubDate><guid>{t.id}</guid></item>")
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

# --- Admin seed ---
@app.post("/_admin/seed")
def seed_demo():
    with SessionLocal() as db:
        names = [("Jane Doe", "US-Congress"), ("Fund X", "Fund")]
        for n, cat in names:
            if not db.query(Profile).filter_by(name=n).one_or_none():
                p = Profile(id=str(uuid.uuid4()), name=n, category=cat, source_url=None)
                db.add(p); db.commit()
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
                    id=str(uuid.uuid4()), profile_id=p.id, security_id=sec.id, direction=dirn, quantity=qty,
                    price=px, filed_at=when, effective_date=(when.date()), note="seed"
                )
                db.add(tr)
        db.commit()
    return {"ok": True}
