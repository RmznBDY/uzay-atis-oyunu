extends Node2D

const SCREEN_WIDTH = 480
const SCREEN_HEIGHT = 720
const PLAYER_SPEED = 300.0
const BULLET_SPEED = 600.0
const ENEMY_SPEED = 150.0
const SPAWN_INTERVAL = 1.2
const ANIMAL_EMOJIS = [
	"🐱", "🐶", "🦊", "🐰", "🐻", "🐼", "🐨", "🐯",
	"🦁", "🐮", "🐷", "🐸", "🐵", "🐔", "🐧", "🐦",
	"🐤", "🐹", "🐭", "🐢", "🐠", "🐳", "🦋", "🐝",
]
const ANIMAL_LIFETIME = 1.6
const ANIMAL_FALL_DISTANCE = 140.0
const PLAYER_MAX_LIVES = 3
const INVULNERABILITY_TIME = 1.5
const STAR_COUNT = 70
const EXPLOSION_PARTICLES = 14
const AUTOFIRE_INTERVAL = 0.18
const TOUCH_FOLLOW_SPEED = 800.0
const PHOTO_DIR = "res://foto"
const PHOTO_DISPLAY_SIZE = 56.0
const DEFAULT_ENEMY_SCORE = 10
const PHOTO_SCORES = {
	"Adsız.png": 100,
	"Adsız2.png": 250,
	"Adsız3.png": 1000,
	"Adsız4.png": 400,
	"Adsız5.png": 400,
	"Adsız6.png": 150,
	"Adsız7.png": 300,
	"Adsız8.png": 500,
	"Adsız9.png": 200,
}
const ENEMY_PHOTO_SIZE = 60.0
const PHOTO_WEIGHTS = {
	"Adsız3.png": 2,
}
const LIFE_BONUS_PHOTO = "Adsız3.png"
const PLAYER_MIN_Y = 220.0
const PLAYER_MAX_Y = SCREEN_HEIGHT - 30.0

const DIFFICULTY_INTERVAL = 15.0
const DIFFICULTY_SPEED_GROWTH = 0.15
const DIFFICULTY_SIZE_GROWTH = 0.10

const SCORE_PER_BULLET = 10000
const MAX_BULLET_COUNT = 7
const BULLET_SPACING = 10.0

const ALIEN_SPAWN_CHANCE = 0.35
const ALIEN_SCORES = [60, 80, 120]

const PLANET_SIZE_PER_STEP = 10000
const PLANET_LEVEL_INTERVAL = 100000
const PLANET_BASE_RADIUS = 28.0
const PLANET_GROWTH_PER_STEP = 14.0
const PLANET_PALETTES = [
	{"main": Color(0.20, 0.55, 0.95), "spot": Color(0.30, 0.75, 0.35), "has_ring": false},
	{"main": Color(0.88, 0.38, 0.18), "spot": Color(0.55, 0.22, 0.12), "has_ring": false},
	{"main": Color(0.96, 0.85, 0.45), "spot": Color(0.78, 0.62, 0.30), "has_ring": true},
	{"main": Color(0.25, 0.40, 0.85), "spot": Color(0.55, 0.70, 1.00), "has_ring": false},
	{"main": Color(0.62, 0.30, 0.82), "spot": Color(0.40, 0.15, 0.60), "has_ring": true},
	{"main": Color(0.92, 0.42, 0.12), "spot": Color(1.00, 0.85, 0.22), "has_ring": false},
	{"main": Color(0.80, 0.96, 1.00), "spot": Color(0.55, 0.80, 0.95), "has_ring": false},
]

const ENEMY_TYPES = [
	{"name": "normal", "speed": 1.0, "size": 1.0, "score_mult": 1.0, "weight": 4},
	{"name": "swift", "speed": 1.7, "size": 0.7, "score_mult": 1.5, "weight": 2},
	{"name": "zigzag", "speed": 0.95, "size": 1.0, "score_mult": 1.2, "weight": 2},
	{"name": "tank", "speed": 0.55, "size": 1.5, "score_mult": 2.0, "weight": 1},
]
const ZIGZAG_FREQ = 2.5
const ENEMY_HIT_RADIUS = 22.0
const PLAYER_HIT_RADIUS = 25.0

