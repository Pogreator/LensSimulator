extends Node2D
class_name RayEmitter

@onready var rays: Node2D = $Rays
@onready var visual: Polygon2D = $Visual

@export var size := 100.0
	
@export var spawn_direction : Vector2 = Vector2(1.0,0.0)
@export var ray_amount : int = 4
@export var step : float = 1
@export var steps_per_tick : int = 10

var ray_directions : PackedVector2Array = []

const size_table := [Vector2(0.1,-0.5),Vector2(0.1,0.5),Vector2(-0.1,0.5),Vector2(-0.1,-0.5)]

func _ready() -> void:
	_resize(size)
	_spawn_rays()
	Global.simulation_reset.connect(_reset_rays)

func _process(_delta: float) -> void:
	if Global.simulation_state == Global.SimulationStates.Play:
		for i in range(steps_per_tick):
			_process_rays()

func _spawn_rays() -> void:
	for i in range(ray_amount):
		var ray_y = ((size/(ray_amount-1)) * i)-(size/2) # Get ray y position using offset and ray amount
		var ray = Line2D.new()
		rays.add_child(ray)
		ray.global_position = Vector2.ZERO # Put line to a known location, points move the ray
		ray.width = 2
		ray.add_point(global_position + Vector2(0.2*size/2, ray_y))
		ray_directions.append(spawn_direction)

func _process_rays() -> void:
	for i in range(len(rays.get_children())):
		var ray : Line2D = rays.get_child(i)
		var direction = ray_directions[i]
		var prev_point = ray.points[-1]
		var predicted = (Vector2(step,step)*direction)*1 + prev_point
		
		for k : SDFObject in Global.sdf_objects:
			var distance = k.sdf_distance(predicted)
			if distance < 0 and k.surface_type == k.SurfaceType.Mirror:
				var normal : Vector2 = k.estimate_normal(predicted)
				direction = direction.bounce(normal)
				if !direction.is_normalized(): direction = direction.normalized()
				
			elif distance < 0 and k.surface_type == k.SurfaceType.Glass:
				var distance_current = k.sdf_distance(prev_point)
				if distance_current > 0:
					var normal : Vector2 = k.estimate_normal(predicted)
					direction = _refraction(direction, normal, 1.0, k.refraction_index)
					
			elif distance > 0 and k.surface_type == k.SurfaceType.Glass:
				var distance_current = k.sdf_distance(prev_point)
				if distance_current < 0:
					var normal : Vector2 = k.estimate_normal(prev_point)
					direction = _refraction(direction, normal, k.refraction_index, 1.0)
		
		if direction != ray_directions[i] or len(ray.points) < 2:
			ray.add_point((Vector2(step,step)*direction) + prev_point)
			ray_directions[i] = direction
		else:
			ray.points[-1] = (Vector2(step,step)*direction) + prev_point

func _delete_rays() -> void:
	for i in rays.get_children():
		i.queue_free()
	ray_directions.clear()

func _reset_rays() -> void:
	_delete_rays()
	_spawn_rays()

func _resize(value : float) -> float:
	for i in range(len(visual.polygon)):
		visual.polygon[i] = size_table[i] * value
	return value

func _refraction(direction : Vector2, normal : Vector2, n1 : float, n2 : float) -> Vector2:
	var incident = direction.angle_to(-normal)
	var snell = asin((n1*sin(incident))/n2)
	print("%s : %s : %s : %s" % [rad_to_deg(direction.angle()), rad_to_deg(incident),rad_to_deg(snell), rad_to_deg(normal.angle())])
	return direction.rotated(snell)
