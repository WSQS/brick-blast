class_name AsciiLayout
extends BrickLayout
## AsciiLayout — encodes a brick grid as an array of strings.
##
## Each string is a row; each character is a cell. The character is looked
## up in the level's specs table. A space (" ") means empty cell.
##
## Output polygons are axis-aligned rectangles (4 vertices). A rectangle is
## a polygon; the consumer treats all bricks as polygons uniformly.

@export var rows: Array[String] = []
@export var cell_size: Vector2 = Vector2(52, 22)
@export var grid_origin: Vector2 = Vector2(0, 80)
@export var gap: float = 4.0
@export var target_width: float = 0.0


func build(specs: Dictionary) -> Array[Dictionary]:
	var x_offset: float = 0.0
	if target_width > 0:
		var max_cols := 0
		for row in rows:
			max_cols = maxi(max_cols, row.length())
		if max_cols > 0:
			var grid_width := max_cols * cell_size.x + (max_cols - 1) * gap
			x_offset = (target_width - grid_width) / 2.0
	var result: Array[Dictionary] = []
	for row_idx in rows.size():
		var row: String = rows[row_idx]
		for col_idx in row.length():
			var ch: String = row[col_idx]
			if ch == " ":
				continue
			if not specs.has(ch):
				continue
			var polygon := _cell_polygon(col_idx, row_idx, x_offset)
			result.append({"polygon": polygon, "spec": specs[ch]})
	return result


func _cell_polygon(col: int, row: int, x_offset: float = 0.0) -> PackedVector2Array:
	var x: float = grid_origin.x + x_offset + col * (cell_size.x + gap) + cell_size.x / 2.0
	var y: float = grid_origin.y + row * (cell_size.y + gap) + cell_size.y / 2.0
	var hx: float = cell_size.x / 2.0
	var hy: float = cell_size.y / 2.0
	return PackedVector2Array(
		[
			Vector2(x - hx, y - hy),
			Vector2(x + hx, y - hy),
			Vector2(x + hx, y + hy),
			Vector2(x - hx, y + hy),
		]
	)