var player: Node2D
var engine_glow: Polygon2D
var score_label: Label
var lives_label: Label
var bullets: Array = []
var enemies: Array = []
var stars: Array = []
var score: int = 0
var lives: int = PLAYER_MAX_LIVES
var spawn_timer: float = 0.0
var invulnerability_timer: float = 0.0
var game_over: bool = false
var game_over_label: Label = null
var emoji_font: Font
var touch_active: bool = false
var touch_x: float = 0.0
var touch_y: float = 0.0
var autofire_timer: float = 0.0
var photos: Array = []
var game_time: float = 0.0
var difficulty_level: int = 0
var enemy_speed_mult: float = 1.0
var enemy_size_mult: float = 1.0
var enemy_type_pool: Array = []
var level_label: Label = null
var photo_round_material: ShaderMaterial = null
var planet_node: Node2D = null
var planet_level: int = -1
var planet_step: int = -1
var bullet_count_label: Label = null


func _ready() -> void:
	emoji_font = load("res://assets/Twemoji.Mozilla.ttf")
	_load_photo_textures()
	_build_enemy_type_pool()
	_setup_photo_round_material()

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.15)
	bg.size = Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	add_child(bg)

	_setup_planet()
	_spawn_stars()

	player = Node2D.new()
	player.position = Vector2(SCREEN_WIDTH / 2.0, SCREEN_HEIGHT - 60)
	add_child(player)
	_build_player_ship(player)

	score_label = Label.new()
	score_label.text = "Skor: 0"
	score_label.position = Vector2(10, 10)
	score_label.add_theme_font_size_override("font_size", 22)
	add_child(score_label)

	lives_label = Label.new()
	lives_label.add_theme_font_override("font", emoji_font)
	lives_label.add_theme_font_size_override("font_size", 22)
	lives_label.position = Vector2(SCREEN_WIDTH - 130, 8)
	lives_label.size = Vector2(120, 30)
	lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(lives_label)
	_update_lives_display()

	level_label = Label.new()
	level_label.text = "Sev 1"
	level_label.position = Vector2(10, 36)
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	add_child(level_label)

	bullet_count_label = Label.new()
	bullet_count_label.position = Vector2(10, 58)
	bullet_count_label.add_theme_font_size_override("font_size", 14)
	bullet_count_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	add_child(bullet_count_label)
	_update_bullet_count_label()
	_update_planet()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		touch_active = event.pressed
		if event.pressed:
			touch_x = event.position.x
			touch_y = event.position.y
			if game_over:
				get_tree().reload_current_scene()
	elif event is InputEventScreenDrag:
		touch_x = event.position.x
		touch_y = event.position.y


