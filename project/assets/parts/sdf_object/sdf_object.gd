extends Node2D
class_name SDFObject

@onready var visual: ColorRect = $Visual

var surface_color = [
	Color(0.738, 0.769, 0.823, 1.0),
	Color(0.553, 0.667, 0.831, 0.482)
]

enum SurfaceType{
	Mirror,
	Glass
}

enum SDF{
	Circle,
	Box,
	Elipsoid,
	Concave
}

@export_category("Attributes")
@export var type : SDF
@export var surface_type : SurfaceType
@export var refraction_index := 1.0
@export_category("Size")
@export var radius = 50.0
@export var sdf_size = Vector2.ONE

var distance = INF
var line : Line2D = null
var debug = false

func _ready() -> void:
	visual.material = visual.material.duplicate()
	visual.material.set_shader_parameter("type",type)
	visual.material.set_shader_parameter("color",surface_color[surface_type])
	Global.sdf_objects.append(self)
	sdf_distance(Vector2.ZERO)
	if OS.is_debug_build() and debug:
		line = Line2D.new()
		add_child(line)
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2.ZERO)
		line.width = 2
		line.default_color = Color.RED

func _process(_delta: float) -> void:
	#rotate(0.01);
	if OS.is_debug_build() and debug:
		var dist = sdf_distance(get_global_mouse_position())
		var normal = estimate_normal(get_global_mouse_position())
		print("%s : %s" % [dist, normal])
		line.points[0] = Vector2(radius,radius) * normal
		line.points[1] = Vector2(radius*2,radius*2) * normal

func sdf_distance(pos : Vector2) -> float:
	match type:
		SDF.Circle: return _sdf_circle(pos)
		SDF.Box: return _sdf_box(pos)
		SDF.Elipsoid: return _sdf_elipsoid(pos)
		SDF.Concave: return _sdf_concave(pos)
		_: return 0

func _sdf_circle(pos : Vector2) -> float:
	pos = _rotate_sdf(pos-global_position)
	visual.size = Vector2(radius*2,radius*2)
	visual.position = -visual.size/2
	return abs((Vector2(pos).length())) - radius

func _sdf_box(pos : Vector2) -> float:
	pos = _rotate_sdf(pos-global_position)
	visual.size = sdf_size*2
	visual.position = Vector2(-sdf_size.x,-sdf_size.y)
	
	var d = abs(Vector2(pos)) - sdf_size
	var a = Vector2(max(d.x,0.0),max(d.y,0.0))
	return (a.length()) + min(max(d.x,d.y),0.0)

func _sdf_elipsoid(pos : Vector2) -> float:
	pos = _rotate_sdf(pos-global_position)
	visual.size = sdf_size*2
	visual.position = Vector2(-sdf_size.x,-sdf_size.y)
	
	var k1 = Vector2(pos.x/sdf_size.x,pos.y/sdf_size.y).length()
	return pos.length() * (1 - (1/k1))

func _sdf_concave(pos : Vector2) -> float:
	visual.size = sdf_size*2
	visual.position = Vector2(-sdf_size.x,-sdf_size.y)
	
	return max(-_sdf_elipsoid(pos-Vector2(0.5*sdf_size.x,0)),_sdf_elipsoid(pos))

func estimate_normal(pos : Vector2) -> Vector2:
	var normal = Vector2(sdf_distance(Vector2(pos.x + Global.epsilon, pos.y)) - sdf_distance(Vector2(pos.x - Global.epsilon, pos.y)), 
						 sdf_distance(Vector2(pos.x, pos.y + Global.epsilon)) - sdf_distance(Vector2(pos.x, pos.y - Global.epsilon))).normalized()
	return normal

func _smoooth_union(d1 : float, d2 : float, k : float):
	k*=4.0
	var h = max(k-abs(d1-d2),0)
	return min(d1,d2)-h*h*0.25/k

func _smooth_subtraction(d1 : float, d2 : float, k : float) -> float:
	return -_smoooth_union(d1,-d2,k)

func _translate_sdf(pos : Vector2, value :Vector2) -> Vector2:
	return pos + value

func _rotate_sdf(pos : Vector2) -> Vector2:
	var angle = Vector2(sin(rotation),cos(rotation))
	return Vector2(angle.y * pos.x + angle.x * pos.y, angle.y * pos.y - angle.x * pos.x)
