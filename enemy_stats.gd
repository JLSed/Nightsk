extends Node

signal no_health
signal health_changed

@export var max_health : int = 50
@export var speed : int = 100
@export var min_damage : int = 1
@export var max_damage : int = 10
var enemy_damage : int
@onready var health: int = max_health:
	set(value):
		health = value
		emit_signal("health_changed")
		if health <= 0:
			emit_signal("no_health")

func randomize_damage(min_dmg, max_dmg):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var finalize_damage = rng.randi_range(min_dmg, max_dmg)
	return finalize_damage
