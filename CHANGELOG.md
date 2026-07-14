# Changelog

All notable changes to brick-blast will be documented in this file.

## [Unreleased]

### Added

- Combo 系统 (D011)：连续击破砖块累积 combo，分数随 combo 缩放
- 球粘挡板 (D012)：球开局粘在挡板上，按 Space / 点击发射
- 星级评价 (D013)：通关后根据 combo 和命数计算 1-3 星
- 暂停功能 (D012)：Esc 暂停/恢复，显示 PAUSED 提示
- 主菜单场景 (`scene/menu.tscn`)：标题 + Start + Quit 按钮
- 游戏入口改为菜单 (`run/main_scene = res://scene/menu.tscn`)
- 游戏结束后显示 Menu 按钮可返回主菜单
- 完整游戏循环：Menu → Playing → Game Over / Win → Menu / Restart

### Fixed

- **暂停后挡板仍可移动**: 原方案使用 `get_tree().paused` + `PROCESS_MODE_ALWAYS`，
  `process_mode` 继承导致 paddle/ball 在暂停时仍运行。
  改为自定义 `paused` 变量，各节点显式检查 `parent.paused`，
  不依赖引擎全局暂停机制。

### Architecture Decision: CharacterBody2D (2026-07-14)

**问题**: Ball 使用 `Area2D`，在 `_physics_process` 中手动 `position += velocity` 移动。
`Area2D` 的碰撞检测（`get_overlapping_areas()` / `intersect_shape()`）由 `PhysicsServer2D`
在物理步进开始时更新，永远滞后一帧。结果：球的高速移动会导致碰撞检测完全失效（穿砖）。

**决策**: 将 Ball 从 `Area2D` 改为 `CharacterBody2D`。

| 组件 | 旧类型 | 新类型 | 原因 |
|------|--------|--------|------|
| Ball | Area2D | CharacterBody2D | `move_and_collide()` 自带 CCD，碰撞结果即时返回 |
| Brick | Area2D | StaticBody2D | 静态碰撞体，供 `move_and_collide` 检测 |
| Paddle | Area2D | StaticBody2D（或 AnimatableBody2D） | 同上 |

**选择 CharacterBody2D 而非 RigidBody2D 的原因**:
- 打砖块的反弹是规则驱动的，不是物理模拟
- 挡板角度反弹需要精确控制（命中位置 → 出射角）
- 后续道具（穿透、粘球、弧线）更容易在 CharacterBody2D 上实现
- 参考项目 Brick Blast 也使用自建物理（等价于 CharacterBody2D 路线）

### Added

- GUT (Godot Unit Test) v9.6.1 测试框架
- 17 个纯函数碰撞数学单元测试（墙壁/砖块/挡板/重叠检测）
- 物理碰撞集成测试（基于 `wait_physics_frames` 驱动真实物理引擎）

### Fixed

- **球碰砖块不反弹（关键 bug）**: `.tscn` 中声明的 `groups = ["brick"]` 在 `PackedScene.instantiate() + add_child()` 后**不会保留**。碰撞时 `collider.is_in_group("brick")` 永远返回 false，碰撞处理代码被跳过，球卡在砖块表面。
  - 修复：`main.gd._spawn_bricks()` 中显式 `brick.add_to_group("brick")`
  - 修复：`paddle.gd._ready()` 中显式 `add_to_group("paddle")`
- ball.gd: 修复 `_check_collisions` 碰撞检测滞后一帧导致穿砖
- ball.gd: 修复 `area_entered` 边沿触发在高速下丢失碰撞
- ball.gd: 添加位置修正（碰撞后将球推出物体表面）
- main.gd: 修复 `COLORS[row % COLORS.size()]` 表达式损坏
- main.gdc: 修复 `brick_scene` @export 赋值顺序（script 必须先于 export 属性）
- brick.gd: 修复 `var s :=` 类型推断失败
