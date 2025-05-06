extends CharacterBody2D
@onready var tilemap= $"../Map"
@onready var max_agent_numb=$"..".agent_number
@onready var speed 
@onready var sprite_2d=$Sprite2D
@onready var get_speed=$"../speed"


var grid_size
var active_agents
var grid_position
var grid_size_y
var grid_size_x
var agent_pos
var map
var target_position
enum AgentState { PROPOSE, CHOOSE, WAIT, FOLLOW, LEADER, SCAN, EXPAND, ARRIVED }
var current_state = AgentState.PROPOSE
var leader_position =null
var leader_targets= 0
var leader_path =1000
var center
var agents_not_spoken
var agents_not_spoken2
var pout
var occupied_tragets= []
var agents = []
var agents_pos = []
var close_tars

var astar_grid


signal propose(center,targets,pos)

signal proclame(pos,path)

signal reached_center()

signal moved_to(new_pos)

signal arrived_at_goal(pos)


var is_moving = false



func _ready() -> void:
	map = tilemap.get_used_rect()
	grid_size = map.size
	grid_position = map.position
	grid_size_y = grid_size.y
	grid_size_x = grid_size.x
	
	agent_pos = tilemap.local_to_map(tilemap.to_local(global_position))
	active_agents = max_agent_numb
	agents_not_spoken = active_agents
	agents_not_spoken2 = active_agents
	
	agents = get_tree().get_nodes_in_group("agents")
	agents_pos = []
	
	speed = int(get_speed.text)
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region =tilemap.get_used_rect()
	astar_grid.cell_size =Vector2(32,32)
	astar_grid.diagonal_mode= AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	

func _process(delta: float) -> void:
	agent_pos = tilemap.local_to_map(tilemap.to_local(global_position))
	
	match current_state:
		
		AgentState.PROPOSE:
			
			var targets = get_visible_targets()
			var center = compute_center_of_mass(targets)
			print(agent_pos," :sending proposal")
			emit_signal("propose",center,targets.size(),agent_pos)
			
			current_state = AgentState.CHOOSE
			
		
		AgentState.CHOOSE:
			if agents_not_spoken == 0:
				agents_not_spoken = active_agents
				for ag in agents:
					if ag == self:
						continue
					agents_pos.append(tilemap.local_to_map(ag.global_position))
				for poss in agents_pos:
					astar_grid.set_point_solid(poss)	
	
				pout= astar_grid.get_id_path(agent_pos,center)
				print(agent_pos," :sending proclamation")
				emit_signal("proclame",agent_pos,pout.size())
				
				for poss in agents_pos:
					astar_grid.set_point_solid(poss,false)	
				
				
				current_state =AgentState.WAIT
				
		AgentState.WAIT:
			if agents_not_spoken2 == 0:
				agents_not_spoken2 = active_agents
				if leader_position == agent_pos:
					print(agent_pos,": I am the leader")
					current_state =AgentState.LEADER
				else:
					print(agent_pos,": I am a follower")
					current_state = AgentState.FOLLOW
			
				
			
		AgentState.FOLLOW:
			#velocity = get_blended_velocity(agent_pos, velocity, agents )
			is_moving = true
			
		
		AgentState.LEADER:
			if not is_moving:
				pout.pop_front()
				if pout.is_empty():
					emit_signal("reached_center")
				else:
					target_position = tilemap.map_to_local(pout[0])
					
					is_moving = true
				
				
		AgentState.SCAN:
			
			current_state = AgentState.EXPAND
			
		AgentState.EXPAND:
			close_tars = get_close_targets()
			for ag in agents:
					if ag == self:
						continue
					agents_pos.append(tilemap.local_to_map(ag.global_position))
			for poss in agents_pos:
					astar_grid.set_point_solid(poss)	
			
			pout = astar_grid.get_id_path(agent_pos,close_tars[0])
			
			for poss in agents_pos:
					astar_grid.set_point_solid(poss)	
			
			if not is_moving:
				
				
				if pout.is_empty():
					close_tars.pop_front()
				else:
					if pout.size()==1:
						emit_signal("arrived_at_goal",agent_pos)
						current_state = AgentState.ARRIVED
					
					else:
						target_position = tilemap.map_to_local(pout[1])
						is_moving = true
						
						
				
				
			
		AgentState.ARRIVED:
			pass

			