func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return

	game_time += delta
	var new_level: int = int(game_time / DIFFICULTY_INTERVAL)
	if new_level != difficulty_level:
		difficulty_level = new_level
		enemy_speed_mult = 1.0 + difficulty_level * DIFFICULTY_SPEED_GROWTH
		enemy_size_mult = 1.0 + difficulty_level * DIFFICULTY_SIZE_GROWTH
		_update_level_label()

	var input_x := 0.0
	var input_y := 0.0
	if Input.is_action_pressed("ui_left"):
		input_x -= 1.0
	if Input.is_action_pressed("ui_right"):
		input_x += 1.0
	if Input.is_action_pressed("ui_up"):
		input_y -= 1.0
	if Input.is_action_pressed("ui_down"):
		input_y += 1.0

	if touch_active:
		var target_x: float = clamp(touch_x, 28.0, SCREEN_WIDTH - 28.0)
		var target_y: float = clamp(touch_y, PLAYER_MIN_Y, PLAYER_MAX_Y)
		player.position.x = move_toward(player.position.x, target_x, TOUCH_FOLLOW_SPEED * delta)
		player.position.y = move_toward(player.position.y, target_y, TOUCH_FOLLOW_SPEED * delta)
	else:
		player.position.x = clamp(
			player.position.x + input_x * PLAYER_SPEED * delta,
			28.0,
			SCREEN_WIDTH - 28.0,
		)
		player.position.y = clamp(
			player.position.y + input_y * PLAYER_SPEED * delta,
			PLAYER_MIN_Y,
			PLAYER_MAX_Y,
		)

	if engine_glow:
		var pulse := 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.012)
		engine_glow.modulate.a = pulse
		engine_glow.scale.y = 0.85 + 0.25 * sin(Time.get_ticks_msec() * 0.012)

	for entry in stars:
		var s: ColorRect = entry["node"]
		s.position.y += entry["speed"] * delta
		if s.position.y > SCREEN_HEIGHT:
			s.position.y = -2.0
			s.position.x = randf_range(0.0, SCREEN_WIDTH)

	if invulnerability_timer > 0.0:
		invulnerability_timer -= delta
		player.modulate.a = 0.35 if int(invulnerability_timer * 10.0) % 2 == 0 else 1.0
		if invulnerability_timer <= 0.0:
			player.modulate.a = 1.0

	if Input.is_action_just_pressed("ui_accept"):
		_spawn_bullet()
		autofire_timer = AUTOFIRE_INTERVAL

	if touch_active:
		autofire_timer -= delta
		if autofire_timer <= 0.0:
			_spawn_bullet()
			autofire_timer = AUTOFIRE_INTERVAL
	else:
		autofire_timer = 0.0

	for i in range(bullets.size() - 1, -1, -1):
		var bullet: ColorRect = bullets[i]
		bullet.position.y -= BULLET_SPEED * delta
		if bullet.position.y < -20.0:
			bullet.queue_free()
			bullets.remove_at(i)

	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		_spawn_enemy()

	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Node2D = enemies[i]
		var base_speed: float = enemy.get_meta("base_speed", ENEMY_SPEED)
		var size_factor: float = enemy.get_meta("size_factor", 1.0)
		enemy.position.y += base_speed * enemy_speed_mult * delta

		if enemy.get_meta("enemy_type", "normal") == "zigzag":
			var base_x: float = enemy.get_meta("base_x", enemy.position.x)
			var phase: float = enemy.get_meta("zigzag_phase", 0.0)
			var amp: float = enemy.get_meta("zigzag_amp", 80.0)
			enemy.position.x = clamp(base_x + sin(game_time * ZIGZAG_FREQ + phase) * amp, 20.0, SCREEN_WIDTH - 20.0)

		var effective_scale: float = size_factor * enemy_size_mult
		enemy.scale = Vector2(effective_scale, effective_scale)
		var enemy_radius: float = ENEMY_HIT_RADIUS * effective_scale

		var enemy_hit := false
		for j in range(bullets.size() - 1, -1, -1):
			var bullet: ColorRect = bullets[j]
			if enemy.position.distance_to(bullet.position) < enemy_radius:
				bullet.queue_free()
				bullets.remove_at(j)
				enemy_hit = true
				break

		if enemy_hit:
			_spawn_explosion(enemy.position, Color(1.0, 0.5, 0.0))
			var stored_score: int = enemy.get_meta("score", DEFAULT_ENEMY_SCORE)
			var stored_tex = enemy.get_meta("photo_texture", null)
			var is_life_bonus: bool = enemy.get_meta("is_life_bonus", false)
			_spawn_trophy(enemy.position, stored_tex)
			_spawn_score_popup(enemy.position, stored_score)
			if is_life_bonus:
				lives += 1
				_update_lives_display()
				_spawn_life_popup(enemy.position)
			enemy.queue_free()
			enemies.remove_at(i)
			score += stored_score
			score_label.text = "Skor: %d" % score
			_update_bullet_count_label()
			_update_planet()
			continue

		if enemy.position.y > SCREEN_HEIGHT + 20.0:
			enemy.queue_free()
			enemies.remove_at(i)
		elif enemy.position.distance_to(player.position) < (PLAYER_HIT_RADIUS * effective_scale * 0.5 + PLAYER_HIT_RADIUS * 0.5):
			if invulnerability_timer > 0.0:
				_spawn_explosion(enemy.position, Color(1.0, 0.5, 0.0))
				enemy.queue_free()
				enemies.remove_at(i)
				continue
			_spawn_explosion(player.position, Color(1.0, 0.3, 0.2))
			enemy.queue_free()
			enemies.remove_at(i)
			_take_damage()
			if lives <= 0:
				_trigger_game_over()
				return


