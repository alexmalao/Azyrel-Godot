extends CharacterBody2D

class_name PhysicsManController


var interact_box: Area2D

var props = PlayerProps
var move_data: PlayerMoveData
var player_input: PlayerInput

var _velocity: Vector2

@export var char_width: float = 100
@export var char_height: float = 200
@export var grace_pixel: float = 0.001
@onready var _sprite = $AnimatedSprite2D


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	self.interact_box = get_node("InteractBox")

	self.props = PlayerProps.new()
	self.move_data = PlayerMoveData.new()
	self.player_input = get_node("PlayerInput")
	self._velocity = Vector2(0, 0)

	# self.player_input.instant_jump_requested.connect(self.instant_jump)
	# self.player_input.jump_requested.connect(self.jump)
	# self.player_input.short_jump_requested.connect(self.short_jump)
	# self.player_input.dash_requested.connect(self.dash)
	self.player_input.interact_requested.connect(self.interact)


func _init():
	pass

func _physics_process(delta: float):
	self.update_position(delta)
	self.update_move(delta)
	self._update_state()


## Interact with area.
func interact():
	var areas: Array = self.interact_box.get_overlapping_areas()
	if areas.size() > 0:
		areas[0].get_parent().interact()


## Update the position of the player
func update_position(delta: float) -> void:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	# corner positions relative to character height and width
	var grace_offsets: Array[Vector2] = [
		Vector2(self.char_width / 2, 0),
		Vector2(-self.char_width / 2, 0),
		Vector2(self.char_width / 2, -self.char_height),
		Vector2(-self.char_width / 2, -self.char_height),
	]
	var corner_offsets: Array[Vector2] = [
		Vector2(self.char_width / 2 - self.grace_pixel, -self.grace_pixel),
		Vector2(-self.char_width / 2 + self.grace_pixel, -self.grace_pixel),
		Vector2(self.char_width / 2 - self.grace_pixel, -self.char_height + self.grace_pixel),
		Vector2(-self.char_width / 2 + self.grace_pixel, -self.char_height + self.grace_pixel),
	]

	var colliding: bool = true
	var delta_vel: Vector2 = self._velocity * delta
	while colliding:
		# use velocity raycasts for continuous collision detection
		colliding = false
		var idx: int = 0
		for offset in corner_offsets:
			var grace_offset: Vector2 = grace_offsets[idx]
			# store the new position to calculate leftover velocity
			var from_pos: Vector2 = Vector2(self.position.x + offset.x,
											self.position.y + offset.y)
			var to_pos: Vector2 = Vector2(self.position.x + offset.x + delta_vel.x,
										  self.position.y + offset.y + delta_vel.y)
			var query = PhysicsRayQueryParameters2D.create(
				from_pos, to_pos, 1)
			var result: Dictionary = space_state.intersect_ray(query)
			if result:
				self.position = Vector2(
					result.position.x - grace_offset.x,
					result.position.y - grace_offset.y,
				)
				colliding = true
				print(to_pos - result.position)
				print(result.normal.orthogonal())
				delta_vel = self.project_vectors(to_pos - result.position, result.normal.orthogonal())
			idx += 1

	self.position = Vector2(self.position.x + delta_vel.x,
							self.position.y + delta_vel.y)


## Move the player horizontally.
func update_move(delta: float):
	var move_input: Vector2 = self.player_input.get_directional_input()
	self._velocity = Vector2(
		self._velocity.x + move_input.x * delta * self.props.GROUND_ACCEL,
		self._velocity.y + move_input.y * delta * self.props.GROUND_ACCEL,
	)


## PRIVATE METHODS

## Update the character sprite
func _update_state() -> void:
	_sprite.flip_h = self.move_data.facing_right


## UTILITY METHODS

func project_vectors(a: Vector2, b: Vector2) -> Vector2:
	# projb a = ((a ⋅ b) / |b|²) * b
	var new_magnitude: float = a.dot(b) / pow(b.length(), 2)
	return new_magnitude * b
