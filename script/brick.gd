extends StaticBody2D
## Brick — destructible block. Emits destroyed signal.
##
## Bricks are configured via configure(spec, polygon) which sets up the
## visual (Polygon2D), collision (ConvexPolygonShape2D), color, hp, and
## behaviors. For backwards compatibility with existing scenes/tests, a
## default ColorRect + RectangleShape2D is preserved until configure() is
## called.

signal destroyed

@export var color: Color = Color("e94560"):
	set(v):
		color = v
		if has_node("ColorRect"):
			($ColorRect as ColorRect).color = color

var spec: BrickSpec
var polygon: PackedVector2Array = PackedVector2Array()
var hp: int = 1
var _destroyed: bool = false


func _ready() -> void:
	# Apply the default color to the ColorRect if it exists (scene-placed brick).
	if has_node("ColorRect"):
		($ColorRect as ColorRect).color = color


## Configure this brick from a BrickSpec and a polygon (local-space vertices).
## Rebuilds the visual and collision nodes to match the polygon.
func configure(s: BrickSpec, poly: PackedVector2Array) -> void:
	spec = s
	polygon = poly
	hp = s.hp
	color = s.color
	_rebuild_visual()
	_rebuild_collision()


## Called when the ball hits this brick. Decrements hp, triggers behaviors,
## and destroys when hp reaches 0.
func on_hit(ball: Node, context: Node) -> void:
	if _destroyed:
		return
	hp -= 1
	if spec:
		for b in spec.behaviors:
			if b.on_hit(self, ball, context):
				break  # behavior consumed the hit; skip remaining
	if hp <= 0:
		if spec:
			for b in spec.behaviors:
				b.on_destroy(self, context)
		destroy()


func destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	destroyed.emit()
	queue_free()


func _rebuild_visual() -> void:
	if polygon.size() < 3:
		return  # Not enough vertices for a polygon; keep default ColorRect
	# Hide the default ColorRect, show a Polygon2D
	if has_node("ColorRect"):
		($ColorRect as ColorRect).visible = false
	var poly_node: Polygon2D
	if has_node("Polygon2D"):
		poly_node = $Polygon2D
	else:
		poly_node = Polygon2D.new()
		poly_node.name = "Polygon2D"
		add_child(poly_node)
	poly_node.polygon = polygon
	poly_node.color = color


func _rebuild_collision() -> void:
	if polygon.size() < 3:
		return  # Keep existing CollisionShape2D (RectangleShape2D default)
	var shape := ConvexPolygonShape2D.new()
	shape.points = polygon
	var col: CollisionShape2D
	if has_node("CollisionShape2D"):
		col = $CollisionShape2D
	else:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)
	col.shape = shape