func _spawn_bullet() -> void:
	var count: int = _current_bullet_count()
	var start_offset: float = -(count - 1) * BULLET_SPACING / 2.0
	for i in range(count):
		var bullet := ColorRect.new()
		bullet.color = Color.YELLOW
		bullet.size = Vector2(4, 12)
		bullet.position = player.position + Vector2(-2 + start_offset + i * BULLET_SPACING, -30)
		add_child(bullet)
		bullets.append(bullet)


func _current_bullet_count() -> int:
	return min(1 + score / SCORE_PER_BULLET, MAX_BULLET_COUNT)


func _update_bullet_count_label() -> void:
	if bullet_count_label == null:
		return
	var c: int = _current_bullet_count()
	bullet_count_label.text = "Mermi: %d'li" % c


func _build_player_ship(parent: Node2D) -> void:
	engine_glow = Polygon2D.new()
	engine_glow.polygon = PackedVector2Array([
		Vector2(-7, 14),
		Vector2(7, 14),
		Vector2(5, 24),
		Vector2(0, 32),
		Vector2(-5, 24),
	])
	engine_glow.color = Color(1.0, 0.55, 0.0)
	parent.add_child(engine_glow)

	var left_wing := Polygon2D.new()
	left_wing.polygon = PackedVector2Array([
		Vector2(-26, 12),
		Vector2(-9, -2),
		Vector2(-8, 16),
		Vector2(-22, 20),
	])
	left_wing.color = Color(0.1, 0.55, 0.85)
	parent.add_child(left_wing)

	var right_wing := Polygon2D.new()
	right_wing.polygon = PackedVector2Array([
		Vector2(26, 12),
		Vector2(9, -2),
		Vector2(8, 16),
		Vector2(22, 20),
	])
	right_wing.color = Color(0.1, 0.55, 0.85)
	parent.add_child(right_wing)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -28),
		Vector2(-9, -8),
		Vector2(-10, 16),
		Vector2(10, 16),
		Vector2(9, -8),
	])
	body.color = Color(0.88, 0.92, 0.96)
	parent.add_child(body)

	var body_stripe := Polygon2D.new()
	body_stripe.polygon = PackedVector2Array([
		Vector2(-2, -22),
		Vector2(2, -22),
		Vector2(3, 16),
		Vector2(-3, 16),
	])
	body_stripe.color = Color(0.95, 0.25, 0.25)
	parent.add_child(body_stripe)

	var cockpit := Polygon2D.new()
	cockpit.polygon = PackedVector2Array([
		Vector2(0, -16),
		Vector2(-5, -6),
		Vector2(-5, 4),
		Vector2(5, 4),
		Vector2(5, -6),
	])
	cockpit.color = Color(0.35, 0.75, 1.0)
	parent.add_child(cockpit)

	var cockpit_highlight := Polygon2D.new()
	cockpit_highlight.polygon = PackedVector2Array([
		Vector2(-3, -12),
		Vector2(-1, -12),
		Vector2(-2, -4),
		Vector2(-4, -4),
	])
	cockpit_highlight.color = Color(1.0, 1.0, 1.0, 0.7)
	parent.add_child(cockpit_highlight)


