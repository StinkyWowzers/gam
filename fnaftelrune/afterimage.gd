extends Sprite2D

@export var lifetime := 0.25

func _ready():
	var tween = create_tween()

	tween.tween_property(self, "modulate:a", 0.0, lifetime)

	await tween.finished

	queue_free()
