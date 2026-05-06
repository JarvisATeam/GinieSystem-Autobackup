#!/usr/bin/env python3
"""
hyperliquid_observation_builder.py
MODUL C — v2.0 (reconstructed from OCR/PDF text)
"""

from __future__ import annotations

import asyncio
import json
import logging
import math
import threading
import time
from collections import deque
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

import numpy as np

try:
    import websockets
    from websockets.exceptions import (
        ConnectionClosedError,
        ConnectionClosedOK,
        WebSocketException,
    )
except Exception:  # pragma: no cover - dependency may be absent in CI
    websockets = None

    class ConnectionClosedError(Exception):
        pass

    class ConnectionClosedOK(Exception):
        pass

    class WebSocketException(Exception):
        pass


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
logger = logging.getLogger("HyperliquidObs")

OBS_VERSION = "C-v2.0"
OBS_DTYPE = np.float32
OBSERVATION_DIM = 105

WS_URL = "wss://api.hyperliquid.exchange/ws"
REST_URL = "https://api.hyperliquid.exchange/info"
MAX_MESSAGES_PER_MINUTE = 2000
MAX_RECONNECT_ATTEMPTS = 5
BASE_RECONNECT_DELAY = 1.0
MAX_RECONNECT_DELAY = 32.0
RING_BUFFER_MAXLEN = 1440
OB_LEVELS = 20
DATA_FRESHNESS_MAX_AGE = 5.0

CAT1_START, CAT1_END = 0, 42
CAT2_START, CAT2_END = 42, 63
CAT3_START, CAT3_END = 63, 94
CAT4_START, CAT4_END = 94, 105


@dataclass
class OrderBookLevel:
    price: float
    size: float


@dataclass
class OrderBook:
    bids: List[OrderBookLevel] = field(default_factory=list)
    asks: List[OrderBookLevel] = field(default_factory=list)
    timestamp: float = 0.0


@dataclass
class AssetContext:
    funding_rate: float = 0.0
    open_interest: float = 0.0
    mark_price: float = 0.0
    timestamp: float = 0.0


@dataclass
class PortfolioState:
    position_size: float = 0.0
    entry_price: float = 0.0
    mark_price: float = 0.0
    unrealized_pnl: float = 0.0
    last_trade_ts: float = 0.0
    account_value: float = 1.0


class RateLimiter:
    def __init__(self, max_per_minute: int = MAX_MESSAGES_PER_MINUTE):
        self._max = max_per_minute
        self._tokens = float(max_per_minute)
        self._last_refill = time.monotonic()
        self._lock = threading.Lock()

    def acquire(self) -> bool:
        with self._lock:
            now = time.monotonic()
            elapsed = now - self._last_refill
            self._tokens = min(float(self._max), self._tokens + elapsed * (self._max / 60.0))
            self._last_refill = now
            if self._tokens >= 1.0:
                self._tokens -= 1.0
                return True
            return False

    def wait_and_acquire(self) -> None:
        while not self.acquire():
            time.sleep(0.01)


class ThreadSafeDeque:
    def __init__(self, maxlen: int = RING_BUFFER_MAXLEN):
        self._deque: deque = deque(maxlen=maxlen)
        self._lock = threading.RLock()

    def append(self, value: Any) -> None:
        with self._lock:
            self._deque.append(value)

    def to_list(self) -> List[Any]:
        with self._lock:
            return list(self._deque)

    def __len__(self) -> int:
        with self._lock:
            return len(self._deque)


def _ema(prices: np.ndarray, period: int) -> np.ndarray:
    if len(prices) == 0:
        return np.zeros(1)
    k = 2.0 / (period + 1)
    result = np.zeros(len(prices))
    result[0] = prices[0]
    for i in range(1, len(prices)):
        result[i] = prices[i] * k + result[i - 1] * (1 - k)
    return result


def compute_rsi(prices: np.ndarray, period: int = 14) -> float:
    if len(prices) < period + 1:
        return 0.0
    deltas = np.diff(prices[-(period + 1) :])
    gains = np.where(deltas > 0, deltas, 0.0)
    losses = np.where(deltas < 0, -deltas, 0.0)
    avg_gain = np.mean(gains) + 1e-9
    avg_loss = np.mean(losses) + 1e-9
    rs = avg_gain / avg_loss
    rsi = 100.0 - (100.0 / (1.0 + rs))
    return float((rsi - 50.0) / 50.0)


