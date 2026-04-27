# Шина Событий (Event Bus) - Документация и Рекомендации

## 📋 Что было улучшено в шине событий

### 1. **Bus.gd** - Основные улучшения:

- **Исправлена сигнатура subscribe()**: Теперь принимает `GDScript` вместо экземпляра события
- **Добавлен unsubscribe()**: Для отписки от событий (важно для предотвращения утечек памяти)
- **Проверка дубликатов**: Подписка одного и того же обработчика не создаст дубликат
- **Авто-очистка невалидных объектов**: Если объект подписки удалён, он автоматически удаляется из списка
- **Копирование массива при отправке**: Предотвращает ошибки при модификации подписок во время обработки события
- **Дополнительные утилиты**: 
  - `get_subscriber_count()` - для отладки
  - `clear_all()` - для очистки всех подписок
  - `_get_event_type()` - хелпер для получения имени типа события

### 2. **EventBusSingleton.gd** - Глобальный доступ:
- Статический класс для доступа к шине событий из любого места без поиска узла
- Автоматически находит экземпляр Bus в сцене

### 3. **Новые типы событий**:
- `PlayerDeathEvent` - смерть игрока (уровень, время, счёт)
- `PlayerLevelUpEvent` - повышение уровня
- `EnemyKilledEvent` - убийство врага (тип, здоровье, награда, дроп)
- `PlayerDamageEvent` - получение урона игроком

---

## 🎯 Где использовать в вашей игре

### 1. **Смерть игрока** (scripts/player.gd)

В функции `_on_player_died()`:
```gdscript
func _on_player_died() -> void:
	is_alive = false
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	state = "death"
	
	# ОТПРАВЛЯЕМ СОБЫТИЕ
	var death_event = PlayerDeathEvent.new(level, _run_time)
	EventBus.create_event(death_event)
	# ИЛИ: Bus.get_instance().create_event(death_event)
	
	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		SetDirection()
		SetState()
		UpdateAnimation()
		get_tree().paused = true
		animation_player.process_mode = AnimationPlayer.PROCESS_MODE_ALWAYS
		await animation_player.animation_finished
		var death_screen = DEATH_SCREEN_SCENE.instantiate()
		get_tree().root.add_child(death_screen)
		if death_screen:
			death_screen.init_stats(_run_time, level)
			death_screen.restart_requested.connect(_on_death_screen_restart)
			death_screen.menu_requested.connect(_on_death_screen_menu)
```

**Кто может подписаться:**
- Достижения (ачивка "Первая смерть")
- Статистика (сохранение количества смертей)
- Аналитика (отправка данных о времени жизни)
- Звуковой менеджер (специальный звук смерти)

---

### 2. **Получение урона** (scripts/player.gd)

В функции `_apply_damage()`:
```gdscript
func _apply_damage(amount: int, knockback_direction: Vector2) -> void:
	if _invincibility_timer > 0.0:
		return
	
	health -= amount
	_invincibility_timer = invincibility_time  
	
	# ОТПРАВЛЯЕМ СОБЫТИЕ ПЕРЕД ВИЗУАЛЬНЫМИ ЭФФЕКТАМИ
	var damage_event = PlayerDamageEvent.new(
		amount, 
		health, 
		max_health, 
		knockback_direction
	)
	EventBus.create_event(damage_event)
	
	if _damage_sfx_player:
		_damage_sfx_player.volume_db = _get_combat_sfx_volume_db()
		_damage_sfx_player.play()
	_flash_red()                              
	
	if knockback_direction != Vector2.ZERO:
		_knockback_timer = 0.10
		velocity = knockback_direction * knockback_force
	
	_update_hp_ui()
	health_updated.emit(health, max_health)
	
	if health <= 0:
		_on_player_died()
```

**Кто может подписаться:**
- Тряска камеры (Camera2D)
- Всплывающий текст урона
- Частицы крови/искры
- UI эффекты (красная виньетка)
- Достижения ("Первый урон", "Выжил с 1 HP")

---

### 3. **Повышение уровня** (scripts/player.gd)

В функции `_on_level_up()`:
```gdscript
func _on_level_up() -> void:
	var previous_level = level - 1
	
	# ОТПРАВЛЯЕМ СОБЫТИЕ ДО ПОКАЗА МЕНЮ
	var level_up_event = PlayerLevelUpEvent.new(level, previous_level)
	EventBus.create_event(level_up_event)
	
	level_updated.emit(level)
	if not LEVEL_UP_MENU_SCENE: return
	
	var menu = LEVEL_UP_MENU_SCENE.instantiate()
	if menu:
		if menu.has_signal("option_chosen"):
			menu.option_chosen.connect(_on_level_up_option_chosen)
		get_tree().root.add_child(menu)
		get_tree().paused = true
```

**Кто может подписаться:**
- Салют/частицы庆祝
- Звук повышения уровня
- Всплывающая надпись "LEVEL UP!"
- Сохранение максимального достигнутого уровня
- Достижения ("Уровень 5", "Уровень 10")

---

### 4. **Смерть врага** (scripts/default_enemy.gd)

В функции `die()`:
```gdscript
func die() -> void:
	# ОПРЕДЕЛЯЕМ ТИП ДРОПА
	var drop_type = "exp"
	if heal_scene and randf() < heal_drop_chance:
		drop_type = "heal"
	
	# ОТПРАВЛЯЕМ СОБЫТИЕ
	var kill_event = EnemyKilledEvent.new(
		get_script().get_global_name(),
		health,
		10,  # exp_reward (можно сделать переменной)
		drop_type
	)
	EventBus.create_event(kill_event)
	
	_play_death_sfx()

	# иногда вместо опыта падает хилка
	if heal_scene and randf() < heal_drop_chance:
		var heal = heal_scene.instantiate()
		heal.global_position = global_position
		get_parent().add_child(heal)
	elif exp_scene:
		var exp = exp_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
	
	queue_free()
```

