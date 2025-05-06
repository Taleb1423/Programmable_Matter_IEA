extends Node2D

@onready var tilemap : TileMapLayer = $Map
class target:
	var position = Vector2i(0,0)
	var ocupied  = false
	var weight = 0
	
	
	static func create(loc:Vector2,w):
		var ins = target.new()
		ins.position = loc
		ins.weight = w
		return ins
		

@export var agent_nb = 0
var astar_grid:AStarGrid2D
enum PlacementType { NONE, TARGET, OBSTACLE }
var current_placement_type = PlacementType.NONE
var targets=[]
@onready var agent_scene = preload("res://scenes/agent.tscn")
@onready var target_button = $Target_Button
@onready var obstacle_button = $Obstacle_Button
@onready var start_button = $start
@onready var reset = $reset
@onready var set_speed = $speed
@onready var set_nb = $agent_nb
func _ready():
	pass
	
	
func _input(event):
	if Input.is_action_just_pressed("click") and current_placement_type != PlacementType.NONE:
		print("Click")
		var mouse_pos = get_global_mouse_position()
		print("global mouse pos: ", mouse_pos)
		var tile_pos = tilemap.local_to_map(mouse_pos)
		
		# Place the appropriate tile based on the current selection
		if tilemap.get_used_rect().has_point(tile_pos):
			if current_placement_type == PlacementType.TARGET:
				place_target(tile_pos)
			elif current_placement_type == PlacementType.OBSTACLE:
				place_obstacle(tile_pos)
			
	if Input.is_action_just_pressed("right_click"):
		var mouse_pos = get_global_mouse_position()
		var tile_pos = tilemap.local_to_map(mouse_pos)
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



	
func _on_agent_arrived(agent) -> void:
	print("arrived")
	for tar in targets:
		if not tar.ocupied:
			if 		agent.global_position== tilemap.map_to_local(tar.position):
				agent.is_done=true
				print("arrived at "+str(tar.position))
				tar.ocupied=true
				return
			return
	
		

func compute_weight(targets):
	var w
	var s= 99
	var freen
	for tar in targets:
		freen=false
		print("computing:" +str(Vector2i(tar.position)))
		var neighbors=[Vector2i.UP+Vector2i(tar.position),Vector2i.DOWN+Vector2i(tar.position),Vector2i.LEFT+Vector2i(tar.position),Vector2i.RIGHT+Vector2i(tar.position)]
		w=tar.weight
		
		for n in neighbors:
			print(n)		
			if tilemap.get_cell_tile_data(n).get_custom_data("target"):
				for t in targets:
					if n == Vector2i(t.position):
						s= t.weight
						print(s)				
				if w>s:
					w=s
			elif tilemap.get_cell_tile_data(n).get_custom_data("Free"):
				
				print("free cell, w = 1")
				freen=true
				break
		if(freen):
			tar.weight=1
		else:
			tar.weight = w+1	
	return

func sort_targets(a,b)->bool:
	if a.weight > b.weight:
		return true
	else:
		return false	


func _on_start_pressed() -> void:
	agent_nb = int(set_nb.text)
	
	target_button.visible=false
	obstacle_button.visible=false
	start_button.visible=false
	set_nb.visible = false
	set_speed.visible = false
	for a in get_tree().get_nodes_in_group("agents"):
		a.queue_free()
		
	astar_grid = AStarGrid2D.new()
	astar_grid.region =tilemap.get_used_rect()
	astar_grid.cell_size =Vector2(32,32)
	astar_grid.diagonal_mode= AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	var i = agent_nb
	var region_size = astar_grid.region.size
	
	var region_position =astar_grid.region.position
	
	for y in region_size.y:
		
		for x in region_size.x:
			var w
			var tile_position=Vector2i(x+region_position.x,region_size.y-1-y +region_position.y)
			
			var tile_data = tilemap.get_cell_tile_data(tile_position)
			
			if tile_data == null or !tile_data.get_custom_data("Free"):
				astar_grid.set_point_solid(tile_position)
				continue
			else:
				if i>0:
					var ins = agent_scene.instantiate()
					ins.name="agent"+str(i)
					add_child(ins)
					ins.position = tilemap.map_to_local(tile_position)
					ins.arrived.connect(_on_agent_arrived)
					i -=1
				
			if tile_data.get_custom_data("target"):
				targets.push_back(target.create(tile_position,99))
			
	compute_weight(targets)
	
	targets.sort_custom(sort_targets)
		
func Astart_path(original_pos,pos,a1):
	var agents = get_tree().get_nodes_in_group("agents")
	var agents_pos = []
	for ag in agents:
		if ag ==a1:
			continue
		agents_pos.append(tilemap.local_to_map(ag.global_position))
	for poss in agents_pos:
		astar_grid.set_point_solid(poss)	
	var pout
	
	for tar in targets:
		if not tar.ocupied:
			pout= astar_grid.get_id_path(pos,tar.position)
			
				
			for poss in agents_pos:
				astar_grid.set_point_solid(poss,false)
			if pout== null:
				continue	
			return pout
	pout = astar_grid.get_id_path(pos,pos+Vector2i.DOWN)
	for poss in agents_pos:
		astar_grid.set_point_solid(poss,false)
	
	return 



func _on_reset_pressed() -> void:
	 # Replace with function body.
	get_tree().reload_current_scene()