def compute_atr(highs: np.ndarray, lows: np.ndarray, closes: np.ndarray, period: int = 14) -> float:
    if len(closes) < period + 1:
        return 0.0
    h = highs[-(period + 1) :]
    l = lows[-(period + 1) :]
    c = closes[-(period + 1) :]
    tr = np.maximum(h[1:] - l[1:], np.maximum(np.abs(h[1:] - c[:-1]), np.abs(l[1:] - c[:-1])))
    atr = np.mean(tr)
    ref = closes[-1] + 1e-9
    return float(np.clip(atr / ref, -3.0, 3.0))


def compute_macd(prices: np.ndarray) -> Tuple[float, float]:
    if len(prices) < 35:
        return 0.0, 0.0
    ema12 = _ema(prices, 12)
    ema26 = _ema(prices, 26)
    macd_line = ema12 - ema26
    signal = _ema(macd_line, 9)
    ref = np.abs(prices[-1]) + 1e-9
    return float(np.clip(macd_line[-1] / ref, -3, 3)), float(np.clip(signal[-1] / ref, -3, 3))


def compute_bollinger(prices: np.ndarray, period: int = 20, std_mult: float = 2.0) -> Tuple[float, float, float]:
    if len(prices) < period:
        return 0.0, 0.0, 0.0
    window = prices[-period:]
    mid = np.mean(window)
    std = np.std(window) + 1e-9
    upper = mid + std_mult * std
    lower = mid - std_mult * std
    last = prices[-1]
    z = (last - mid) / std
    z_upper = (upper - last) / std
    z_lower = (last - lower) / std
    return float(np.clip(z_upper, -3, 3)), float(np.clip(z, -3, 3)), float(np.clip(z_lower, -3, 3))


def compute_turbulence(returns: np.ndarray, lookback: int = 60) -> float:
    if len(returns) < lookback + 1:
        return 0.0
    window = returns[-lookback:]
    mu = np.mean(window)
    sigma = np.std(window) + 1e-9
    last_return = returns[-1]
    z = (last_return - mu) / sigma
    return float(1.0 / (1.0 + np.exp(-np.abs(z))))


def compute_cvd(trades: List[Dict], window_seconds: int) -> float:
    now = time.time()
    cutoff = now - window_seconds
    buy_vol = 0.0
    sell_vol = 0.0
    for t in trades:
        if t.get("ts", 0) < cutoff:
            continue
        sz = float(t.get("size", 0))
        if t.get("side") == "buy":
            buy_vol += sz
        else:
            sell_vol += sz
    total = buy_vol + sell_vol + 1e-9
    return float(np.clip((buy_vol - sell_vol) / total, -1.0, 1.0))


def compute_liquidation_heatmap(liq_events: List[Dict], current_price: float, pct: float = 0.01) -> float:
    if current_price <= 0 or not liq_events:
        return 0.0
    lower = current_price * (1 - pct)
    upper = current_price * (1 + pct)
    count = sum(1 for e in liq_events if lower <= float(e.get("price", 0)) <= upper)
    return float(np.clip(count / (len(liq_events) + 1e-9), 0.0, 1.0))


