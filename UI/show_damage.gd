extends Node2D

@onready var animate = $AnimationPlayer
@onready var damage_on_label = $Label
@onready var damage_dealt

func _ready():
	if damage_dealt != 0:
		damage_on_label.text = str(damage_dealt)
	else:
		damage_on_label.text = "MISS"
	animate.play("damage_to_player")
