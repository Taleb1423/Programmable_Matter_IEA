extends Area2D
var original := false
var dead := false
var alive := false
var elite := false  # Flag to mark elite creatures
var dnaSource = null  # DNA to use as source (either best DNA or goal-specific DNA)
var speed := 20
var genome := []
var spotInGenome := 0
var fittness := 0.0
var targetGoalIndex := 0  # Which goal this creature is targeting
var goals = []  # References to all goals
var genomeSize := 50
var mutAmt := 0.4
var useProgressiveDNA := false  # Flag to indicate if this creature should use best fitness DNA

func _ready() -> void:
	for i in genomeSize:
		genome.append(Vector2.ZERO)
	
	randomize()
	
	# Get references to all goals
	var mainScene = get_parent().get_parent()
	for i in Global.totalGoals:
		var goalName = "Goal" + str(i + 1)
		if mainScene.has_node(goalName):
			goals.append(mainScene.get_node(goalName))
		else:
			push_error("Goal not found: " + goalName)
	1
	# Calculate adaptive mutation rate - higher for later generations but with a minimum
	mutAmt = max(0.3 - (Global.generationNum * 0.01), 0.1)
	
	# Initialize genome
	if original:
		# Generate completely random genome
		for i in genomeSize:
			var v := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed
			genome[i] = v
	elif elite and dnaSource != null:
		# Elite creatures exactly copy the DNA that reached the goal
		for i in genomeSize:
			genome[i] = dnaSource[i]
	elif useProgressiveDNA and Global.goalDNAs[targetGoalIndex] != null:
		# Use the best DNA for this goal with mutation
		for i in genomeSize:
			if randf() < mutAmt:
				# Apply mutation - sometimes small adjustments, sometimes bigger changes
				if randf() < 0.5:
					# Small adjustment to existing direction
					var v = Global.goalDNAs[targetGoalIndex][i]
					var variation = Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
					genome[i] = (v + variation).normalized() * speed
				else:
					# Completely new direction
					var v := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed
					genome[i] = v
			else:
				genome[i] = Global.goalDNAs[targetGoalIndex][i]
	else:
		# Generate random genome
		for i in genomeSize:
			var v := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed
			genome[i] = v

func _physics_process(delta: float) -> void:
	if alive:
		if !dead and spotInGenome < genome.size():
			global_position += genome[spotInGenome]
		else:
			die()

func die() -> void:
	dead = true
	
	# Calculate fitness based on the distance to the targeted goal
	var targetGoal = goals[targetGoalIndex]
	fittness = global_position.distance_squared_to(targetGoal.global_position)
	
func _on_creature_body_entered(body: Node) -> void:
	if body:
		dead = true
 
func _on_Timer_timeout() -> void:
	if alive:
		spotInGenome += 1
	else:
		dead = true

func _on_goal_area_entered(area: Area2D) -> void:
	# Check if we entered any goal
	if area.is_in_group("goal"):
		# Get the goal index
		for i in goals.size():
			if area == goals[i]:
				# We reached a goal!
				var reachedGoalIndex = i
				
				# Save this DNA as a goal-reaching DNA
				Global.goalReachedDNAs[reachedGoalIndex] = genome.duplicate()
				Global.goalsReached[reachedGoalIndex] = true
				print("Goal ", reachedGoalIndex, " has been reached!")
				
				# We don't need to track fitness for this goal anymore
				# since we actually reached it
				fittness = 0  # Perfect fitness
				
				die()
				break