func _spawn_enemy() -> void:
	var enemy := Node2D.new()
	enemy.set_meta("score", DEFAULT_ENEMY_SCORE)
	enemy.set_meta("photo_texture", null)
	enemy.set_meta("is_life_bonus", false)

	var etype: Dictionary = _pick_enemy_type()
	var type_name: String = etype["name"]
	var base_score: int = DEFAULT_ENEMY_SCORE

	var use_alien: bool = randf() < ALIEN_SPAWN_CHANCE or photos.size() == 0
	if not use_alien and photos.size() > 0:
		var picked: Dictionary = photos[randi() % photos.size()]
		var tex: Texture2D = picked["texture"]
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.material = photo_round_material
		var tex_size := tex.get_size()
		var max_dim: float = max(tex_size.x, tex_size.y)
		var fit_scale: float = ENEMY_PHOTO_SIZE / max_dim
		sprite.scale = Vector2(fit_scale, fit_scale)
		enemy.add_child(sprite)
		base_score = picked["score"]
		enemy.set_meta("photo_texture", tex)
		if (picked["name"] as String) == LIFE_BONUS_PHOTO:
			enemy.set_meta("is_life_bonus", true)
	else:
		var alien_kind: int = randi() % 3
		var alien_visual: Node2D = _make_alien_visual(alien_kind)
		enemy.add_child(alien_visual)
		base_score = ALIEN_SCORES[alien_kind]

	var final_score: int = int(round(base_score * (etype["score_mult"] as float)))
	enemy.set_meta("score", final_score)
	enemy.set_meta("enemy_type", type_name)
	enemy.set_meta("base_speed", ENEMY_SPEED * (etype["speed"] as float))
	enemy.set_meta("size_factor", etype["size"] as float)

	var spawn_x: float = randf_range(30.0, SCREEN_WIDTH - 30.0)
	enemy.position = Vector2(spawn_x, -20.0)

	if type_name == "zigzag":
		enemy.set_meta("base_x", spawn_x)
		enemy.set_meta("zigzag_phase", randf() * TAU)
		enemy.set_meta("zigzag_amp", randf_range(70.0, 110.0))

	var effective_scale: float = (etype["size"] as float) * enemy_size_mult
	enemy.scale = Vector2(effective_scale, effective_scale)
	if type_name == "tank":
		enemy.modulate = Color(1.0, 0.85, 0.85)
	elif type_name == "swift":
		enemy.modulate = Color(1.0, 1.0, 0.75)

	add_child(enemy)
	enemies.append(enemy)


func _make_alien_visual(kind: int) -> Node2D:
	match kind:
		0:
			return _make_ufo()
		1:
			return _make_classic_alien()
		_:
			return _make_octopus_alien()


func _make_ufo() -> Node2D:
	var holder := Node2D.new()
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-26, 4), Vector2(-16, -2), Vector2(16, -2), Vector2(26, 4),
		Vector2(16, 11), Vector2(-16, 11),
	])
	body.color = Color(0.72, 0.72, 0.78)
	holder.add_child(body)
	var dome := Polygon2D.new()
	dome.polygon = PackedVector2Array([
		Vector2(-11, -2), Vector2(-8, -13), Vector2(8, -13), Vector2(11, -2),
	])
	dome.color = Color(0.45, 0.85, 1.0, 0.9)
	holder.add_child(dome)
	for x in [-16, -6, 6, 16]:
		var light := Polygon2D.new()
		light.polygon = PackedVector2Array([
			Vector2(x - 2.5, 9), Vector2(x + 2.5, 9),
			Vector2(x + 2.5, 14), Vector2(x - 2.5, 14),
		])
		light.color = Color(1.0, 0.9, 0.25)
		holder.add_child(light)
	return holder


func _make_classic_alien() -> Node2D:
	var holder := Node2D.new()
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-10, 6), Vector2(-14, -2), Vector2(-10, -15), Vector2(10, -15),
		Vector2(14, -2), Vector2(10, 6),
	])
	body.color = Color(0.4, 0.88, 0.32)
	holder.add_child(body)
	for ex in [-7, 7]:
		var eye := Polygon2D.new()
		eye.polygon = PackedVector2Array([
			Vector2(ex - 3, -11), Vector2(ex + 3, -11),
			Vector2(ex + 3, -4), Vector2(ex - 3, -4),
		])
		eye.color = Color.BLACK
		holder.add_child(eye)
	var antenna := Polygon2D.new()
	antenna.polygon = PackedVector2Array([
		Vector2(-1, -19), Vector2(1, -19), Vector2(1, -14), Vector2(-1, -14),
	])
	antenna.color = Color(0.4, 0.88, 0.32)
	holder.add_child(antenna)
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(-2.5, -22), Vector2(2.5, -22), Vector2(2.5, -18), Vector2(-2.5, -18),
	])
	tip.color = Color(1.0, 0.4, 0.4)
	holder.add_child(tip)
	return holder


