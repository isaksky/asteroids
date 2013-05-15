#= require vendor/Box2dWeb-2.1.a.3.min.js
#= require vendor/underscore-min
#= require underscore_mixins
#= require constants
#= require util
#= require game_objects
#= require levels
#= require physics

# loljs 'import'
b2Vec2 = Box2D.Common.Math.b2Vec2
b2BodyDef = Box2D.Dynamics.b2BodyDef
b2Body = Box2D.Dynamics.b2Body
b2FixtureDef = Box2D.Dynamics.b2FixtureDef
b2Fixture = Box2D.Dynamics.b2Fixture
b2World = Box2D.Dynamics.b2World
b2MassData = Box2D.Collision.Shapes.b2MassData
b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
b2DebugDraw = Box2D.Dynamics.b2DebugDraw

LEVEL_INTRO_TIME = 2500

log = (msg) ->
  self.postMessage(func_name: 'log', arg: msg)

@set_keys = (keys) ->
  @keys = keys

@init = ({width, height}) =>
  @width = width
  @height = height
  log "init!"
  gravity = new b2Vec2(0, 0) #random(-0.5, 0.5), random(-0.5, 0.5))
  allow_sleep = true
  @world = new b2World(gravity, allow_sleep)
  @waves_spawned_by_level = {}
  @jerk_charge_duration = JERK_CHARGE_DURATION_PIXEL_COEFF * @width * @height
  @score = @num_update_ticks = 0
  @finished = false
  @prev_spawn_time = _.now()
  @game_objects = {}

  gravity = new b2Vec2(0, 0)#random(-0.5, 0.5), random(-0.5, 0.5))
  allow_sleep = true
  @world = new b2World(gravity, allow_sleep)

  @player = create_game_object[SHIP](@width / SCALE / 2, @height / SCALE / 2)
  @player.is_player = true
  @game_objects[@player.guid] = @player

  @player_body = @setup_physics_for_game_object(player)
  @player_body.SetAngularDamping(2.5)
  @player_body.SetLinearDamping(1)

  @start_next_wave_or_level()
  @start_collision_detection()

  @interval_id = setInterval(@update_loop, parseInt(1000 / 60, 10))



# wrap object to other side of screen if its not on screen
@wrap_object = (body) ->
  pos = body.GetPosition()
  if pos.x > @width / SCALE + EDGE_OFFSET
    new_x = -EDGE_OFFSET
  else if pos.x < 0 - EDGE_OFFSET
    new_x = @width / SCALE + EDGE_OFFSET

  if pos.y > @height / SCALE + EDGE_OFFSET
    new_y = -EDGE_OFFSET
  else if pos.y < 0 - EDGE_OFFSET
    new_y = @height / SCALE + EDGE_OFFSET

  if new_x? || new_y?
    new_x = pos.x unless new_x?
    new_y = pos.y unless new_y?
    body.SetPosition(new b2Vec2(new_x, new_y))

@handle_keyboard_input = ->
  if @keys.UP
    @gas(@player, @player_body, false)
  if @keys.DOWN
    @gas(@player, @player_body, true)
  if @keys.LEFT
    @player_body.ApplyTorque(-0.2)
  if @keys.RIGHT
    @player_body.ApplyTorque(0.2)
  if @keys.SPACE
    if @player.fire_juice > BASE_BULLET_COST
      @shoot_bullet @player.bullet_radius
  # if @keys.SHIFT
  #   if @player.fire_juice > 0
  #     @shoot_bullet 0.20

@handle_jerk_ai = (jerk, jerk_body) ->
  dx =  player.x - jerk.x
  dy = player.y - jerk.y
  attack_angle = _.normalize_angle(Math.atan2(dy, dx))
  jerk_angle = jerk.angle
  angle_diff = _.normalize_angle(jerk_angle - attack_angle)
  #log "dx : #{dx}, dy : #{dy}, Attack angle : #{attack_angle},
  #  angle delta : #{angle_diff}" if @num_update_ticks % 500 == 1
  is_off_screen = jerk.x > @width / SCALE || jerk.x < 0 || jerk.y < 0 || jerk.y > @width / SCALE
  if jerk.current_charge_start && jerk.current_charge_start > 0
    @gas(jerk, jerk_body, false, 0.07)
    if _.now() - jerk.current_charge_start > @jerk_charge_duration
      jerk.current_charge_start = -1
  else if is_off_screen
    @gas(jerk, jerk_body, false, 0.07)
  else if Math.abs(angle_diff) < 0.05
    jerk.aim += 1
    if jerk.aim > JERK_AIM_TIME
      jerk.current_charge_start = _.now()
      log "ATTACK!"
  else
    jerk.aim = 0 if jerk.aim
    # look ahead 1/3 sec. Applying the right torque gets complicated when we're already spinning
    future_jerk_angle = jerk_angle + jerk_body.GetAngularVelocity() / 3.0
    torque = if _.is_clockwise_of(attack_angle, future_jerk_angle) then 0.1 else -0.1
    jerk_body.ApplyTorque(torque)

@update_loop = ->
  @dt = if @last_update_time? then _.now() - @last_update_time else 1
  @update()
  @last_update_time = _.now()

