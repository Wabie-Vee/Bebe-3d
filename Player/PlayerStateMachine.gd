extends Node

const IdleState = preload("res://Player/States/IdleState.gd")
const RunState = preload("res://Player/States/RunState.gd")
const JumpState = preload("res://Player/States/JumpState.gd")
const FallState = preload("res://Player/States/FallState.gd")
const LockedState = preload("res://Player/States/LockedState.gd")
const CrouchState = preload("res://Player/States/CrouchState.gd")

var states = {}
var current_state = null
var player = null

func _init(_player):
	player = _player

func _ready():
	states = {
	"IdleState": IdleState.new(),
	"RunState": RunState.new(),
	"JumpState": JumpState.new(),
	"FallState": FallState.new(),
	"LockedState": LockedState.new(),
	"CrouchState": CrouchState.new()
	}
	set_state("IdleState")

func set_state(state_name: String):
	if current_state:
		current_state.exit(player)
	current_state = states[state_name]
	current_state.enter(player)
	#print("→ Entered state:", state_name)  # 👀


func _physics_process(delta):
	if current_state:
		current_state.physics_update(player, delta)

func _unhandled_input(event):
	if current_state:
		current_state.handle_input(player, event)
