# Formal Elements Analysis

Based on Fullerton, *Game Design Workshop* Ch 3. Updated each design iteration.

Legend: ✅ complete · ⚠️ has gaps · ❌ missing

---

## 1. Players

**Status**: ✅

| Aspect | Current |
|--------|---------|
| Number | Single player |
| Role | Operator (controls paddle) |
| Interaction pattern | Player vs. system |

**Gaps**: Opening experience lacks invitation — menu → start → ball sticks to paddle (player must launch manually).

---

## 2. Objectives

**Status**: ⚠️ (core implemented, star-upgrade link deferred)

**Current**: Clear all bricks = win. Lose all 3 lives = game over.

**Decision (D010)**: Construction (primary) + Forbidden Act (first secondary) + Outwit (later secondary)
- Primary objective: clear bricks (existing) ✅
- First secondary: challenge conditions (primarily combo) + star rating ✅ implemented (D011, D013)
- Second secondary: upgrade selection ✅ implemented (D014) — **but** star rating affecting upgrade choice quantity/quality is still TODO (see roadmap.md v0.1)
- Positive loop: play well → more stars → more upgrades → stronger (partially implemented)

Fullerton's objective types:

- **Capture** — acquire or seize specific items (e.g., hitting key brick triggers power-up)
- **Chase** — pursue a moving target (not very applicable to brick-breaker, player "catches" not "chases")
- **Race** — complete within time limit, or faster than opponent (e.g., time-limited mode)
- **Alignment** — arrange elements into specific patterns (e.g., Tetris, match-3, doesn't fit brick-breaker)
- **Rescue** — save something from danger (unless adding a narrative layer, feels unnatural)
- **Escape** — break free from a predicament (e.g., bricks pressing down, must clear before being crushed)
- **Forbidden Act** — must not do something, doing so means failure (e.g., "clear without losing a ball" as extra challenge)
- **Construction** — achieve goal by placing or removing elements (core of brick-breaker: eliminate all bricks)
- **Exploration** — discover hidden content (e.g., hidden bricks, secret level entrances)
- **Outwit** — win through strategy rather than pure execution (e.g., Roguelike upgrade selection)

**Implemented systems**:
- Combo system ✅ implemented (D011)
- Star rating ✅ implemented (D013)
- Upgrade selection system ✅ implemented (D014), all 5 upgrades complete

---

## 3. Procedures

**Status**: ✅

**Decision (D012)** — all implemented:
1. **Ball sticks to paddle** ✅: ball attaches to paddle and follows, click/Space to launch
2. **Pause** ✅: Esc, on-screen pause button (top-right), or Android back gesture to toggle, minimal UI
3. **Level transition** ✅: 5 levels cycle after each clear (D016); upgrades persist across levels

**Target flow**:
```
Menu → Start → Ball sticks to paddle → Click/Space to launch → Play (combo, bricks)
  → Clear level → Upgrade choice → Advance to next level (loops after 5)
  → Game Over �� Restart/Menu
  Esc → Pause (Resume / Menu)
```

---

## 4. Rules

**Status**: ✅ (basic)

**Current rules**:
- Paddle moves horizontally, stops at walls
- Ball bounces off walls, bricks, paddle
- Paddle hit angle depends on contact position (center = straight up, edges = angled)
- Bricks default to one-hit destroy; hp is configurable per `BrickSpec` (D016), current levels all use hp=1
- 3 lives, lose one only when ALL balls fall below paddle (multi-ball: extra balls don't cost lives)
- Ball speed increases 3% per paddle hit (capped at 550)
- Multi-ball: extra balls don't collide with each other (layer 2, mask 1)
- Pierce: ball exchanges pierce 1:1 with brick hp (dies → pass through; survives → bounce); resets on paddle hit

**Gaps**:
- No dynamic effect rules (e.g. "speed up after N bricks destroyed")
- No special brick types yet (hard, explosive, indestructible, power-up carrier). The `BrickBehavior` infrastructure (D016) is in place but no concrete behaviors are shipped.

---

## 5. Resources

**Status**: ✅

**Current resources**:
| Resource | Status | Notes |
|----------|--------|-------|
| Lives | ✅ | 3, decremented on ball loss |
| Score | ✅ | Scales with combo: `10 * (1 + combo / 5)` |
| Combo | ✅ | D011: +1 per brick hit, reset on paddle hit / ball loss |
| Stars | ✅ | D013: clear = 1★, combo≥10 = 2★, no lives lost = 3★ |
| Upgrade choices | ✅ | D014: 3-choice post-clear, 5/5 implemented (wide/slow/life/multi/pierce) |

**Combo rules (D011)**:
- Ball hits brick → combo += 1
- Ball hits paddle → combo = 0
- Ball hits wall → combo unaffected
- Ball lost → combo = 0

**Design intent**: combo introduces a Dilemma at the catch moment — "risk one more brick vs safe catch"

---

## 6. Conflict

**Status**: ✅

Fullerton's conflict sources: Obstacles / Opponents / Dilemmas.

**Current**:
| Source | Status | Details |
|--------|--------|---------|
| Obstacles | ✅ | Brick layout blocks ball path |
| Opponents | N/A | Single-player, no AI |
| Dilemmas | ✅ | Combo risk/reward (D011) + upgrade choices (D014) |

**Resolved**: Combo creates dilemma ("risk one more brick vs safe catch"); upgrade selection forces strategic trade-offs each round.

---

## 7. Boundaries

**Status**: ✅

**Current**: 480×720 portrait playfield. Left/right/top walls reflect ball. Bottom = ball lost. Paddle constrained to horizontal movement within walls.

No issues identified.

---

## 8. Outcome

**Status**: ✅

**Decision (D013)** — implemented: Star rating
- ⭐ Clear level
- ⭐⭐ Clear level + max combo ≥ 10 (adjust after playtest)
- ⭐⭐⭐ Clear level + no lives lost

---

## Summary: Decision Status

| Element | Status | Decision |
|---------|--------|----------|
| Players | ✅ | No change needed |
| Objectives | ⚠️ | D010: Construction + Forbidden Act → Outwit (core implemented, star-upgrade link TODO) |
| Procedures | ✅ | D012: Ball sticks + pause + level transition (D016) all implemented |
| Rules | ✅ | Combo (D011), multi-ball, pierce rules all implemented |
| Resources | ✅ | D011 combo + D014 upgrades (5/5) all implemented |
| Conflict | ✅ | Solved by D011 (combo dilemma) + D014 (upgrade choices) |
| Boundaries | ✅ | No change needed |
| Outcome | ✅ | D013: 3-star rating implemented |