@update = ->
  return if @finished
  @player.fire_juice += 0.5
  @player.fire_juice = MAX_PLAYER_FIRE_JUICE if @player.fire_juice > MAX_PLAYER_FIRE_JUICE #Math.min(@player.fire_juice, 100)

  @handle_keyboard_input()

  #bottom
  step_rate = @dt / 1000
  @world.Step(step_rate, 10, 10)
  @world.DrawDebugData() if @debug
  @world.ClearForces()

  graveyard = []
  body = @world.GetBodyList()
  @enemies_remaining = 0
  while body?
    if body.GetUserData()?
      pos = body.GetPosition()
      game_object = @game_objects[body.GetUserData()]
      if game_object.hp <= 0
        if game_object.is_player
          @finished = true
        else
          graveyard.push(game_object)
          @world.DestroyBody(body)

          drop_pct = DROP_PCT_BY_TYPE[game_object.type]
          if drop_pct? && _.random() <= drop_pct
            drop_type = _.random(DROP_TYPES)
            drop = create_game_object[drop_type](game_object.x, game_object.y)
            @game_objects[drop.guid] = drop
            drop_body = @setup_circular_physics_body(drop)
            drop_body.SetLinearDamping(1)
      else if game_object.type == BULLET && (_.now() - game_object.start_time) > 1400
        graveyard.push(game_object)
        @world.DestroyBody(body)
      else if game_object.type == PARTICLE && (_.now() - game_object.start_time) > MAX_PARTICLE_AGE
        graveyard.push(game_object)
        @world.DestroyBody(body)
      else
        @wrap_object(body)
        _.merge game_object,
          x : pos.x
          y : pos.y
          angle : body.GetAngle()
        @handle_jerk_ai(game_object, body) if game_object.type == JERK
    @enemies_remaining += 1 if game_object.type == ASTEROID || game_object.type == JERK
    game_object.invuln_ticks -= 1 if game_object.invuln_ticks
    body = body.m_next

  for o in graveyard
    point_value = POINTS_BY_TYPE[o.type]
    @score += point_value if point_value?
    delete @game_objects[o.guid]

  @advance_level_check() if @num_update_ticks % 20 == 1

  #@spawn_enemies_tick() if @num_update_ticks % 20 == 1
  @num_update_ticks += 1

  try
    @postMessage
      game_objects : @game_objects
  catch e
    clearInterval @interval_id
    log @game_objects

@advance_level_check = () ->
  on_last_level = @level_idx == levels.length - 1
  on_last_wave = @prev_wave_spawned_by_level[@level_idx] == levels[@level_idx].waves.length - 1
  if !on_last_wave
    wave_due_at = @wave_start_time + levels[@level_idx].waves[@prev_wave_spawned_by_level[@level_idx]].start_time
    due_for_wave = _.now() > wave_due_at

  if on_last_level && on_last_wave
    @finished = true if @enemies_remaining == 0
  else if (@enemies_remaining < 2 || due_for_wave)  && !on_last_wave
    @start_next_wave_or_level()
  else if @enemies_remaining == 0
    @start_next_wave_or_level()

@random_x_coord = () ->
  _.random(@width / 10 / SCALE, (@width - @width / 10) / SCALE)

@random_y_coord = () ->
  _.random(@height / 10 / SCALE, (@height - @height / 10) / SCALE)



@start_next_wave_or_level = ->
  @prev_wave_spawned_by_level ||= {}
  unless @level_idx?
    @level_idx = 0
    @level_start_time = _.now()
    @prev_wave_spawned_by_level[@level_idx] = -1

  wave_found = false
  for wave, wave_idx in levels[@level_idx].waves
    if @prev_wave_spawned_by_level[@level_idx] < wave_idx
      wave_found = true
      break

  if wave_found
    log "Sending next wave!"
    @prev_wave_spawned_by_level[@level_idx] = wave_idx
    @wave_start_time = _.now()
    for object_type_name, quantity of wave.spawns
      object_type = self[object_type_name.toUpperCase()]
      quantity = Math.ceil(quantity * (@height * @width / (1280 * 800))) # normalize quantity by window size
      log "creating #{quantity} of type #{object_type} : #{ENUM_NAME_BY_TYPE[object_type]}"
      _(quantity).times =>
        invuln_ticks = if @level_idx == 0 && wave_idx == 0 then 0 else 60
        game_object = create_game_object[object_type](@random_x_coord(), @random_y_coord(), invuln_ticks)
        @game_objects[game_object.guid] = game_object

        @setup_physics_for_game_object(game_object)

  else if levels[@level_idx + 1]?
    log "Advancing levels!"
    JERK_AIM_TIME = Math.ceil(JERK_AIM_TIME * 0.9)
    @level_idx += 1
    @prev_wave_spawned_by_level[@level_idx] = -1
    @level_start_time = _.now()
    return @start_next_wave_or_level()
  else
    log "hmm"

@onmessage = (e) =>
  {func_name, arg} = e.data
  #log "Got command #{e.data.func_name}, /w arg #{e.data.arg}"
  self[func_name](arg)
  # if func? && self[func_name]?
  #   self[func_name](arg)
  # else
  #   throw new Error("Dont have this function: #{e.data.func_name}")
