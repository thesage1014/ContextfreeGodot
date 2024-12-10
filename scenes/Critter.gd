class_name Critter extends RigidBody3D
@export var bonusMesh:MeshInstance3D
@export var modelScene:Node3D
@export var meshAnim:AnimationPlayer
@export var meshMesh:MeshInstance3D
var blockGeneration = false
var generating = false
var fileReady = false
var filename = str(randi()) + ".png"
var thread:Thread
var queuedParams:Dictionary
var lastParams:Dictionary
var buddy:Critter
#offs = 15
#stroke = 1.5
#osc2 = .03
#hu = 90
#huc = .05
#dark = 0
func _ready() -> void:
	meshAnim.play("Swim")

func _process(delta: float) -> void:
	if generating:
		bonusMesh.scale = Vector3(.3,.3,1)
		bonusMesh.rotate_z(4)
	else:
		if queuedParams:
			if queuedParams != lastParams:
				var qptemp = queuedParams
				generate(qptemp)
			queuedParams = {}
	
	if fileReady:
		var image:Image = Image.load_from_file("./gen/" + filename)
		var imageTexture = ImageTexture.create_from_image(image)
		var mat = meshMesh.get_active_material(0) as StandardMaterial3D
		mat.albedo_texture = imageTexture
		generating = false
		fileReady = false
		thread.wait_to_finish()
		thread = null
		bonusMesh.visible = false

func _physics_process(_delta: float) -> void:
	apply_central_force(Vector3(randf()-.5,randf()-.5,randf()-.5))

func generate(params:Dictionary):
	if !blockGeneration:
		generating = true
		bonusMesh.visible = true
		if !thread:
			thread = Thread.new()
			lastParams.clear()
			lastParams.merge(params)
			thread.start(loadFile.bind(params))
		else:
			queuedParams = params

func loadFile(params:Dictionary):
	var offs = params["offs"]
	var stroke = params["stroke"]
	var osc2 = params["osc2"]
	var hu = params["hu"]
	var huc = params["huc"]
	var dark = params["dark"]
	var legs = params["legs"]
	var clparams = ["./bin/critters.cfdg","./gen/" + filename]
	for param in params:
		clparams.append("/D " + param + "=" + str(params[param]))
	var output = []
	var code = OS.execute("./bin/ContextFreeCLI.exe",clparams,output,true)
	#print(code)
	#print(output)
	fileReady = true

func _exit_tree():
	if thread:
		thread.wait_to_finish()


func _on_body_entered(body: Node) -> void:
	if !buddy and body is Critter:
		var possibleBuddy = body as Critter
		if !possibleBuddy.buddy:
			buddy = possibleBuddy
			buddy.buddy = self
			var joint = ConeTwistJoint3D.new()
			add_child(joint)
			joint.node_a = self.get_path()
			joint.node_b = buddy.get_path()
			#joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN,0)
			#joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN,0)
			#joint.set_param(ConeTwistJoint3D.PARAM_SOFTNESS,0)
			#joint.set_param(ConeTwistJoint3D.PARAM_BIAS,0)
			
