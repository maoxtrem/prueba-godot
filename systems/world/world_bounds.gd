extends RefCounted
class_name WorldBounds

const SIZE := Vector2(4000.0, 4000.0)
const RECT := Rect2(Vector2.ZERO, SIZE)
const MARGIN := 48.0

static func playable_rect() -> Rect2:
	return RECT.grow(-MARGIN)

static func clamp_position(position: Vector2) -> Vector2:
	var area := playable_rect()
	return Vector2(
		clampf(position.x, area.position.x, area.end.x),
		clampf(position.y, area.position.y, area.end.y)
	)

static func contains_position(position: Vector2) -> bool:
	var area := playable_rect()
	return position.x >= area.position.x and position.x <= area.end.x and position.y >= area.position.y and position.y <= area.end.y
