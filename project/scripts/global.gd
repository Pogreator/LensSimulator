extends Node

signal simulation_play
signal simulation_pause
signal simulation_reset

enum SimulationStates {
	Pause,
	Play
}

var simulation_state = SimulationStates.Pause
var debug = OS.is_debug_build()

var sdf_objects = []
var epsilon = 1

func _ready() -> void:
	simulation_play.connect(_simulation_play)
	simulation_pause.connect(_simulation_pause)
	simulation_reset.connect(_simulation_reset)

func _simulation_play() -> void:
	simulation_state = SimulationStates.Play
	if debug: print("Play")

func _simulation_pause() -> void:
	simulation_state = SimulationStates.Pause
	if debug: print("Pause")

func _simulation_reset() -> void:
	if debug: print("Reset Simulation")
