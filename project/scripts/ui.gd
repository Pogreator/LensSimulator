extends Control

@onready var simulation_control_button: Button = $ControlsContainer/SimulationControl
@onready var simulation_reset_button: Button = $ControlsContainer/SimulationReset

func _on_simulation_control_pressed() -> void:
	match Global.simulation_state:
		Global.SimulationStates.Play: 
			Global.simulation_pause.emit()
			simulation_control_button.text = "Play"
		Global.SimulationStates.Pause: 
			Global.simulation_play.emit()
			simulation_control_button.text = "Pause"

func _on_simulation_reset_pressed() -> void:
	Global.simulation_reset.emit()
