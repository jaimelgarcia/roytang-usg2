extends KinematicBody2D

signal hit
signal child_created
signal child_destroyed

export var speed = 75
var _player

export var hpmax = 100
var hpcurrent = hpmax

export var can_be_hit = true
var hit_recovery_secs = 0.2 

# composite enemies are automatically destroyed when the last child is destroyed
export var composite = false
var child_count = 0

export var rotating = false
export var drop_count = 1

var health_pickup = "res://Items/HealthPickup.tscn" 
var energy_pickup = "res://Items/EnergyPickup.tscn" 
var minerals_pickup = "res://Items/MineralsPickup.tscn" 

var drop_list = [minerals_pickup, minerals_pickup, minerals_pickup, energy_pickup, health_pickup]

# hit flash stuff
var sprite
var flash_timer
const SHADER = preload("res://hitflash.gdshader")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	_player = get_node("/root/Player")
	hpcurrent = hpmax
	connect("hit", self, "_on_Enemy_hit")
	
	if composite:
		connect("child_created", self, "_on_child_created")
		connect("child_destroyed", self, "_on_child_destroyed")
	get_parent().emit_signal("child_created")
		
	sprite = $Sprite
	if is_instance_valid(sprite):
		flash_timer = Timer.new()
		flash_timer.wait_time = 0.2
		add_child(flash_timer)
		flash_timer.connect("timeout", self, "_on_flash_timeout")
		
		var mat = ShaderMaterial.new()
		mat.shader = SHADER
		# mat.set_shader(SHADER)
		sprite.set_material(mat)
		
	var collision_shape = $CollisionShape2D

func _process(delta):
	if is_instance_valid(_player) and rotating:
		look_at(_player.get_global_position())

func _on_Enemy_hit(damage):
	if is_instance_valid(sprite):
		sprite.material.set_shader_param("flash_modifier", 1.0)
		flash_timer.start()
	
	print("Hit for damage ", damage)
	if can_be_hit:
		hpcurrent = hpcurrent - damage
		print("Remaining HP ", hpcurrent)
		can_be_hit = false
		if hpcurrent <= 0:
			die()
		else:
			var _anim = get_node("AnimationPlayer")
			if is_instance_valid(_anim):
				_anim.play("hit")
		yield(get_tree().create_timer(hit_recovery_secs), "timeout")
		can_be_hit = true

func die():

	for n in range(drop_count):
		# drop a random pickup
		var count_opts = drop_list.size()
		var new_scene = drop_list[randi() % count_opts]
		# spawn pickup 5-10 units away in a random direction
		var pickup = load(new_scene).instance()
		var rand_direction = Vector2(randf()*2-1, randf()*2-1)
		var rand_x = randi()%5 + 5
		var rand_y = randi()%5 + 5
		var offset = Vector2(rand_x, rand_y) * rand_direction
		pickup.position = get_global_position() + offset
		get_tree().get_root().call_deferred("add_child", pickup)
	
	# make sumbong to the parent
	get_parent().emit_signal("child_destroyed")
	queue_free()


func _on_flash_timeout():
	sprite.material.set_shader_param("flash_modifier", 0.0)

func _on_child_created():
	child_count = child_count + 1

func _on_child_destroyed():
	child_count = child_count - 1
	if child_count <= 0:
		die()
