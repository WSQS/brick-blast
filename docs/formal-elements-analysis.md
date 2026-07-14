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

**Gaps**: Opening experience lacks invitation — menu → start → ball auto-launches with no "are you ready?" moment.

---

## 2. Objectives

**Status**: ⚠️

**Current**: Clear all bricks = win. Lose all 3 lives = game over.

Fullerton's objective types: Capture / Chase / Race / Alignment / Rescue / Escape / Forbidden Act / Construction / Exploration / Outwit.

Brick Blast is currently pure **Construction** (elimination = reverse construction).

**Gaps**:
- Objective is binary (win/lose), no gradation (stars, score rank, time bonus)
- No secondary objectives (e.g. "clear without losing a ball", "clear under 60s")
- Mode choice (stages vs. roguelike) will fundamentally change objective structure

**Decision needed**: See P001 in decisions.md

---

## 3. Procedures

**Status**: ⚠️

**Current flow**:
```
Menu → Start → Ball auto-launches → Play (move paddle, bounce ball, break bricks)
  → Win (all bricks cleared) OR Lose (3 balls lost) → Restart / Menu
```

**Gaps**:
- Ball auto-launches — player has no "I'm ready" control
- No transition between rounds/waves (if endless or multi-level)
- No pause

---

## 4. Rules

**Status**: ✅ (basic)

**Current rules**:
- Paddle moves horizontally, stops at walls
- Ball bounces off walls, bricks, paddle
- Paddle hit angle depends on contact position (center = straight up, edges = angled)
- Bricks are one-hit destroy
- 3 lives, lose one when ball falls below paddle
- Ball speed increases 3% per paddle hit (capped at 550)

**Gaps**:
- No dynamic effect rules (e.g. "speed up after N bricks destroyed")
- No special brick types (hard, explosive, indestructible, power-up carrier)

---

## 5. Resources

**Status**: ⚠️ (weakest element)

**Current resources**:
| Resource | Status | Notes |
|----------|--------|-------|
| Lives | ✅ | 3, decremented on ball loss |
| Score | ⚠️ | Accumulates but has no consumption outlet — can't spend it |

**Missing resource types** (from Fullerton's list):
- Power-Ups: none yet
- Currency: score is currently currency-less
- Health: bricks have 1 HP, paddle/ball have no HP concept
- Time: no timer or time-based mechanics
- Inventory: none
- Special Terrain: none

**This is the primary area for expansion.**

---

## 6. Conflict

**Status**: ⚠️

Fullerton's conflict sources: Obstacles / Opponents / Dilemmas.

**Current**:
| Source | Status | Details |
|--------|--------|---------|
| Obstacles | ✅ | Brick layout blocks ball path |
| Opponents | N/A | Single-player, no AI |
| Dilemmas | ❌ | No meaningful choices to weigh |

**Gap**: Player never faces a decision where they must trade off risk vs. reward. Every moment has one optimal action: "go catch the ball."

**Potential dilemmas**:
- Hard bricks: choose which brick to target first
- Power-ups: risk positioning to catch a falling power-up vs. safely return ball
- Speed management: aggressive play (faster ball = more points) vs. safe play

---

## 7. Boundaries

**Status**: ✅

**Current**: 480×720 portrait playfield. Left/right/top walls reflect ball. Bottom = ball lost. Paddle constrained to horizontal movement within walls.

No issues identified.

---

## 8. Outcome

**Status**: ⚠️

**Current**: Binary — Win (all bricks cleared) / Lose (0 lives remaining).

**Gaps**:
- No gradation of outcome (perfect clear vs. barely survived)
- No score-based ranking or stars
- No "how well did you do?" feedback beyond raw score number

---

## Summary: Priority Actions

| Priority | Element | Gap | Impact |
|----------|---------|-----|--------|
| 1 | Resources | Only Lives + unused Score | Blocks all progression systems |
| 2 | Objectives | Binary win/lose, no mode structure | Blocks game depth |
| 3 | Conflict | No dilemmas | Every playthrough feels identical |
| 4 | Procedures | No player control over start/pace | Reduces sense of agency |