func _make_octopus_alien() -> Node2D:
	var holder := Node2D.new()
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-13, 2), Vector2(-11, -10), Vector2(0, -15), Vector2(11, -10),
		Vector2(13, 2), Vector2(9, 6), Vector2(-9, 6),
	])
	body.color = Color(0.85, 0.3, 0.7)
	holder.add_child(body)
	for tx in [-10, -5, 0, 5, 10]:
		var tent := Polygon2D.new()
		tent.polygon = PackedVector2Array([
			Vector2(tx - 1.5, 5), Vector2(tx + 1.5, 5),
			Vector2(tx + 0.5, 15), Vector2(tx - 0.5, 15),
		])
		tent.color = Color(0.85, 0.3, 0.7)
		holder.add_child(tent)
	var eye := Polygon2D.new()
	eye.polygon = PackedVector2Array([
		Vector2(-4, -9), Vector2(4, -9), Vector2(4, -3), Vector2(-4, -3),
	])
	eye.color = Color.WHITE
	holder.add_child(eye)
	var pupil := Polygon2D.new()
	pupil.polygon = PackedVector2Array([
		Vector2(-1.5, -7), Vector2(1.5, -7), Vector2(1.5, -4), Vector2(-1.5, -4),
	])
	pupil.color = Color.BLACK
	holder.add_child(pupil)
	return holder


func _build_enemy_type_pool() -> void:
	enemy_type_pool.clear()
	for t in ENEMY_TYPES:
		for _w in range(t["weight"] as int):
			enemy_type_pool.append(t)


func _setup_photo_round_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float radius_ratio : hint_range(0.0, 0.5) = 0.35;

