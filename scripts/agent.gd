extends CharacterBody2D

var astar_grid:AStarGrid2D
@onready var tilemap= $"../Map"
@onready var target_list=$".."
@onready var sprite_2d=$Sprite2D
var is_moving
var is_done
signal arrived(pos)
var initial_pos
var path
func _ready():
	is_done=false
	initial_pos = global_position
		
func _process(_delta: float) -> void:
	if is_moving or is_done:
		return
	move()
	
	
func move():
	path = target_list.Astart_path(tilemap.local_to_map(initial_pos),tilemap.local_to_map(global_position),self)
	if path.is_empty():
		print(str(name)+": no target")
		return
	path.pop_front()
	if path.is_empty():
		arrived.emit(self)
		return	
	
	var original_position =Vector2(global_position)
	
	global_position= tilemap.map_to_local(path[0])
	sprite_2d.global_position= original_position
	
	if path.size() == 1 :
		arrived.emit(self)	
	
	is_moving=true
	
		
func _physics_process(delta: float) -> void:
	if is_moving:
		sprite_2d.global_position = sprite_2d.global_position.move_toward(global_position, 1) 

		if sprite_2d.global_position != global_position:
			return
		else:
			is_moving = false
	
	
		
			
