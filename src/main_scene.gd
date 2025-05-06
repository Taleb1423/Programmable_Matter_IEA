extends Node2D
@onready var cFolder := $CreatureFolder
@onready var goals = [$Goal1, $Goal2, $Goal3, $Goal4, $Goal5, $Goal6, $Goal7, $Goal8, $Goal9, $Goal10, $Goal11,$Goal12]  # Multiple goals - update node paths to match your scene
@export var spawnAmt := 40
@export var eliteCount := 1  # Number of elite creatures per goal

func _ready() -> void:
	print("we are on gen: " + str(Global.generationNum))
	
	# Store goal positions for fitness calculations
	for i in goals.size():
		Global.goalPositions[i] = goals[i].global_position
	
	randomize()
	spawnFunc()

func spawnFunc() -> void:
	# Check if all goals have been reached
	if Global.are_all_goals_reached():
		print("All goals reached! Algorithm complete.")
		return
		
	if Global.generationNum > 0:  # Not the first generation
		var creaturesSpawned = 0
		
		# First, spawn elite creatures ONLY for goals that have been reached
		for goalIdx in Global.totalGoals:
			if Global.goalReachedDNAs[goalIdx] != null:
				# We have a DNA that reached this goal - spawn an elite
				for i in eliteCount:
					var creature := preload("res://src/creature/creature.tscn").instantiate()
					creature.position = Vector2(300, 300)
					creature.original = false
					creature.elite = true
					creature.targetGoalIndex = goalIdx
					creature.dnaSource = Global.goalReachedDNAs[goalIdx]
					cFolder.add_child(creature)
					creaturesSpawned += 1
		
		# Calculate population diversity based on generation
		var randomPercent = 0.3  # Start with 30% random creatures
		var progressivePercent = 0.7  # 70% using best DNA + mutation
		
		# Calculate counts
		var randomCount = floor(randomPercent * (spawnAmt - creaturesSpawned))
		var progressiveCount = spawnAmt - creaturesSpawned - randomCount
		
		# Spawn random creatures (pure exploration)
		for i in randomCount:
			var creature := preload("res://src/creature/creature.tscn").instantiate()
			creature.position = Vector2(300, 300)
			creature.original = true  # This makes it generate completely random genome
			creature.alive = true
			
			# Prioritize unfulfilled goals
			var unfulfilled_goals = []
			for g in Global.totalGoals:
				if not Global.goalsReached[g]:
					unfulfilled_goals.append(g)
			
			if unfulfilled_goals.size() > 0:
				creature.targetGoalIndex = unfulfilled_goals[randi() % unfulfilled_goals.size()]
			else:
				creature.targetGoalIndex = randi() % Global.totalGoals
			
			cFolder.add_child(creature)
			
		# Spawn progressive creatures (using best DNA with mutation)
		for i in progressiveCount:
			var creature := preload("res://src/creature/creature.tscn").instantiate()
			creature.position = Vector2(300, 300)
			creature.original = false
			creature.elite = false
			creature.useProgressiveDNA = true  # Flag to use best DNA with mutation
			
			# Prioritize unfulfilled goals
			var unfulfilled_goals = []
			for g in Global.totalGoals:
				if not Global.goalsReached[g]:
					unfulfilled_goals.append(g)
			
			if unfulfilled_goals.size() > 0:
				creature.targetGoalIndex = unfulfilled_goals[randi() % unfulfilled_goals.size()]
			else:
				creature.targetGoalIndex = randi() % Global.totalGoals
			
			cFolder.add_child(creature)
		
		# Activate all creatures
		for creature in cFolder.get_children():
			creature.alive = true
			creature.dead = false
	else:  # First generation
		# Generate completely random creatures
		for i in spawnAmt:
			var creature := preload("res://src/creature/creature.tscn").instantiate()
			creature.position = Vector2(300, 300)
			creature.original = true
			creature.alive = true
			
			# Assign to random goal
			creature.targetGoalIndex = randi() % Global.totalGoals
			
			cFolder.add_child(creature)

func _on_Timer_timeout() -> void:
	var deadAmt := 0.0
	for creature in cFolder.get_children():
		if creature.dead:
			deadAmt += 1
			
	if deadAmt == spawnAmt:
		# Update both goal-reaching DNAs and best fitness DNAs
		for goalIdx in Global.totalGoals:
			# Process goal-reaching creatures first
			for creature in cFolder.get_children():
				if creature.fittness == 0 and creature.targetGoalIndex == goalIdx:
					# This creature reached its goal!
					if not Global.goalsReached[goalIdx]:
						Global.goalsReached[goalIdx] = true
						print("Goal ", goalIdx, " has been reached!")
					
					# Update the reached DNA
					Global.goalReachedDNAs[goalIdx] = creature.genome.duplicate()
					print("Updated reached DNA for goal ", goalIdx)
					
			# If goal not reached yet, track best fitness DNA
			if not Global.goalsReached[goalIdx]:
				# Find the best creature for this goal
				var bestFitness = 10000000.0
				var bestCreature = null
				
				for creature in cFolder.get_children():
					if creature.targetGoalIndex == goalIdx and creature.fittness < bestFitness:
						bestFitness = creature.fittness
						bestCreature = creature
				
				# Update best DNA if we found a better one
				if bestCreature != null and bestFitness < Global.goalFitness[goalIdx]:
					Global.goalFitness[goalIdx] = bestFitness
					Global.goalDNAs[goalIdx] = bestCreature.genome.duplicate()
					print("Updated best DNA for goal ", goalIdx, " with fitness ", bestFitness)
		
		# Check if all goals are reached
		if Global.are_all_goals_reached():
			print("All goals have been reached! Algorithm complete.")
			return
			
		Global.generationNum += 1
		get_tree().reload_current_scene()

# Custom sort function
func sort_by_fitness(a, b):
	return a.fitness < b.fitness  # Lower fitness is better