void fragment() {
	vec2 tex_size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
	float radius_px = min(tex_size.x, tex_size.y) * radius_ratio;
	vec2 pos = UV * tex_size;
	vec2 center = tex_size * 0.5;
	vec2 d = abs(pos - center) - (center - vec2(radius_px));
	float dist = length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - radius_px;

	float alpha = 1.0 - smoothstep(-1.5, 1.5, dist);
	vec4 tex_col = texture(TEXTURE, UV);
	COLOR = vec4(tex_col.rgb, tex_col.a * alpha);
}
"""
	photo_round_material = ShaderMaterial.new()
	photo_round_material.shader = shader


func _pick_enemy_type() -> Dictionary:
	if enemy_type_pool.is_empty():
		return ENEMY_TYPES[0]
	return enemy_type_pool[randi() % enemy_type_pool.size()]


func _enemy_type_color(type_name: String) -> Color:
	match type_name:
		"swift":
			return Color(1.0, 0.9, 0.2)
		"zigzag":
			return Color(0.4, 0.8, 1.0)
		"tank":
			return Color(0.9, 0.3, 0.6)
		_:
			return Color.RED


func _load_photo_textures() -> void:
	var dir := DirAccess.open(PHOTO_DIR)
	if dir == null:
		return
	var seen := {}
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir():
			var canonical := name
			if canonical.to_lower().ends_with(".import"):
				canonical = canonical.substr(0, canonical.length() - 7)
			var lower := canonical.to_lower()
			var is_image := lower.ends_with(".png") or lower.ends_with(".jpg") or lower.ends_with(".jpeg") or lower.ends_with(".webp")
			if is_image and not seen.has(canonical):
				seen[canonical] = true
				var path := PHOTO_DIR + "/" + canonical
				if ResourceLoader.exists(path):
					var tex: Texture2D = load(path)
					if tex != null:
						var score_value: int = PHOTO_SCORES.get(canonical, DEFAULT_ENEMY_SCORE)
						var weight: int = PHOTO_WEIGHTS.get(canonical, 1)
						var entry := {"texture": tex, "score": score_value, "name": canonical}
						for _w in range(weight):
							photos.append(entry)
		name = dir.get_next()
	dir.list_dir_end()


func _spawn_trophy(pos: Vector2, tex) -> void:
	var trophy: Node2D
	if tex != null:
		trophy = _make_photo_trophy(tex)
	else:
		trophy = _make_emoji_trophy()
	trophy.position = pos
	add_child(trophy)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(trophy, "position:y", trophy.position.y + ANIMAL_FALL_DISTANCE, ANIMAL_LIFETIME)
	tween.tween_property(trophy, "modulate:a", 0.0, ANIMAL_LIFETIME).set_delay(ANIMAL_LIFETIME * 0.4)
	tween.chain().tween_callback(trophy.queue_free)


func _make_emoji_trophy() -> Node2D:
	var holder := Node2D.new()
	var animal := Label.new()
	animal.text = ANIMAL_EMOJIS[randi() % ANIMAL_EMOJIS.size()]
	animal.add_theme_font_override("font", emoji_font)
	animal.add_theme_font_size_override("font_size", 40)
	animal.size = Vector2(60, 60)
	animal.position = Vector2(-30, -30)
	animal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	animal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	holder.add_child(animal)
	return holder


func _make_photo_trophy(tex: Texture2D) -> Node2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.material = photo_round_material
	var tex_size := tex.get_size()
	var max_dim: float = max(tex_size.x, tex_size.y)
	var fit_scale: float = PHOTO_DISPLAY_SIZE / max_dim
	sprite.scale = Vector2(fit_scale, fit_scale)
	return sprite


func _spawn_life_popup(pos: Vector2) -> void:
	var popup := Label.new()
	popup.text = "+1 CAN ❤"
	popup.add_theme_font_override("font", emoji_font)
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.size = Vector2(140, 32)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = pos - Vector2(70, 80)
	add_child(popup)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 90.0, 1.4)
	tween.tween_property(popup, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tween.chain().tween_callback(popup.queue_free)


func _spawn_score_popup(pos: Vector2, value: int) -> void:
	var popup := Label.new()
	popup.text = "+%d" % value
	popup.add_theme_font_size_override("font_size", 22 if value < 500 else 30)
	var col := Color(1.0, 0.95, 0.4) if value < 500 else Color(1.0, 0.55, 0.1)
	popup.add_theme_color_override("font_color", col)
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.size = Vector2(100, 30)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = pos - Vector2(50, 50)
	add_child(popup)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 70.0, 1.0)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.3)
	tween.chain().tween_callback(popup.queue_free)


func _spawn_stars() -> void:
	for i in range(STAR_COUNT):
		var star := ColorRect.new()
		var depth := randf()
		var size_px := 1.0 + depth * 2.5
		star.size = Vector2(size_px, size_px)
		star.color = Color(1.0, 1.0, 1.0, 0.35 + depth * 0.65)
		star.position = Vector2(randf_range(0.0, SCREEN_WIDTH), randf_range(0.0, SCREEN_HEIGHT))
		add_child(star)
		stars.append({"node": star, "speed": 25.0 + depth * 90.0})


func _spawn_explosion(pos: Vector2, base_color: Color) -> void:
	for i in range(EXPLOSION_PARTICLES):
		var particle := ColorRect.new()
		particle.size = Vector2(3, 3)
		particle.color = Color(
			base_color.r,
			base_color.g + randf_range(-0.15, 0.25),
			base_color.b + randf_range(0.0, 0.2),
		)
		particle.position = pos
		add_child(particle)

		var angle := randf() * TAU
		var distance := randf_range(28.0, 70.0)
		var target := pos + Vector2(cos(angle) * distance, sin(angle) * distance)
		var lifetime := randf_range(0.35, 0.6)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target, lifetime).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, lifetime)
		tween.chain().tween_callback(particle.queue_free)


func _take_damage() -> void:
	lives -= 1
	invulnerability_timer = INVULNERABILITY_TIME
	_update_lives_display()


func _update_lives_display() -> void:
	if lives_label == null:
		return
	if lives <= 0:
		lives_label.text = ""
	else:
		lives_label.text = "❤️".repeat(lives)


func _trigger_game_over() -> void:
	game_over = true
	game_over_label = Label.new()
	game_over_label.text = "OYUN BITTI\nSkor: %d\n[BOSLUK] ile tekrar dene" % score
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.size = Vector2(SCREEN_WIDTH, 100)
	game_over_label.position = Vector2(0, SCREEN_HEIGHT / 2.0 - 50)
	game_over_label.add_theme_font_size_override("font_size", 26)
	add_child(game_over_label)


func _setup_planet() -> void:
	planet_node = Node2D.new()
	planet_node.position = Vector2(SCREEN_WIDTH / 2.0, 170)
	planet_node.z_index = -10
	add_child(planet_node)


func _update_planet() -> void:
	if planet_node == null:
		return
	var new_level: int = score / PLANET_LEVEL_INTERVAL
	var new_step: int = (score / PLANET_SIZE_PER_STEP) % (PLANET_LEVEL_INTERVAL / PLANET_SIZE_PER_STEP)
	if new_level == planet_level and new_step == planet_step:
		return
	planet_level = new_level
	planet_step = new_step
	_redraw_planet()
	_update_level_label()


func _update_level_label() -> void:
	if level_label == null:
		return
	level_label.text = "Sev %d  Gezegen %d  x%.2f" % [difficulty_level + 1, planet_level + 1, enemy_speed_mult]


func _redraw_planet() -> void:
	for child in planet_node.get_children():
		child.queue_free()

	var radius: float = PLANET_BASE_RADIUS + planet_step * PLANET_GROWTH_PER_STEP
	var palette: Dictionary = PLANET_PALETTES[planet_level % PLANET_PALETTES.size()]
	var main_color: Color = palette["main"]
	var spot_color: Color = palette["spot"]
	var has_ring: bool = palette["has_ring"]

	if has_ring:
		var ring_back := Line2D.new()
		ring_back.width = max(4.0, radius * 0.12)
		ring_back.default_color = Color(main_color.r * 0.85, main_color.g * 0.85, main_color.b * 0.85, 0.85)
		ring_back.points = _make_ellipse_points(radius * 1.7, radius * 0.45, 48)
		ring_back.z_index = -1
		planet_node.add_child(ring_back)

	var body := Polygon2D.new()
	body.polygon = _make_circle_polygon(radius, 36)
	body.color = main_color
	planet_node.add_child(body)

	var rng := RandomNumberGenerator.new()
	rng.seed = planet_level * 1000 + planet_step
	for i in range(5):
		var spot := Polygon2D.new()
		var sr: float = radius * rng.randf_range(0.15, 0.32)
		spot.polygon = _make_circle_polygon(sr, 16)
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0.0, radius * 0.6)
		spot.position = Vector2(cos(angle) * dist, sin(angle) * dist)
		spot.color = spot_color
		planet_node.add_child(spot)

	var highlight := Polygon2D.new()
	highlight.polygon = _make_circle_polygon(radius * 0.45, 24)
	highlight.position = Vector2(-radius * 0.35, -radius * 0.35)
	highlight.color = Color(1.0, 1.0, 1.0, 0.18)
	planet_node.add_child(highlight)

	if has_ring:
		var ring_front := Line2D.new()
		ring_front.width = max(4.0, radius * 0.12)
		ring_front.default_color = Color(main_color.r * 1.15, main_color.g * 1.15, main_color.b * 1.15, 0.9)
		var pts: PackedVector2Array = _make_ellipse_points(radius * 1.7, radius * 0.45, 48)
		var front_pts := PackedVector2Array()
		for p in pts:
			if p.y >= 0:
				front_pts.append(p)
		ring_front.points = front_pts
		ring_front.z_index = 1
		planet_node.add_child(ring_front)

	planet_node.modulate.a = 0.55


func _make_circle_polygon(radius: float, segments: int = 32) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in range(segments):
		var a: float = i * TAU / segments
		verts.append(Vector2(cos(a) * radius, sin(a) * radius))
	return verts


func _make_ellipse_points(rx: float, ry: float, segments: int) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in range(segments + 1):
		var a: float = i * TAU / segments
		verts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return verts
