extends TileMapLayer

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var tile_pos = local_to_map(mouse_pos)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("here?")
			#set_cell(0, tile_pos, 1, Vector2i(0, 0)) # Replace '1' with your tile ID
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			print("hello")
			#erase_cell(0, tile_pos) # Remove tile on right click
