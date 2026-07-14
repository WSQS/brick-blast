# Decision Log

All significant design and architecture decisions, with context and rationale.

---

## D001: 项目定位 — 真正的游戏项目 (2026-07-14)

**Context**: 区别于 godot-little-games（玩法实验室），创建一个有完整玩法循环的游戏。
**Decision**: 以打砖块为主题，参考 Brick Blast (Kotlin/Android, F-Droid)。
**Rationale**: 打砖块机制简单清晰，适合作为第一个完整游戏项目。核心循环明确：控制挡板 → 反弹球 → 消除砖块。

---

## D002: 引擎选择 — Godot 4.7 (2026-07-14)

**Context**: 需要选择游戏引擎，目标平台 Windows + Android + Web。
**Decision**: 使用 Godot 4.7（Steam 版），GL Compatibility 渲染器。
**Rationale**: 已有 godot-little-games 的 Godot 经验；GL Compatibility 支持全平台；免费开源。

---

## D003: 物理方案 — CharacterBody2D + move_and_collide (2026-07-14)

**Context**: Ball 最初使用 Area2D + 手动 position 移动。Area2D 的碰撞检测（get_overlapping_areas / intersect_shape）由 PhysicsServer2D 在物理步进开始时更新，永远滞后一帧。高速球穿砖。
**Options considered**:
1. Area2D + 手动碰撞检测 — 滞后一帧，穿砖
2. RigidBody2D — 物理引擎驱动，反弹角度不可控
3. CharacterBody2D + move_and_collide — CCD，碰撞即时返回，速度可控
**Decision**: CharacterBody2D。
**Rationale**:
- 打砖块反弹是规则驱动的，不是物理模拟
- 挡板角度反弹需要精确控制（命中位置 → 出射角）
- 后续道具（穿透、粘球、弧线）更容易实现
- move_and_collide 自带 CCD，不会穿模
- 参考项目 Brick Blast 使用自建物理（等价路线）

---

## D004: 碰撞数学提取为纯静态方法 (2026-07-14)

**Context**: 需要对碰撞逻辑进行单元测试，但物理引擎行为在 GUT 测试环境中难以驱动。
**Decision**: 将碰撞数学（墙壁反弹、砖块反弹、挡板角度、圆-矩形重叠）提取为 ball.gd 的 static func。
**Rationale**: 纯函数不依赖物理引擎，可以直接单元测试。物理集成测试单独验证 move_and_collide 行为。

---

## D005: 测试策略 — GUT + 纯函数 + 物理集成 (2026-07-14)

**Context**: 需要验证碰撞逻辑正确性。
**Decision**:
- 纯函数测试：墙壁/挡板/重叠检测的数学逻辑（不依赖物理引擎）
- 物理集成测试：force_update_transform + move_and_collide 验证真实碰撞行为
- Bug fix workflow：先写失败测试复现 bug，再修复
**Rationale**: 两层测试覆盖——数学正确性 + 物理引擎交互正确性。
**Key findings**: GUT 不步进 PhysicsServer2D；.tscn groups 在 instantiate() 后丢失；queue_free 是延迟的。

---

## D006: 游戏入口 — 主菜单 (2026-07-14)

**Context**: 游戏缺少完整的循环（打开就直接进游戏，打完只能 Restart）。
**Decision**: 添加主菜单场景 (menu.tscn) 作为游戏入口，包含 Start / Quit 按钮。
**Rationale**: 建立完整循环 Menu → Playing → Game Over/Win → Menu/Restart。为后续多模式选择做铺垫。

---

## D007: 设计方法论 — Playcentric Design + Formal Elements (2026-07-14)

**Context**: 作为程序员转游戏设计，需要系统化的设计方法。
**Decision**: 采用 Fullerton《Game Design Workshop》的 Playcentric Design 作为主流程，用 Formal Elements (Ch 3) 框架定期审视设计。
**Rationale**: Playcentric 强调"设定体验目标 → 原型 → 测试 → 迭代"，与当前小步快跑开发方式一致。
**Status**: 已用 Formal Elements 分析当前游戏，识别出三个薄弱点：
1. Resources 过于稀少（只有 Lives 和 Score，Score 无消费出口）
2. Conflict/Dilemmas 不足（玩家没有需要权衡的决策）
3. Procedures 缺少过渡（球自动发射，无掌控感）

---

## D008: 暂不添加大量设计文档 (2026-07-14)

**Context**: 检索结果建议建立完整的 docs/ 目录结构（vision.md, pillars.md, core-loop.md 等）。
**Decision**: 不一次性创建所有文档，按需添加。
**Rationale**: 避免过早建设。当前已有 copilot-instructions.md 和 CHANGELOG.md，后续在必要节点添加对应文档。

---

## D009: Git 提交规范 — Angular Convention (2026-07-14)

**Context**: 提交历史需要规范化。
**Decision**: 使用 Angular commit convention（type(scope): subject）。
**Types**: feat / fix / refactor / test / docs / style / chore
**Rationale**: 行业标准，结构清晰，便于追踪变更类型。

---

## Pending Decisions

以下决策尚未确定，列出备选方向供后续讨论：

### P001: 游戏模式选择
- 闯关模式：固定关卡布局，通关解锁
- Roguelike 模式：随机关卡 + 强化选择
- 其他：Classic（无尽）/ Time Attack / Hardcore / Puzzle / Zen
**Status**: 待讨论。需要先确定"想给玩家什么体验"（MDA 的 Aesthetics 层）。

### P002: 下一功能方向
基于 Formal Elements 分析的三个薄弱点：
- Resources → 道具系统
- Conflict → 硬砖块（不同 HP）
- Procedures → 球粘挡板（点击发射）
**Status**: 待讨论。

### P003: 关卡数据格式
- JSON 文件
- Godot Resource (.tres)
- 二维数组/字符串
**Status**: 需要先确定是否做闯关模式（P001）。
