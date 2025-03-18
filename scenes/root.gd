extends Node2D


class target:
	var position = Vector2(0,0)
	var ocupied  = false
	
	
	static func create(loc:Vector2):
		var ins = target.new()
		ins.position = loc
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
				targets.push_back(target.create(tile_position))
		
func Astart_path(pos,a1):
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
			
	for poss in agents_pos:
		astar_grid.set_point_solid(poss,false)	
	#return astar_grid.get_id_path(pos,pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_agent_arrived(pos: Variant) -> void:
	for tar in targets:
		if Vector2i(tar.position) == pos:
			tar.ocupied = true
			astar_grid.set_point_solid(tar.position)
			
