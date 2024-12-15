extends Node3D
const MAX_CRITTERS = 25
var meshScenes = [preload("res://scenes/Starfish.tscn"),preload("res://scenes/Octo.tscn")]
var fishes = []
var activePreview = 0
@export var previewFish:Array[Critter]
@export var tabs:TabContainer
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
	previewFish[activePreview].meshAnim.play("Wave2")
	

func _process(delta: float) -> void:
	previewFish[activePreview].rotate_y(delta*.15)

func _update_preview():
	for slider in tabs.get_current_tab_control().find_children("","Slider"):
		params[slider.name] = slider.value
	params["tab"] = tabs.current_tab
	previewFish[activePreview].generate(params)

func _on_generate_button_pressed() -> void:
	var newFish = meshScenes[tabs.current_tab].instantiate() as Critter
	add_child(newFish)
	newFish.global_position = Vector3(6,6,0)
	newFish.apply_central_impulse(Vector3(-6,-6,0))
	if fishes.size()>=MAX_CRITTERS:
		fishes.pop_front().despawn()
	fishes.append(newFish)
	newFish.generate(params)

func _on_slider_drag_ended(value_changed: bool) -> void:
	_update_preview()


func _on_randomize_button_pressed() -> void:
	previewFish[activePreview].blockGeneration = true
	for slider in tabs.get_current_tab_control().find_children("","Slider"):
		if slider.exp_edit:
			slider.value = slider.min_value + abs(randfn(0, (slider.max_value-slider.min_value)/60))
		else:
			slider.value = randf_range(slider.min_value, slider.max_value)
	previewFish[activePreview].blockGeneration = false
	_update_preview()


func _on_slider_value_changed(value: float) -> void:
	_update_preview()


func _on_tab_container_tab_changed(tab: int) -> void:
	if tab != tabs.get_tab_count()-1:
		previewFish[activePreview].visible = false
		previewFish[tab].visible = true
		activePreview = tab
		_update_preview()
	else:
		for fish in previewFish:
			fish.visible = false
