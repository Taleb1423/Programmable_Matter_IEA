extends Node
# Original variables (kept for backward compatibility)
var bestDNA = null  
var bestFit :float= 10000000.0
var generationNum := 0
# New variables for multi-goal tracking
var goalDNAs = []  # Best DNA by fitness for each goal
var goalFitness = []  # Best fitness for each goal
var goalsReached = []  # Boolean array to track which goals have been reached
var goalPositions = []  # Positions of each goal
var totalGoals := 12  # Total number of goals in the scene - CHANGE THIS TO MATCH YOUR SETUP
var goalReachedDNAs = []  # Only store DNAs that actually reached goals

func _ready():
	# Initialize arrays
	for i in totalGoals:
		goalDNAs.append(null)
		goalFitness.append(10000000.0)
		goalsReached.append(false)
		goalPositions.append(Vector2.ZERO)
		goalReachedDNAs.append(null)
		
func are_all_goals_reached() -> bool:
	for reached in goalsReached:
		if not reached:
			return false
	return true
