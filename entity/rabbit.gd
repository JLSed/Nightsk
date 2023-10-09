extends CharacterBody2D

@onready var stats = $enemy_stats
@onready var hurtbox = $Hurtbox
@onready var hitbox = $Marker2D/Hitbox
@onready var player_detector = $Player_Detector
@onready var animation_player = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var marker = $Marker2D
@onready var hp_bar = $ProgressBar
@onready var timer_for_death = get_node("Timer_for_Death")
const show_damage = preload("res://UI/show_damage.tscn")

enum {
	IDLE,
	CHASE,
	ATTACK,
	KNOCKBACK,
	DEATH
}
var STATE = IDLE
var player
var speed

func _ready():
	player = player_detector.player
	speed = stats.speed
	stats.enemy_damage = stats.randomize_damage(stats.min_damage, stats.max_damage)
	hitbox.damage = stats.enemy_damage
	
func _physics_process(delta):
	match STATE:
		IDLE:
			idle_state(delta)
		CHASE:
			chase_state(delta)
		ATTACK:
			attack_state(delta)
		KNOCKBACK:
			knockback_state(delta)
		DEATH:
			death_state(delta)
	move_and_slide()

func _on_hurtbox_area_entered(area):
		STATE = KNOCKBACK
		velocity = area.vector * 85
		stats.health -= area.damage
		display_damage(show_damage, area.damage)
		
func idle_state(delta):
	velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
	animation_player.play("Idle")

func chase_state(delta):
	animation_player.play("Run")
	var destination = (player.global_position - global_position).normalized()
	hitbox.vector = destination
	velocity = velocity.move_toward(destination * speed, 100 * delta)
	if (player.global_position.x - global_position.x) < 0:
		sprite.flip_h = true
		marker.rotation_degrees = 180
	else:
		sprite.flip_h = false
		marker.rotation = 0

func attack_state(delta):
	velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
	animation_player.play("Attack")
	
func knockback_state(delta):
	hp_bar.visible = true
	hp_bar.value = stats.health
	animation_player.play("Hurt")
	velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)

func death_state(delta):
	velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
	animation_player.play("Death")
	hurtbox.set_deferred("monitorable", false)
	hurtbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	hitbox.set_deferred("monitoring", false)
	
func display_damage(scene: PackedScene, damage_dealt):
	if scene:
		var effect = scene.instantiate()
		effect.damage_dealt = damage_dealt
		add_child(effect)

func knockback_animation_finished():
	if player == null:
		STATE = IDLE
	else:
		STATE = CHASE

func attack_animation_finished():
	STATE = CHASE

func _on_player_detector_body_entered(body):
	player = body
	STATE = CHASE

func _on_player_detector_body_exited(_body):
	player = null
	STATE = IDLE

func _on_enemy_stats_no_health():
	timer_for_death.start()
	STATE = DEATH

func _on_hitbox_area_entered(_area):
	stats.enemy_damage = stats.randomize_damage(stats.min_damage, stats.max_damage)
	hitbox.damage = stats.enemy_damage
	STATE = ATTACK

func _on_timer_for_death_timeout():
	STATE = DEATH

func _on_enemy_stats_health_changed():
	hp_bar.value = stats.health
