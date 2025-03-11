extends CharacterBody2D

var astar_grid:AStarGrid2D
@onready var tilemap= $"../Map"
@onready var sprite_2d=$Sprite2D
var is_moving
var targets=[]
var arrived

func _ready():
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region =tilemap.get_used_rect()
	astar_grid.cell_size =Vector2(32,32)
	astar_grid.diagonal_mode= AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	var region_size = astar_grid.region.size
	
	var region_position =astar_grid.region.position
	
	for x in region_size.x:
		for y in region_size.y:
			
			var tile_position=Vector2i(x+region_position.x,y+region_position.y)
			
			var tile_data = tilemap.get_cell_tile_data(tile_position)
			
			if tile_data == null or !tile_data.get_custom_data("Free"):
				astar_grid.set_point_solid(tile_position)
				
			if tile_data.get_custom_data("target"):
				
				targets.push_back(tile_position)
		
	print(targets)	
		
		
func _process(_delta: float) -> void:
	if is_moving or arrived:
		return
	move()
	
	
func move():
	var path = astar_grid.get_id_path(tilemap.local_to_map(global_position),targets[9])
	path.pop_front()
	if path.is_empty():
		print("no path")
		return
		
	var original_position =Vector2(global_position)
	global_position= tilemap.map_to_local(path[0])
	sprite_2d.global_position= original_position
	is_moving=true
	
		
func _physics_process(delta: float) -> void:
	if is_moving:
		sprite_2d.global_position = sprite_2d.global_position.move_toward(global_position, 1) 

		if sprite_2d.global_position != global_position:
			return
		else:
			is_moving = false
