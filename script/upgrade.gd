class_name Upgrade
## Upgrade — defines a power-up that modifies game state between rounds.

enum Type { PADDLE_WIDE, SLOW_BALL, EXTRA_LIFE, MULTI_BALL, PIERCE }

var id: Type
var display_name: String
var description: String


static func all() -> Array[Upgrade]:
	return [
		_create(Type.PADDLE_WIDE, "Wide Paddle", "+50% paddle width"),
		_create(Type.SLOW_BALL, "Slow Ball", "-20% ball speed"),
		_create(Type.EXTRA_LIFE, "Extra Life", "+1 life"),
		_create(Type.MULTI_BALL, "Multi-Ball", "Launch an extra ball"),
		_create(Type.PIERCE, "Pierce", "Ball pierces through 3 bricks"),
	]


static func _create(p_id: Type, p_name: String, p_desc: String) -> Upgrade:
	var u := Upgrade.new()
	u.id = p_id
	u.display_name = p_name
	u.description = p_desc
	return u


static func random_choices(count: int) -> Array[Upgrade]:
	var pool: Array[Upgrade] = all()
	pool.shuffle()
	var result: Array[Upgrade] = []
	for i in mini(count, pool.size()):
		result.append(pool[i])
	return result
