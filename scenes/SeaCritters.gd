extends Node3D
var starfishScene = preload("res://scenes/Starfish.tscn")
var fishes = []
@export var previewFish:Starfish
@export var sliders:Array[HSlider]
#offs = 15
#stroke = 1.5
#osc2 = .03
#hu = 90
#huc = .05
#dark = 0
var params:Dictionary = {
	"offs":15,
	"stroke":1.5,
	"osc2":.03,
	"hu":0,
	"huc":.05,
	"dark":0,
	"legs":5
}
func _ready() -> void:
	_update_preview()

func _process(delta: float) -> void:
	previewFish.rotate_z(delta*.15)

func _update_preview():
	for slider in sliders:
		params[slider.name] = slider.value
	previewFish.generate(params)

func _on_generate_button_pressed() -> void:
	var newFish = starfishScene.instantiate() as Starfish
	add_child(newFish)
	newFish.global_position = Vector3(6,6,0)
	newFish.apply_central_impulse(Vector3(-6,-6,0))
	if fishes.size()>35:
		fishes.pop_front().queue_free()
	fishes.append(newFish)
	newFish.generate(params)

func _on_slider_drag_ended(value_changed: bool) -> void:
	_update_preview()


func _on_randomize_button_pressed() -> void:
	for slider in sliders:
		slider.value = randf_range(slider.min_value, slider.max_value)
	_update_preview()


func _on_slider_value_changed(value: float) -> void:
	_update_preview()
