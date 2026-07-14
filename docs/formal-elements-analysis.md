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

**Status**: ⚠️ → 决策已定 (D010)，待实现

**Current**: Clear all bricks = win. Lose all 3 lives = game over.

**Decision (D010)**: Construction（主）+ Forbidden Act（第一副）+ Outwit（后续副）
- 主目标：清砖块（已有）
- 第一副目标：挑战条件（连击为主，不绑死）+ 星级评价
- 第二副目标（后续）：强化选择，星级影响选择数量/质量
- 正向循环：玩得好 → 更多星级 → 更多强化 → 更强

Fullerton's objective types:

- **Capture** — 获取或夺取特定物品（如打中关键砖块触发道具）
- **Chase** — 追逐移动目标（打砖块不太适用，玩家是"接"不是"追"）
- **Race** — 在限定时间内完成，或比对手更快（如限时模式）
- **Alignment** — 将元素排列成特定图案（如俄罗斯方块、三消，与打砖块不搭）
- **Rescue** — 拯救某物脱离危险（除非加叙事层，否则不自然）
- **Escape** — 从困境中脱出（如砖块不断下压，必须在被压死前清除）
- **Forbidden Act** — 不能做某事，做了就失败（如"不丢球通关"作为额外挑战）
- **Construction** — 通过放置或移除元素达成目标（打砖块的核心：消除所有砖块）
- **Exploration** — 发现隐藏内容（如隐藏砖块、秘密关卡入口）
- **Outwit** — 通过策略而非纯操作取胜（如 Roguelike 的强化选择）

**Remaining gaps**:
- 连击系统尚未实现
- 星级评价尚未实现
- 强化选择系统尚未实现（Phase 2）

---

## 3. Procedures

**Status**: ⚠️ → 决策已定 (D012)，待实现

**Decision (D012)**:
1. **球粘挡板**（待实现）：球贴在挡板上跟随移动，点击/空格发射。与 combo 配套
2. **暂停**（待实现）：Esc 暂停，最小化 UI
3. **关卡间过渡**：推迟到 Phase 2

**Target flow**:
```
Menu → Start → Ball sticks to paddle → Click/Space to launch → Play (combo, bricks)
  → Win/Lose → Restart/Menu
  Esc → Pause (Resume / Menu)
```

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

**Status**: ⚠️ → 决策已定 (D011)，待实现

**Current resources**:
| Resource | Status | Notes |
|----------|--------|-------|
| Lives | ✅ | 3, decremented on ball loss |
| Score | ⚠️ | Accumulates but has no consumption outlet — can't spend it |
| Combo | ❌ 待实现 | D011: 每打一块砖 +1，碰挡板/失球重置 |
| Stars | ❌ 待实现 | D010: 通关后根据 combo 等条件评定 1-3 星 |
| Upgrade choices | ❌ Phase 2 | D010: 星级影响强化选择数量 |

**Combo rules (D011)**:
- 球碰砖块 → combo += 1
- 球碰挡板 → combo = 0
- 球碰墙 → 不影响 combo
- 失球 → combo = 0

**设计意图**: combo 在接球环节引入 Dilemma——"冒险多打一块砖 vs 安全接球"

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