class HyperliquidObservationBuilder:
    def __init__(self, coin: str = "BTC", portfolio_state: Optional[PortfolioState] = None, max_position: float = 1.0):
        self.coin = coin
        self.max_position = max(max_position, 1e-9)
        self.obs_version = OBS_VERSION

        self._portfolio_lock = threading.RLock()
        self._portfolio = portfolio_state or PortfolioState()
        self._peak_value = max((portfolio_state.account_value if portfolio_state else 1.0), 1e-9)

        self._price_buf = ThreadSafeDeque(RING_BUFFER_MAXLEN)
        self._high_buf = ThreadSafeDeque(RING_BUFFER_MAXLEN)
        self._low_buf = ThreadSafeDeque(RING_BUFFER_MAXLEN)
        self._trade_buf = ThreadSafeDeque(RING_BUFFER_MAXLEN)
        self._liq_buf = ThreadSafeDeque(RING_BUFFER_MAXLEN)
        self._funding_buf = ThreadSafeDeque(1440)
        self._oi_buf = ThreadSafeDeque(1440)
        self._ls_ratio_buf = ThreadSafeDeque(1440)

        self._ob_lock = threading.RLock()
        self._orderbook = OrderBook()
        self._asset_ctx_lock = threading.RLock()
        self._asset_ctx = AssetContext()
        self._mids_lock = threading.RLock()
        self._all_mids: Dict[str, float] = {}

        # [0]=orderbook, [1]=funding/OI, [2]=OHLC proxy/live, [3]=trades
        self._quality_flags = np.zeros(4, dtype=np.float32)

        self._last_update_ts = 0.0
        self._freshness_lock = threading.Lock()

        self._rate_limiter = RateLimiter(MAX_MESSAGES_PER_MINUTE)
        self._loop: Optional[asyncio.AbstractEventLoop] = None
        self._running = threading.Event()
        self._connected = threading.Event()

        logger.info("HyperliquidObservationBuilder v2.0 init: %s, max_pos=%s", coin, self.max_position)

    @property
    def last_update_ts(self) -> float:
        with self._freshness_lock:
            return self._last_update_ts

    @property
    def is_connected(self) -> bool:
        return self._connected.is_set()

    def is_data_fresh(self, max_age_seconds: float = DATA_FRESHNESS_MAX_AGE) -> bool:
        with self._freshness_lock:
            if self._last_update_ts == 0.0:
                return False
            return (time.time() - self._last_update_ts) < max_age_seconds

    def start(self) -> None:
        if websockets is None:
            raise RuntimeError("websockets dependency is unavailable")
        if self._running.is_set():
            logger.warning("Allerede kjørende")
            return
        self._running.set()
        threading.Thread(target=self._run_event_loop, daemon=True, name="HLiqWS").start()
        logger.info("WS bakgrunnstråd startet")

    def stop(self) -> None:
        self._running.clear()
        if self._loop and self._loop.is_running():
            self._loop.call_soon_threadsafe(self._loop.stop)
        logger.info("Stopp-signal sendt")

    def update_portfolio(self, state: PortfolioState) -> None:
        with self._portfolio_lock:
            self._portfolio = state
            if state.account_value > self._peak_value:
                self._peak_value = state.account_value

    def set_max_position(self, max_pos: float) -> None:
        self.max_position = max(max_pos, 1e-9)
        logger.info("max_position oppdatert: %s", self.max_position)

    def build_observation(self) -> np.ndarray:
        obs = np.zeros(OBSERVATION_DIM, dtype=OBS_DTYPE)
        obs[CAT1_START:CAT1_END] = self._build_category1()
        obs[CAT2_START:CAT2_END] = self._build_category2()
        obs[CAT3_START:CAT3_END] = self._build_category3()
        obs[CAT4_START:CAT4_END] = self._build_category4()
        obs = np.where(np.isfinite(obs), obs, 0.0).astype(OBS_DTYPE)
        logger.debug("[%s] obs built, fresh=%s, quality=%s", OBS_VERSION, self.is_data_fresh(), self._quality_flags.tolist())
        assert obs.shape == (OBSERVATION_DIM,)
        return obs

    def get_obs_quality_flags(self) -> np.ndarray:
        return self._quality_flags.copy()

    def get_current_mid(self) -> float:
        prices = self._price_buf.to_list()
        return float(prices[-1]) if prices else 0.0

    def get_observation_labels(self) -> List[str]:
        labels: List[str] = []
        labels += ["ob_imb_5", "ob_imb_10", "spread_norm", "mid_return_1t"]
        labels += [f"cvd_{m}m" for m in [1, 5, 15]]
        labels += [f"liq_hm_{p}pct" for p in [1, 2, 5]]
        for i in range(10):
            labels += [f"bid_dist_{i}", f"bid_sz_{i}"]
        labels += [f"bid_sz_top{i}" for i in range(5)]
        labels += [f"ask_sz_top{i}" for i in range(5)]
        labels += ["vwmp_z", "microprice_z"]
        labels += ["fr_now", "fr_twap", "fr_skew"]
        labels += ["oi_d_1h", "oi_d_4h", "oi_d_24h"]
        labels += ["ls_ratio", "oi_log", "fr_sign"]
        labels += [f"fr_hist_{i}" for i in range(12)]
        labels += ["rsi14", "atr14", "macd", "macd_sig"]
        labels += ["bb_upper_z", "bb_mid_z", "bb_lower_z", "turbulence"]
        labels += [f"log_ret_{i}" for i in range(7)]
        labels += [f"roll_std_{w}" for w in [5, 10, 20, 50, 100, 200, 500]]
        labels += [f"mom_{p}" for p in [5, 10, 20, 50, 100, 200, 500]]
        labels += ["slope_ema12", "slope_ema26"]
        labels += ["pos_norm", "upnl_pct", "time_since_trade"]
        labels += ["sin_dow", "cos_dow", "sin_hod", "cos_hod"]
        labels += ["leverage_util", "drawdown", "pos_abs_log", "in_position"]
        assert len(labels) == OBSERVATION_DIM, f"Label-mismatch: {len(labels)} != {OBSERVATION_DIM}"
        return labels

    def _build_category1(self) -> np.ndarray:
        feat = np.zeros(42, dtype=np.float32)
        with self._ob_lock:
            ob = self._orderbook

        bids = ob.bids[:20]
        asks = ob.asks[:20]
        if not bids or not asks:
            return feat

        best_bid = bids[0].price
        best_ask = asks[0].price
        mid = (best_bid + best_ask) / 2.0
        spread = (best_ask - best_bid) / (mid + 1e-9)

        bid5_vol = sum(b.size for b in bids[:5])
        ask5_vol = sum(a.size for a in asks[:5])
        total5 = bid5_vol + ask5_vol + 1e-9
        feat[0] = float(np.clip((bid5_vol - ask5_vol) / total5, -1, 1))

        bid10_vol = sum(b.size for b in bids[:10])
        ask10_vol = sum(a.size for a in asks[:10])
        total10 = bid10_vol + ask10_vol + 1e-9
        feat[1] = float(np.clip((bid10_vol - ask10_vol) / total10, -1, 1))
        feat[2] = float(np.clip(spread / 0.01, 0.0, 1.0))

        prices = self._price_buf.to_list()
        if len(prices) >= 2:
            feat[3] = float(np.clip(math.log(prices[-1] / (prices[-2] + 1e-9)) * 100, -3, 3))

        trades = self._trade_buf.to_list()
        feat[4] = compute_cvd(trades, 60)
        feat[5] = compute_cvd(trades, 300)
        feat[6] = compute_cvd(trades, 900)

        liqs = self._liq_buf.to_list()
        feat[7] = compute_liquidation_heatmap(liqs, mid, 0.01)
        feat[8] = compute_liquidation_heatmap(liqs, mid, 0.02)
        feat[9] = compute_liquidation_heatmap(liqs, mid, 0.05)

        idx = 10
        for i in range(min(10, len(bids))):
            price_dist = abs(bids[i].price - mid) / (mid + 1e-9)
            size_norm = math.log1p(bids[i].size) / 10.0
            feat[idx] = float(np.clip(price_dist / 0.01, 0, 3))
            feat[idx + 1] = float(np.clip(size_norm, 0, 3))
            idx += 2

        idx = 30
        for i in range(min(5, len(bids))):
            feat[idx] = float(np.clip(math.log1p(bids[i].size) / 10.0, 0, 3))
            idx += 1
        for i in range(min(5, len(asks))):
            feat[idx] = float(np.clip(math.log1p(asks[i].size) / 10.0, 0, 3))
            idx += 1

        bid_vol = bids[0].size if bids else 0
        ask_vol = asks[0].size if asks else 0
        total_vol = bid_vol + ask_vol + 1e-9
        vwmp = (best_bid * ask_vol + best_ask * bid_vol) / total_vol
        feat[40] = float(np.clip((vwmp - mid) / (spread * mid + 1e-9), -3, 3))
        microprice = mid + (bid5_vol - ask5_vol) / total5 * spread / 2
        feat[41] = float(np.clip((microprice - mid) / (spread * mid + 1e-9), -3, 3))
        return feat

    def _build_category2(self) -> np.ndarray:
        feat = np.zeros(21, dtype=np.float32)
        with self._asset_ctx_lock:
            ctx = self._asset_ctx

        funding_hist = self._funding_buf.to_list()
        oi_hist = self._oi_buf.to_list()
        ls_hist = self._ls_ratio_buf.to_list()

        fr_now = ctx.funding_rate
        feat[0] = float(np.clip(fr_now * 3 * 365 * 10, -3, 3))

        if len(funding_hist) >= 8:
            twap = np.mean(funding_hist[-8:])
            feat[1] = float(np.clip(twap * 3 * 365 * 10, -3, 3))
        else:
            feat[1] = feat[0]

        feat[2] = float(np.clip(feat[0] - feat[1], -3, 3))

        oi_now = ctx.open_interest
        for i, n_ticks in enumerate([60, 240, 1440]):
            if len(oi_hist) >= n_ticks:
                oi_ref = oi_hist[-n_ticks]
                feat[3 + i] = float(np.clip((oi_now - oi_ref) / (oi_ref + 1e-9), -3, 3))

        if ls_hist:
            feat[6] = float(np.clip((ls_hist[-1] - 1.0) / 2.0, -1, 1))

        if oi_now > 0:
            feat[7] = float(np.clip(math.log10(oi_now + 1) / 10.0, 0, 3))

        feat[8] = float(np.sign(fr_now))

        hist_slice = funding_hist[-12:]
        for i, fr in enumerate(hist_slice):
            feat[9 + i] = float(np.clip(fr * 3 * 365 * 10, -3, 3))
        return feat

    def _build_category3(self) -> np.ndarray:
        feat = np.zeros(31, dtype=np.float32)
        prices = np.array(self._price_buf.to_list(), dtype=np.float64)
        highs = np.array(self._high_buf.to_list(), dtype=np.float64)
        lows = np.array(self._low_buf.to_list(), dtype=np.float64)
        if len(prices) < 2:
            return feat

        min_len = min(len(prices), len(highs), len(lows))
        prices = prices[-min_len:]
        highs = highs[-min_len:]
        lows = lows[-min_len:]
        log_returns = np.diff(np.log(prices + 1e-9))

        feat[0] = compute_rsi(prices, 14)
        if min_len >= 15:
            feat[1] = compute_atr(highs, lows, prices, 14)

        macd_line, signal_line = compute_macd(prices)
        feat[2] = macd_line
        feat[3] = signal_line

        if len(prices) >= 20:
            feat[4], feat[5], feat[6] = compute_bollinger(prices, 20, 2.0)

        if len(log_returns) >= 60:
            feat[7] = compute_turbulence(log_returns, 60)

        for i, lr in enumerate(log_returns[-7:]):
            feat[8 + i] = float(np.clip(lr * 100, -10, 10))

        windows = [5, 10, 20, 50, 100, 200, 500]
        for i, w in enumerate(windows):
            if len(log_returns) >= w:
                feat[15 + i] = float(np.clip(np.std(log_returns[-w:]) * 100, 0, 10))

        sma_periods = [5, 10, 20, 50, 100, 200, 500]
        last_price = prices[-1] + 1e-9
        for i, p in enumerate(sma_periods):
            if len(prices) >= p:
                sma = np.mean(prices[-p:])
                feat[22 + i] = float(np.clip((last_price / (sma + 1e-9)) - 1, -3, 3))

        if len(prices) >= 26:
            ema12 = _ema(prices, 12)
            ema26 = _ema(prices, 26)
            slope12 = (ema12[-1] - ema12[-2]) / last_price if len(ema12) >= 2 else 0
            slope26 = (ema26[-1] - ema26[-2]) / last_price if len(ema26) >= 2 else 0
            feat[29] = float(np.clip(slope12 * 100, -3, 3))
            feat[30] = float(np.clip(slope26 * 100, -3, 3))
        return feat

    def _build_category4(self) -> np.ndarray:
        feat = np.zeros(11, dtype=np.float32)
        with self._portfolio_lock:
            p = self._portfolio
            peak = self._peak_value

        feat[0] = float(np.clip(p.position_size / (self.max_position + 1e-9), -1, 1))

        if p.entry_price > 0 and p.mark_price > 0:
            pnl_pct = (p.mark_price - p.entry_price) / p.entry_price
            if p.position_size < 0:
                pnl_pct = -pnl_pct
            feat[1] = float(np.clip(pnl_pct * 10, -3, 3))

        now = time.time()
        if p.last_trade_ts > 0:
            secs = now - p.last_trade_ts
            feat[2] = float(np.clip(math.log1p(secs) / math.log1p(86400), 0, 1))

        dt_utc = datetime.now(timezone.utc)
        dow = dt_utc.weekday()
        hour_frac = dt_utc.hour / 24.0
        feat[3] = float(math.sin(2 * math.pi * dow / 7))
        feat[4] = float(math.cos(2 * math.pi * dow / 7))
        feat[5] = float(math.sin(2 * math.pi * hour_frac))
        feat[6] = float(math.cos(2 * math.pi * hour_frac))

        if p.account_value > 0 and p.mark_price > 0:
            notional = abs(p.position_size) * p.mark_price
            leverage = notional / (p.account_value + 1e-9)
            feat[7] = float(np.clip(leverage / 10.0, 0, 1))

        if peak > 0 and p.account_value > 0:
            drawdown = (peak - p.account_value) / peak
            feat[8] = float(np.clip(drawdown, 0, 1))

        feat[9] = float(np.clip(math.log1p(abs(p.position_size)), 0, 5))
        feat[10] = float(1.0 if abs(p.position_size) > 1e-8 else 0.0)
        return feat

    def _run_event_loop(self) -> None:
        self._loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self._loop)
        try:
            self._loop.run_until_complete(self._ws_reconnect_loop())
        except Exception as exc:
            logger.error("Event-loop krasjet: %s", exc)
        finally:
            self._loop.close()

    async def _ws_reconnect_loop(self) -> None:
        attempt = 0
        delay = BASE_RECONNECT_DELAY
        while self._running.is_set():
            try:
                logger.info("WS tilkoblingsattempt %s/%s", attempt + 1, MAX_RECONNECT_ATTEMPTS)
                await self._ws_connect_and_listen()
                attempt = 0
                delay = BASE_RECONNECT_DELAY
            except (ConnectionClosedError, ConnectionClosedOK) as exc:
                logger.warning("WS koblet fra: %s", exc)
            except WebSocketException as exc:
                logger.error("WS feil: %s", exc)
            except Exception as exc:
                logger.error("Uventet feil: %s", exc, exc_info=True)
            finally:
                self._connected.clear()

            if not self._running.is_set():
                break
            attempt += 1
            if attempt >= MAX_RECONNECT_ATTEMPTS:
                logger.error("Maks reconnect-forsøk nådd. Gir opp.")
                self._running.clear()
                break
            logger.info("Reconnect om %.1fs ...", delay)
            await asyncio.sleep(delay)
            delay = min(delay * 2, MAX_RECONNECT_DELAY)

    async def _ws_connect_and_listen(self) -> None:
        if websockets is None:
            raise RuntimeError("websockets dependency is unavailable")
        async with websockets.connect(
            WS_URL,
            ping_interval=20,
            ping_timeout=30,
            close_timeout=10,
            max_size=10 * 1024 * 1024,
        ) as ws:
            logger.info("WS tilkoblet: %s", WS_URL)
            self._connected.set()
            await self._subscribe(ws)
            async for raw in ws:
                if not self._running.is_set():
                    break
                self._rate_limiter.wait_and_acquire()
                self._process_message(raw)
                with self._freshness_lock:
                    self._last_update_ts = time.time()

    async def _subscribe(self, ws) -> None:
        # Decision: include trades/liquidations since _process_message handles them.
        subs = [
            {"method": "subscribe", "subscription": {"type": "l2Book", "coin": self.coin}},
            {"method": "subscribe", "subscription": {"type": "activeAssetCtx", "coin": self.coin}},
            {"method": "subscribe", "subscription": {"type": "allMids"}},
            {"method": "subscribe", "subscription": {"type": "trades", "coin": self.coin}},
            {"method": "subscribe", "subscription": {"type": "liquidations", "coin": self.coin}},
        ]
        for sub in subs:
            await ws.send(json.dumps(sub))
            logger.debug("Abonnert: %s", sub["subscription"]["type"])
            await asyncio.sleep(0.05)

    def _process_message(self, raw: str) -> None:
        try:
            msg = json.loads(raw)
        except json.JSONDecodeError as exc:
            logger.warning("JSON parse-feil: %s", exc)
            return
        channel = msg.get("channel", "")
        data = msg.get("data", {})
        if channel == "l2Book":
            self._handle_l2book(data)
        elif channel == "activeAssetCtx":
            self._handle_asset_ctx(data)
        elif channel == "allMids":
            self._handle_all_mids(data)
        elif channel == "trades":
            self._handle_trades(data)
        elif channel == "liquidations":
            self._handle_liquidations(data)

    def _handle_l2book(self, data: Dict) -> None:
        try:
            levels = data.get("levels", [[], []])
            bids = [OrderBookLevel(float(l[0]), float(l[1])) for l in levels[0][:OB_LEVELS] if len(l) >= 2]
            asks = [OrderBookLevel(float(l[0]), float(l[1])) for l in levels[1][:OB_LEVELS] if len(l) >= 2]
            ts = float(data.get("time", time.time()))
            with self._ob_lock:
                self._orderbook = OrderBook(bids=bids, asks=asks, timestamp=ts)
            self._quality_flags[0] = 1.0
            if bids and asks:
                mid = (bids[0].price + asks[0].price) / 2.0
                self._price_buf.append(mid)
                self._high_buf.append(asks[0].price)
                self._low_buf.append(bids[0].price)
                self._quality_flags[2] = 1.0
        except Exception as exc:
            logger.warning("l2book feil: %s", exc)

    def _handle_asset_ctx(self, data: Dict) -> None:
        try:
            ctx = data.get("ctx", data)
            fr = float(ctx.get("funding", 0.0))
            oi = float(ctx.get("openInterest", 0.0))
            mk = float(ctx.get("markPx", 0.0))
            with self._asset_ctx_lock:
                self._asset_ctx = AssetContext(funding_rate=fr, open_interest=oi, mark_price=mk, timestamp=time.time())
            self._funding_buf.append(fr)
            self._oi_buf.append(oi)
            self._quality_flags[1] = 1.0
        except Exception as exc:
            logger.warning("asset ctx feil: %s", exc)

    def _handle_all_mids(self, data: Dict) -> None:
        try:
            with self._mids_lock:
                if isinstance(data, dict):
                    self._all_mids = {k: float(v) for k, v in data.items()}
                else:
                    self._all_mids = {}
            mid = self._all_mids.get(self.coin)
            if mid and mid > 0:
                self._price_buf.append(mid)
        except Exception as exc:
            logger.warning("allMids feil: %s", exc)

    def _handle_trades(self, data: Any) -> None:
        try:
            events = data if isinstance(data, list) else [data]
            now = time.time()
            for t in events:
                if not isinstance(t, dict):
                    continue
                px = float(t.get("px", t.get("price", 0.0)) or 0.0)
                sz = float(t.get("sz", t.get("size", 0.0)) or 0.0)
                side = t.get("side", "buy")
                ts = float(t.get("time", t.get("ts", now)))
                self._trade_buf.append({"price": px, "size": sz, "side": side, "ts": ts})
                if px > 0:
                    self._price_buf.append(px)
            self._quality_flags[3] = 1.0
        except Exception as exc:
            logger.warning("trades feil: %s", exc)

    def _handle_liquidations(self, data: Any) -> None:
        try:
            events = data if isinstance(data, list) else [data]
            now = time.time()
            for e in events:
                if not isinstance(e, dict):
                    continue
                price = float(e.get("px", e.get("price", 0.0)) or 0.0)
                ts = float(e.get("time", e.get("ts", now)))
                side = e.get("side", "unknown")
                self._liq_buf.append({"price": price, "side": side, "ts": ts})
        except Exception as exc:
            logger.warning("liquidations feil: %s", exc)


__all__ = [
    "OBS_VERSION",
    "OBS_DTYPE",
    "OBSERVATION_DIM",
    "WS_URL",
    "REST_URL",
    "OrderBookLevel",
    "OrderBook",
    "AssetContext",
    "PortfolioState",
    "HyperliquidObservationBuilder",
]
