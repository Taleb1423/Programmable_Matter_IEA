extends Node2D

@onready var tile_map : TileMapLayer = $Map

enum PlacementType { NONE, TARGET, OBSTACLE }
var current_placement_type = PlacementType.NONE

func _ready():
	# Connect the button signals
	$Target_Button.pressed.connect(_on_target_button_pressed)
	$Obstacle_Button.pressed.connect(_on_obstacle_button_pressed)
	
func _input(event):
	if Input.is_action_just_pressed("click") and current_placement_type != PlacementType.NONE:
		print("Click")
		var mouse_pos = get_global_mouse_position()
		print("global mouse pos: ", mouse_pos)
		var tile_pos = tile_map.local_to_map(mouse_pos)
		
		# Place the appropriate tile based on the current selection
		if current_placement_type == PlacementType.TARGET:
			place_target(tile_pos)
		elif current_placement_type == PlacementType.OBSTACLE:
			place_obstacle(tile_pos)
			
	if Input.is_action_just_pressed("right_click"):
		var mouse_pos = get_global_mouse_position()
		var tile_pos = tile_map.local_to_map(mouse_pos)
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
	
	tile_map.set_cell(tile_pos, source_id, atlas_coordt)
	print("Target placed at:", tile_pos)

func place_obstacle(tile_pos: Vector2i) -> void:
	var source_id = 0
	var atlas_coordo = Vector2i(3, 6)
	
	tile_map.set_cell(tile_pos, source_id, atlas_coordo)
	print("Obstacle placed at:", tile_pos)
	
func remove_tile(tile_pos: Vector2i) -> void:
	var existing_tile = tile_map.get_cell_tile_data(tile_pos)
	if existing_tile != null:
		var source_id = 0
		var atlas_coordf = Vector2i(3, 4)
		#tile_map.set_cell(tile_pos, -1)  # Remove the tile
		tile_map.set_cell(tile_pos, source_id, atlas_coordf)
		print("Tile removed at:", tile_pos)
