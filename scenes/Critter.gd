class_name Critter extends RigidBody3D
@export var emojis:String
@export var bonusMesh:MeshInstance3D
@export var modelScene:Node3D
@export var meshAnim:AnimationPlayer
@export var meshMesh:MeshInstance3D
@export var light:OmniLight3D
@export var headPos:Node3D
@export var originPos:Node3D
@export var chatLabel:Label3D
var blockGeneration = false
var generating = false
var fileReady = false
var filename = str(randi()) + ".png"
var thread:Thread
var queuedParams:Dictionary
var lastParams:Dictionary
var buddy:Critter
var timeGotBuddy = 0
var minInteractionTime = 4500
var askingQuestion = false
var timeQuestionAsked = 0
var paramInQuestion = ""
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
		
	if buddy:
		if !askingQuestion and !buddy.askingQuestion:
			askingQuestion = true
			paramInQuestion = lastParams.keys().slice(0,lastParams.size()-2).pick_random()
			buddy.paramInQuestion = paramInQuestion
			timeQuestionAsked = Time.get_ticks_msec()
			chatLabel.text = emojis[lastParams.keys().find(paramInQuestion)]
			chatLabel.modulate = Color(0,0,0,0)
			chatLabel.outline_modulate = Color(0,0,0,0)
			buddy.chatLabel.modulate = Color(0,0,0,0)
			buddy.chatLabel.outline_modulate = Color(0,0,0,0)
			buddy.chatLabel.text = emojis[lastParams.keys().find(paramInQuestion)]
			
	if askingQuestion:
		var questionAge = Time.get_ticks_msec()-timeQuestionAsked
		var fade = smoothstep(0,1000,questionAge-1000)
		chatLabel.modulate = Color(Color.WHITE,fade)
		chatLabel.outline_modulate =  Color(Color.BLACK,fade)
		if fade == 1 and !buddy.askingQuestion:
			buddy.askingQuestion = true
			buddy.timeQuestionAsked = Time.get_ticks_msec()-500
		if questionAge >= 3000:
			pass

func _physics_process(_delta: float) -> void:
	apply_central_force(Vector3(randf()-.5,randf()-.5,randf()-.5)*3)
	if buddy:
		apply_central_force((buddy.headPos.global_position-headPos.global_position)*2)#,headPos.global_position)
		originPos.look_at(buddy.position)
		apply_torque((originPos.rotation_degrees)*.02)
		angular_damp = 10
		if randf()<.002:
			breakAwayFromBuddy()

		

func generate(params:Dictionary):
	if !blockGeneration:
		if light and params.has("hu"):
			light.light_color = Color.from_hsv(params["hu"]/360.0,1,1)
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
	fileReady = true






func _on_body_entered(body: Node) -> void:
	if !is_queued_for_deletion() and !buddy and body is Critter:
		var possibleBuddy = body as Critter
		if !possibleBuddy.buddy:
			buddy = possibleBuddy
			buddy.buddy = self
			timeGotBuddy = Time.get_ticks_msec()
			buddy.timeGotBuddy = Time.get_ticks_msec()
			#var joint = ConeTwistJoint3D.new()
			#add_child(joint)
			#joint.node_a = self.get_path()
			#joint.node_b = buddy.get_path()
			meshAnim.clear_queue()
			meshAnim.stop(true)
			meshAnim.play("Shake")
			meshAnim.queue("Swim")
			buddy.meshAnim.clear_queue()
			buddy.meshAnim.stop(true)
			buddy.meshAnim.play("Shake")
			buddy.meshAnim.queue("Swim")
			#joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN,0)
			#joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN,0)
			#joint.set_param(ConeTwistJoint3D.PARAM_SOFTNESS,0)
			#joint.set_param(ConeTwistJoint3D.PARAM_BIAS,0)
			
func breakAwayFromBuddy(override=false):
	if buddy:
		if override or Time.get_ticks_msec()-timeGotBuddy > minInteractionTime:
			var pushForce = 2
			if askingQuestion and buddy.askingQuestion:
				var p1 = lastParams[paramInQuestion]
				var p2 = buddy.lastParams[paramInQuestion]
				var pmin = Singleton.paramRanges[paramInQuestion][0]
				var pmax = Singleton.paramRanges[paramInQuestion][1]
				var dist = smoothstep(pmin,pmax,abs(p1-p2))
				#print(dist)
				pushForce = 10*dist
			apply_central_impulse((global_position-headPos.global_position)*pushForce)
			buddy.apply_central_impulse((global_position-headPos.global_position)*-pushForce)
			askingQuestion = false
			chatLabel.text = ""
			buddy.askingQuestion = false
			buddy.chatLabel.text = ""
			buddy.buddy = null
			buddy = null

func despawn():
	breakAwayFromBuddy(true)
	queue_free()

func _exit_tree():
	if thread:
		thread.wait_to_finish()
