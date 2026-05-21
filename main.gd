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
	"Adsız3.png": 400,
	"Adsız4.png": 400,
	"Adsız5.png": 1000,
}
const PHOTO_WEIGHTS = {
	"Adsız5.png": 2,
}
const PLAYER_MIN_Y = 220.0
const PLAYER_MAX_Y = SCREEN_HEIGHT - 30.0

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


func _ready() -> void:
	emoji_font = load("res://assets/Twemoji.Mozilla.ttf")
	_load_photo_textures()

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.15)
	bg.size = Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	add_child(bg)

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
		var enemy: Polygon2D = enemies[i]
		enemy.position.y += ENEMY_SPEED * delta

		var enemy_hit := false
		for j in range(bullets.size() - 1, -1, -1):
			var bullet: ColorRect = bullets[j]
			if enemy.position.distance_to(bullet.position) < 22.0:
				bullet.queue_free()
				bullets.remove_at(j)
				enemy_hit = true
				break

		if enemy_hit:
			_spawn_explosion(enemy.position, Color(1.0, 0.5, 0.0))
			var earned: int = _spawn_animal(enemy.position)
			_spawn_score_popup(enemy.position, earned)
			enemy.queue_free()
			enemies.remove_at(i)
			score += earned
			score_label.text = "Skor: %d" % score
			continue

		if enemy.position.y > SCREEN_HEIGHT + 20.0:
			enemy.queue_free()
			enemies.remove_at(i)
		elif enemy.position.distance_to(player.position) < 25.0:
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
	var bullet := ColorRect.new()
	bullet.color = Color.YELLOW
	bullet.size = Vector2(4, 12)
	bullet.position = player.position + Vector2(-2, -30)
	add_child(bullet)
	bullets.append(bullet)


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
	var enemy := Polygon2D.new()
	enemy.polygon = PackedVector2Array([
		Vector2(0, 15),
		Vector2(-15, -15),
		Vector2(15, -15),
	])
	enemy.color = Color.RED
	enemy.position = Vector2(randf_range(30.0, SCREEN_WIDTH - 30.0), -20.0)
	add_child(enemy)
	enemies.append(enemy)


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


func _spawn_animal(pos: Vector2) -> int:
	var trophy: Node2D
	var earned := DEFAULT_ENEMY_SCORE
	if photos.size() > 0:
		var picked: Dictionary = photos[randi() % photos.size()]
		trophy = _make_photo_trophy(picked["texture"])
		earned = picked["score"]
	else:
		trophy = _make_emoji_trophy()
	trophy.position = pos
	add_child(trophy)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(trophy, "position:y", trophy.position.y + ANIMAL_FALL_DISTANCE, ANIMAL_LIFETIME)
	tween.tween_property(trophy, "modulate:a", 0.0, ANIMAL_LIFETIME).set_delay(ANIMAL_LIFETIME * 0.4)
	tween.chain().tween_callback(trophy.queue_free)
	return earned


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
	var tex_size := tex.get_size()
	var max_dim: float = max(tex_size.x, tex_size.y)
	var fit_scale: float = PHOTO_DISPLAY_SIZE / max_dim
	sprite.scale = Vector2(fit_scale, fit_scale)
	return sprite


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
