extends CharacterBody2D

const ACCELERATION = 500
var max_dmg_SPEED = 60
const FRICTION = 500

enum {
	ATTACK,
	MOVING,
	KNOCKBACK,
	DEATH
}
var STATE = MOVING
var attack_velocity = Vector2.RIGHT
var attack_pattern = 1
#@onready var animationPlayer = get_node("AnimationPlayer")
@onready var animationTree = get_node("AnimationTree")
@onready var animationState = animationTree.get("parameters/playback")
@onready var Marker = get_node("Marker2D")
@onready var stats = get_node("player_stats")
@onready var hitbox = get_node("Marker2D/Hitbox")
@onready var hurtbox = get_node("Hurtbox")
@onready var show_player_dmg = get_node("Player_Screen/showDMG_to_enemy")
@onready var hp_bar = get_node("Player_Screen/GuihpBar/ProgressBar")
@onready var hp_label = get_node("Player_Screen/GuihpBar/Label")
const show_damage = preload("res://UI/show_damage.tscn")

func _ready():
	hp_bar.value = stats.health
	hp_label.text = str(stats.health) + "/" + str(stats.max_health)

func _physics_process(delta):
	match STATE:
		MOVING:
			moving_state(delta)
		ATTACK:
			attack_state(delta)
		KNOCKBACK:
			knockback_state(delta)
		DEATH:
			death_state(delta)
	move_and_slide()
	
func _input(event):
	var mouse_position = get_local_mouse_position().normalized()
	if event is InputEventMouseMotion and STATE == MOVING:
		attack_velocity = mouse_position
		hitbox.vector = attack_velocity
		animationTree.set("parameters/Idle/blend_position", mouse_position)
		animationTree.set("parameters/Walk/blend_position", mouse_position)
		animationTree.set("parameters/Run/blend_position", mouse_position)
		animationTree.set("parameters/Attack1/blend_position", mouse_position)
		animationTree.set("parameters/Attack2/blend_position", mouse_position)
		animationTree.set("parameters/Attack3/blend_position", mouse_position)

func moving_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * max_dmg_SPEED, 50)
		if Input.is_action_pressed("ui_shift"):
			max_dmg_SPEED = 120
			animationState.travel("Run")
		else:
			max_dmg_SPEED = 60
			animationState.travel("Walk")
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		attack_pattern = rng.randi_range(1,3)
		stats.player_damage = stats.randomize_damage(stats.min_damage, stats.max_damage)
		hitbox.damage = stats.player_damage
		
		STATE = ATTACK
	
func attack_state(delta):
	match attack_pattern:
		1:
			animationState.travel("Attack1")
		2:
			animationState.travel("Attack2")
		3:
			animationState.travel("Attack3")
	velocity = velocity.move_toward(attack_velocity, 200 * delta)
	
func knockback_state(delta):
	animationState.travel("Hurt")
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
func death_state(delta):
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	animationState.travel("Death")
	show_damage.is_queued_for_deletion()

func knockback_animation_finished():
	STATE = MOVING
	
func change_state_toMoving():
	velocity = Vector2.ZERO
	STATE = MOVING
	
func display_damage(scene: PackedScene, damage_dealt):
	if scene:
		var effect = scene.instantiate()
		effect.damage_dealt = damage_dealt
		add_child(effect)
		effect.global_position = global_position

func _on_hurtbox_area_entered(area):
	STATE = KNOCKBACK
	animationTree.set("parameters/Hurt/blend_position", area.vector)
	velocity = area.vector * 50
	stats.health -= area.damage
	display_damage(show_damage, area.damage)

func _on_player_stats_no_health():
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	STATE = DEATH
	$AnimationPlayer.play("Death_Screen")

func _on_hitbox_area_entered(area):
	show_player_dmg.animate.play("RESET")
	show_player_dmg.damage_on_label.text = str(hitbox.damage) + " DMG"
	show_player_dmg.animate.play("damage_to_enemy")

func _on_player_stats_health_changed():
	hp_bar.value = stats.health
	hp_label.text = str(stats.health) + "/" + str(stats.max_health)
