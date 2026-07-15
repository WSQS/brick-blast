# Changelog

All notable changes to brick-blast will be documented in this file.

## [Unreleased]

### Added

- ��化选择系统 (D014)：通关后弹出 3 选 1 强化面板，选择后重开同一��
- 5 种强化全部实现：挡板加宽(+50%)、减速(-20%)、额外生命(+1)、多球、穿透(穿过 3 块砖)
- 多球规则：额外球与主球不互相碰撞；有球在场时不扣命，所有球掉光才扣命
- 球粘挡板时额外球也跟随挡板移动
- 新场景 `scene/upgrade_panel.tscn`：强化选择 UI
- 新脚本 `script/upgrade.gd`（强化数据模型）、`script/upgrade_panel.gd`（UI 控制）
- 72 个单元测试（含 32 个强化系统测试）

### Changed

- 球碰撞层从 layer 1 改为 layer 2（mask 1），球与球之间不再碰撞
- 挡板加宽有上限：最多占屏幕宽度 80%（`minf(w * 1.5, playfield * 0.8)`）

### Fixed

- 强化面板不可见：CanvasLayer.visible 需要与 overlay.visible 同时控制
- 通关后球未停止：`_win()` 现在立即设置 `ball_stuck=true` + `velocity=ZERO`
- 多球时丢一球扣命：改为有球在场时不扣命
- 球粘挡板时额外球不跟随：`_process` 中同步额外球位置
- 强化面板打开时点击会发射球：`_input` 增加 `upgrade_panel.visible` 守卫
- 穿透未在碰挡板时重置：`_on_paddle_hit` 恢复 `pierce_count`
- 挡板加宽仅更新 CollisionShape：同步 ColorRect 的 size 和 position

## [0.0.1] - 2026-07-14

### Added

- Combo 系统 (D011)：连续击破砖块累积 combo，分数随 combo 缩放
- 球粘挡板 (D012)：球开局粘在挡板上，按 Space / 点击发射
- 星级评价 (D013)：通关后根据 combo 和命数计算 1-3 星
- 暂停功能 (D012)：Esc 暂停/恢复，显示 PAUSED 提示
- 主菜单场景 (`scene/menu.tscn`)：标题 + Start + Quit 按钮
- 游戏入口改为菜单 (`run/main_scene = res://scene/menu.tscn`)
- 游戏结束后显示 Menu 按钮可返回主菜单
- 完整游戏循环：Menu → Playing → Game Over / Win → Menu / Restart

### Changed

- **Paddle 移除 group 机制**: paddle 是唯一节点，不需要 group 查找。
  ball.gd 碰撞检测从 `collider.is_in_group("paddle")` 改为 `collider == parent.paddle`。
  删除 paddle.gd 的 `_ready()` group 注册和 paddle.tscn 的 `groups` 声明。
- **main.gd 重构**: `_reset_ball()` 重命名为 `_reset_round()`；`_compute_stars()` 返回 int 而非 String；
  提取 `_win`/`_lose` 重复代码为 `_end_game(text)`；魔法数字 `40.0` 提取为 `BALL_OFFSET` 常量。
- **paddle.gd**: 鼠标跟随改为仅在鼠标实际移动时生效（避免键盘松开后挡板跳回鼠标位置）。
- **brick.gd**: 移除未使用的 `get_rect()` 方法。
- **ball.gd**: 移除死代码 `circle_overlaps_rect`（迁移到 test_collision.gd）；`_on_ball_lost` 调用加空指针守卫。

### Fixed

- **暂停后挡板仍可移动**: 原方案使用 `get_tree().paused` + `PROCESS_MODE_ALWAYS`，
  `process_mode` 继承导致 paddle/ball 在暂停时仍运行。
  改为自定义 `paused` 变量，各节点显式检查 `parent.paused`，
  不依赖引擎全局暂停机制。
- **暂停时仍可发射球**: `_input` 缺少 `not paused` 守卫，暂停时按 Space 会设置 `ball_stuck = false`。

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