**Кто может подписаться:**
- Счётчик убийств (для HUD или достижений)
- Комбо-система (если убиваешь быстро подряд)
- Квесты/задания ("Убей 10 врагов")
- Волны спавна (прогресс волны)
- Достижения ("Первая кровь", "100 убийств")

---

### 5. **Пример подписки** (scripts/hud.gd или отдельный скрипт)

Создайте новый скрипт `scripts/event_listeners.gd`:

```gdscript
extends Node

@onready var kill_counter_label: Label = $HUD/KillCounter
var kill_count: int = 0


func _ready() -> void:
	# Подписка на события
	EventBus.subscribe(PlayerDeathEvent, _on_player_death)
	EventBus.subscribe(EnemyKilledEvent, _on_enemy_killed)
	EventBus.subscribe(PlayerLevelUpEvent, _on_level_up)
	EventBus.subscribe(PlayerDamageEvent, _on_player_damaged)


func _exit_tree() -> void:
	# Отписка при уничтожении (ВАЖНО!)
	EventBus.unsubscribe(PlayerDeathEvent, _on_player_death)
	EventBus.unsubscribe(EnemyKilledEvent, _on_enemy_killed)
	EventBus.unsubscribe(PlayerLevelUpEvent, _on_level_up)
	EventBus.unsubscribe(PlayerDamageEvent, _on_player_damaged)


func _on_player_death(event: PlayerDeathEvent) -> void:
	print("Игрок умер на уровне ", event.player_level, 
		  ", прожил ", event.run_time, " секунд")
	# Сохраняем статистику, показываем достижения и т.д.


func _on_enemy_killed(event: EnemyKilledEvent) -> void:
	kill_count += 1
	if kill_counter_label:
		kill_counter_label.text = "Kills: %d" % kill_count
	
	if kill_count == 10:
		print("Достижение: Убийца 10 уровня!")


func _on_level_up(event: PlayerLevelUpEvent) -> void:
	print("Повышение уровня! Был ", event.previous_level, 
		  ", стал ", event.player_level)
	# Проигрываем звук, показываем частицы


func _on_player_damaged(event: PlayerDamageEvent) -> void:
	if event.current_health <= event.max_health * 0.2:
		print("ВНИМАНИЕ: Низкое здоровье!")
		# Показываем предупреждение на экране
```

---

### 6. **Интеграция с Main.tscn**

1. Добавьте узел `Bus` (из `events/core/bus.gd`) в вашу основную сцену `main.tscn`
2. Или настройте как AutoLoad в Project Settings → AutoLoad:
   - Path: `res://events/core/bus.gd`
   - Name: `EventBus`

Тогда можно будет использовать:
```gdscript
EventBus.subscribe(PlayerDeathEvent, self._on_death)
EventBus.create_event(my_event)
```

---

## ⚠️ Важные замечания

### 1. **Всегда отписывайтесь!**
При использовании `subscribe()` в `_ready()`, добавляйте `unsubscribe()` в `_exit_tree()`:

```gdscript
func _ready():
	EventBus.subscribe(MyEvent, self._on_my_event)

func _exit_tree():
	EventBus.unsubscribe(MyEvent, self._on_my_event)
```

Это предотвратит утечки памяти и ошибки когда объект уже удалён, но всё ещё в списке подписок.

### 2. **Не используйте для критичной по времени логики**
События обрабатываются через `call_deferred()`, что означает задержку на 1 кадр. 
Для мгновенной реакции используйте прямые вызовы или сигналы.

### 3. **Избегайте циклических зависимостей**
Если событие A вызывает событие B, которое вызывает событие A — будет бесконечный цикл.

### 4. **Документируйте события**
Создайте файл `EVENTS.md` со списком всех событий и их назначением.

---

## 📊 Сравнение: Сигналы vs Шина Событий

| Критерий | Сигналы Godot | Шина Событий |
|----------|--------------|--------------|
| Производительность | ⭐⭐⭐⭐⭐ Быстрее | ⭐⭐⭐⭐ Чуть медленнее (deferred) |
| coupling | Средний (нужна ссылка на объект) | Низкий (полная развязка) |
| Отладка | Легко (стек вызовов виден) | Сложнее (асинхронно) |
| Масштабируемость | Требует связей 1-к-1 | Множественные подписчики |
| Использование | Внутри связанных объектов | Между независимыми системами |

**Рекомендация:** Используйте сигналы для тесно связанных объектов (игрок-пуля, враг-урон), 
а шину событий для кросс-системных событий (достижения, статистика, квесты).

---

## 🚀 Следующие шаги

1. **Добавьте Bus как AutoLoad** в Project Settings
2. **Интегрируйте события** в player.gd и enemy.gd (примеры выше)
3. **Создайте EventListeners** скрипт для обработки событий
4. **Добавьте новые события** по мере необходимости:
   - `GameStartedEvent`
   - `WaveCompletedEvent`
   - `ItemCollectedEvent`
   - `SettingsChangedEvent`

5. **Рассмотрите добавление приоритетов** для обработчиков событий
6. **Добавьте логирование** для отладки (какие события отправляются)
