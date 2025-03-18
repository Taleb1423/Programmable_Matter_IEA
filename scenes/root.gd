extends Node2D


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
@onready var tilemap= $Map
var targets=[]
@onready var agent_scene = preload("res://scenes/agent.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	
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
			else:
				if i>0:
					var ins = agent_scene.instantiate()
					ins.name="agent"+str(i)
					add_child(ins)
					ins.position = tilemap.map_to_local(tile_position)
					ins.arrived.connect(_on_agent_arrived)
					i -=1
				
			if tile_data.get_custom_data("target"):
				targets.push_back(target.create(tile_position,compute_weight(tile_position)))
			
	targets.sort_custom(sort_targets)
	for tar in targets:
		print(tar.position)	
	
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
			return pout
	pout = astar_grid.get_id_path(pos,pos+Vector2i.DOWN)
	for poss in agents_pos:
		astar_grid.set_point_solid(poss,false)
	
	return 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
	
		

func compute_weight(tile_pos:Vector2i )->int:
	var w = 0
	var neighbors=[tilemap.get_cell_tile_data(Vector2i.UP+tile_pos),tilemap.get_cell_tile_data(Vector2i.DOWN+tile_pos),tilemap.get_cell_tile_data(Vector2i.LEFT+tile_pos),tilemap.get_cell_tile_data(Vector2i.RIGHT+tile_pos)]
	for n in neighbors:
		if n.get_custom_data("target"):
			w +=1
		if not n.get_custom_data("Free"):
			w+=1	
	return w

func sort_targets(a,b)->bool:
	if a.weight > b.weight:
		return true
	else:
		return false
	
		
	 			