func get_visible_targets() -> Array:
	var visible_targets = []
	

	for y in range(grid_size_y):
		for x in range(grid_size_x):
			
			
			var tile_position=Vector2i(x+grid_position.x,y+grid_position.y)
			
			var tile_data = tilemap.get_cell_tile_data(tile_position)
			
			if tile_position == agent_pos:
				continue

			if tile_data.get_custom_data("target"):
				if is_not_obstructed(agent_pos, tile_position) and not occupied_tragets.has(tile_position):
					visible_targets.append(tile_position)
			
			else:
				if !tile_data.get_custom_data("Free"):
					astar_grid.set_point_solid(tile_position)
				else:
					if not is_not_obstructed(agent_pos,tile_position):
						astar_grid.set_point_solid(tile_position)

	
	


	return visible_targets
	
	
func get_close_targets() -> Array:
	var visible_targets = []
	var sorted_tars = []
	
	var rect = create_rect_centered_at_point(center,10,10)

	for y in range(grid_size_y):
		for x in range(grid_size_x):
				
			
			
			var tile_position=Vector2i(x+grid_position.x,y+grid_position.y)
			if tile_position == agent_pos:
				continue
			var tile_data = tilemap.get_cell_tile_data(tile_position)
			
			
			if rect.has_point(tile_position):
				if tile_data.get_custom_data("target"):
					if is_not_obstructed(agent_pos, tile_position) and not occupied_tragets.has(tile_position):
						visible_targets.append(tile_position)
				
			
				
			if !tile_data.get_custom_data("Free"):
				astar_grid.set_point_solid(tile_position)
			else:
				if not is_not_obstructed(agent_pos,tile_position):
					astar_grid.set_point_solid(tile_position)
	
	sorted_tars = expand_search(visible_targets)
	
	

	return sorted_tars


func create_rect_centered_at_point(center_point: Vector2i, width: int, height: int) -> Rect2i:
	# Calculate top-left position (origin point of the Rect2i)
	var top_left = Vector2i(center_point.x - width / 2,center_point.y - height / 2 )
	
	# Create and return the Rect2i
	return Rect2i(top_left, Vector2i(width, height))

func is_not_obstructed(from: Vector2i, to: Vector2i) -> bool:
	var points_on_line = get_bresenham_line(from, to)
	
	
	for point in points_on_line:
		var local_point = Vector2i(point.x+grid_position.x,point.y+grid_position.y)
		
		
		if point == to or point == from:
			continue  # don't block the target tile itself
		

		var data = tilemap.get_cell_tile_data(point)		
		
		if !data.get_custom_data("Free"):
			
			return false
			
	return true

func get_bresenham_line(start: Vector2i, end: Vector2i) -> Array:
	# Returns an array of Vector2i points that make up a line from start to end
	var points = []
	
	# Get the absolute differences and directions
	var dx = abs(end.x - start.x)
	var dy = abs(end.y - start.y)
	var sx = 1 if start.x < end.x else -1
	var sy = 1 if start.y < end.y else -1
	
	# Initialize error
	var err = dx - dy
	
	# Current position
	var x = start.x
	var y = start.y
	
	while true:
		# Add current point to the list
		points.append(Vector2i(x, y))
		
		# Check if we've reached the end point
		if x == end.x and y == end.y:
			break
		
		# Calculate error for next step
		var e2 = 2 * err
		
		# Step in x direction
		if e2 > -dy:
			err -= dy
			x += sx
		
		# Step in y direction
		if e2 < dx:
			err += dx
			y += sy
	
	return points
	
	
	
func compute_center_of_mass(positions: Array) -> Variant:
	if positions.is_empty():
		return null
	
	var sum = Vector2i(0, 0)
	for pos in positions:
		sum += pos
	
	var count = positions.size()
	var center = Vector2i(
		int(round(float(sum.x) / count)),
		int(round(float(sum.y) / count))
	)
	
	return center
	
func _on_propose(cent,targets,pos):
	if current_state == AgentState.ARRIVED:
		return
	print("recived from ",pos)
	agents_not_spoken -=1
	if cent == null:
		return
	if leader_targets < targets:
		center = cent
		leader_targets = targets
		
func _on_proclame(pos, path):
	if current_state == AgentState.ARRIVED:
		return
	agents_not_spoken2 -=1
	if path == null:
		return
	if path < leader_path:
		leader_path = path
		leader_position = pos


func _on_moved_to(vel):
	if current_state == AgentState.ARRIVED:
		return
	if current_state == AgentState.LEADER:
		return
	if current_state == AgentState.FOLLOW:
		velocity = vel

