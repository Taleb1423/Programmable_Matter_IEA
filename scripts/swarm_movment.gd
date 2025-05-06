extends Node2D

enum PlacementType { NONE, TARGET, OBSTACLE }
var current_placement_type = PlacementType.NONE
@onready var agent_scene = preload("res://scenes/agent_swarm.tscn")
@onready var target_button = $Target_Button
@onready var obstacle_button = $Obstacle_Button
@onready var start_button = $start
@onready var reset = $reset
@onready var set_speed = $speed
@onready var set_nb = $agent_nb
@onready var tilemap=$Map
var agent_number = 0
var map
var grid_size
var grid_position

func _ready() -> void:
	pass
   
	
	
func _input(event):
	var radius = tilemap.get_used_rect()
	radius.position += Vector2i(1, 1)
	radius.size -= Vector2i(2, 2)
	if Input.is_action_pressed("click") and current_placement_type != PlacementType.NONE:
		print("Click")
		var mouse_pos = get_global_mouse_position()
		print("global mouse pos: ", mouse_pos)
		var tile_pos = tilemap.local_to_map(tilemap.to_local(mouse_pos))
		
		
		# Place the appropriate tile based on the current selection
		if radius.has_point(tile_pos):
			if current_placement_type == PlacementType.TARGET:
				place_target(tile_pos)
			elif current_placement_type == PlacementType.OBSTACLE:
				place_obstacle(tile_pos)
			
	if Input.is_action_pressed("right_click"):
		var mouse_pos = get_global_mouse_position()
		var tile_pos = tilemap.local_to_map(tilemap.to_local(mouse_pos))
		if radius.has_point(tile_pos):
			remove_tile(tile_pos)

func _on_target_button_pressed():
	print("Target mode activated")
	current_placement_type = PlacementType.TARGET

func _on_obstacle_button_pressed():
	print("Obstacle mode activated")
	current_placement_type = PlacementType.OBSTACLE

func place_target(tile_pos: Vector2i) -> void:
	var source_id = 0
	var atlas_coordt = Vector2i(7, 9)
	
	tilemap.set_cell(tile_pos, source_id, atlas_coordt)
	print("Target placed at:", tile_pos)

func place_obstacle(tile_pos: Vector2i) -> void:
	var source_id = 0
	var atlas_coordo = Vector2i(8, 2)
	
	tilemap.set_cell(tile_pos, source_id, atlas_coordo)
	print("Obstacle placed at:", tile_pos)
	
func remove_tile(tile_pos: Vector2i) -> void:
	var existing_tile = tilemap.get_cell_tile_data(tile_pos)
	if existing_tile != null:
		var source_id = 0
		var atlas_coordf = Vector2i(3, 4)
		#tile_map.set_cell(tile_pos, -1)  # Remove the tile
		tilemap.set_cell(tile_pos, source_id, atlas_coordf)
		print("Tile removed at:", tile_pos)
		
func _on_reset_pressed() -> void:
	 # Replace with function body.
	get_tree().reload_current_scene()

	


func _on_start_pressed() -> void:
	target_button.visible=false
	obstacle_button.visible=false
	start_button.visible=false
	set_nb.visible = false
	set_speed.visible = false
	
	
	map = tilemap.get_used_rect()
	grid_size = map.size
	grid_position = map.position
	
	for a in get_tree().get_nodes_in_group("agents"):
		a.queue_free()
	agent_number = int(set_nb.text)
	var i = agent_number
	for y in grid_size.y:
		
		for x in grid_size.x:
			var w
			var tile_position=Vector2i(x+grid_position.x,grid_size.y-1-y +grid_position.y)
			
			var tile_data = tilemap.get_cell_tile_data(tile_position)
			
			if tile_data == null or !tile_data.get_custom_data("Free"):
				continue
			else:
				if i>0:
					var ins = agent_scene.instantiate()
					ins.name="agent"+str(i)
					add_child(ins)
					ins.position = tilemap.map_to_local(tile_position)
					i -=1
	var agents = get_tree().get_nodes_in_group("agents") 
	for emitter in agents:
		for receiver in agents:
			# Connect each agent's "propose" signal to _on_propose() in all agents
			emitter.connect("propose", Callable(receiver, "_on_propose"))
			emitter.connect("proclame", Callable(receiver, "_on_proclame"))
			emitter.connect("moved_to", Callable(receiver, "_on_moved_to"))
			emitter.connect("reached_center", Callable(receiver, "_on_reached_center"))
			emitter.connect("arrived_at_goal",Callable(receiver, "_on_arrived_at_goal") )
			