#func get_blended_velocity(self_pos: Vector2i, self_velocity: Vector2, neighbors: Array) -> Vector2:
	#if neighbors.is_empty():
		#return self_velocity  # keep moving in same direction
#
	#var alignment = get_average_velocity(neighbors)
	#var group_center = compute_center_of_mass(neighbors.map(func(n): return n.agent_pos))
	#var cohesion_direction = Vector2((group_center - self_pos))
#
	#var velocity = alignment + cohesion_direction * 0.5
	#return velocity.normalized() * self_velocity.length()
	#
#func get_average_velocity(neighbors: Array) -> Vector2:
	#if neighbors.is_empty():
		#return Vector2.ZERO
#
	#var total = Vector2.ZERO
	#for agent in neighbors:
		#total += agent.velocity
	#return total / neighbors.size()
	#
	#
	#
#func get_closest_neighbors(self_pos: Vector2, agents: Array) -> Array:
	#var sorted_agents = agents.duplicate()
	#var max_count = 3
	#if agents.size() < 3:
		#max_count = agents.size()
	#sorted_agents.sort_custom(func(a, b):
		#return self_pos.distance_squared_to(a.position) < self_pos.distance_squared_to(b.position)
	#)
#
	## Return up to `max_count` agents, excluding self
	#var neighbors = []
	#for agent in sorted_agents:
		#if agent.position == self_pos:
			#continue  # Skip self
		#neighbors.append(agent)
		#if neighbors.size() == max_count:
			#break
#
	#return neighbors
	#
	#
func _on_arrived_at_goal(pos):
	if current_state == AgentState.ARRIVED:
		return
	active_agents -=1
	print("i arrived ")
	occupied_tragets.push_back(pos)

func _on_reached_center():
	if current_state == AgentState.ARRIVED:
		return
	if current_state == AgentState.LEADER:
		var data = tilemap.get_cell_tile_data(agent_pos)
		if data.get_custom_data("target"):
			emit_signal("arrived_at_goal",agent_pos)
			current_state = AgentState.ARRIVED
		else:
			current_state = AgentState.SCAN
			
			
	else:
			current_state = AgentState.SCAN
			is_moving =false
			
			

func expand_search(targets: Array) -> Array:
	
	var sorted_targets = targets.duplicate()
	
   
	var center_weight = 0.6  # Higher weight for center
	var agent_weight = 0.4   # Lower weight for agent
	
	
	sorted_targets.sort_custom(func(pos_a , pos_b):
		# Determine the positions (targets might be objects with position property or direct Vector2)
		
		
		# Calculate Manhattan distances (better for tile maps than Euclidean)
		var a_center_dist = abs(pos_a.x - center.x) + abs(pos_a.y - center.y)
		var b_center_dist = abs(pos_b.x - center.x) + abs(pos_b.y - center.y)
		var a_agent_dist = abs(pos_a.x - agent_pos.x) + abs(pos_a.y - agent_pos.y)
		var b_agent_dist = abs(pos_b.x - agent_pos.x) + abs(pos_b.y - agent_pos.y)
		
		# Calculate weighted scores (lower score = better/closer)
		var a_score = a_center_dist * center_weight + a_agent_dist * agent_weight
		var b_score = b_center_dist * center_weight + b_agent_dist * agent_weight
		
		# Return true if a should come before b (lower score is better)
		return a_score < b_score)
	return sorted_targets
	
func _physics_process(delta: float) -> void:
	if is_moving:
		if current_state == AgentState.LEADER:
			var direction = (Vector2(target_position) - global_position).normalized()
			velocity = direction * speed
			emit_signal("moved_to",velocity)
			move_and_slide()
			# Check if agent reached target position
			if global_position.distance_to(target_position) < 1.0:
				global_position = target_position  # Snap to grid
				velocity = Vector2.ZERO
				emit_signal("moved_to",velocity)
				is_moving = false
				
		if current_state == AgentState.FOLLOW:		
			move_and_slide()
			
		if current_state==AgentState.EXPAND:
			
			var direction = (Vector2(target_position) - global_position).normalized()
			#breakpoint
			velocity = direction * speed
			
			move_and_slide()
			# Check if agent reached target position
			
			if global_position.distance_to(target_position) < 1:
				global_position = target_position  # Snap to grid
				velocity = Vector2.ZERO
				is_moving = false
				
	else:
		velocity= Vector2.ZERO
