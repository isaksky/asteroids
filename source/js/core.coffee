# loljs imports
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
b2AABB = Box2D.Collision.b2AABB

LEVEL_INTRO_TIME = 2500
MAX_PLACEMENT_ATTEMPTS = 50
PLACEMENT_OFFSET = 2
jerk_base_engine_power = 0.01
bub_base_engine_power = 0.005

@game = Sketch.create
  container : document.getElementById "container"
  # Gotta turn things way down for people not using Chrome
  max_pixels :  if "Google Inc." == window.navigator?.vendor then 1280 * 800 else 800 * 600
  setup : ->
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
    window.player = @player
    @game_objects[@player.guid] = @player

    @player_body = physics_helper.get_physics_setup_fn(@player)(@player, @world)
    @player_body.SetAngularDamping(2.5)
    @player_body.SetLinearDamping(1)

    @start_next_wave_or_level()
    @start_collision_detection()

  start_next_wave_or_level : ->
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
      _.log "Sending next wave!"
      @prev_wave_spawned_by_level[@level_idx] = wave_idx
      @wave_start_time = _.now()

      for object_type_name, quantity of wave.spawns
        object_type = window[object_type_name.toUpperCase()]
        quantity = Math.ceil(quantity * (@height * @width / (1280 * 800))) # normalize quantity by window size
        _.log "creating #{quantity} of type #{object_type} : #{ENUM_NAME_BY_TYPE[object_type]}"


        for i in [0..quantity]
          attempts = 1
          invuln_ticks = if @level_idx == 0 && wave_idx == 0 then 0 else 60
          x = @random_x_coord()
          y = @random_y_coord()
          offset_multiplier = 3
          while attempts <= MAX_PLACEMENT_ATTEMPTS && _.is_point_in_rect(x, y,
            @player.x - PLACEMENT_OFFSET,
            @player.y - PLACEMENT_OFFSET,
            @player.x + PLACEMENT_OFFSET,
            @player.y + PLACEMENT_OFFSET)
              x = @random_x_coord()
              y = @random_y_coord()
              attempts += 1
          _.log "Reached max placement attempts" if attempts == MAX_PLACEMENT_ATTEMPTS
          game_object = create_game_object[object_type](x, y, invuln_ticks)
          @game_objects[game_object.guid] = game_object
          physics_helper.get_physics_setup_fn(game_object)(game_object, @world)
    else if levels[@level_idx + 1]?
      _.log "Advancing levels!"
      JERK_AIM_TIME = Math.ceil(JERK_AIM_TIME * 0.8)
      jerk_base_engine_power *= 1.3
      bub_base_engine_power *= 1.3
      @level_idx += 1
      @prev_wave_spawned_by_level[@level_idx] = -1
      @level_start_time = _.now()
      return @start_next_wave_or_level()
    else
      _.log "programming incompetens excepshon"

  contact_info : (contact) ->
    info = {}
    guid_a = contact.GetFixtureA().GetBody().GetUserData()
    guid_b = contact.GetFixtureB().GetBody().GetUserData()
    if guid_a && guid_b && @game_objects[guid_a] && @game_objects[guid_b]
      a = @game_objects[guid_a]
      b = @game_objects[guid_b]
      info.same_types = a.type == b.type
      if info.same_types
        info.both = [a, b]
      else
        info[a.type] = a
        info[b.type] = b
    info

  start_collision_detection : ->
    #NOTE: This part of the code is a total shitshow. Trying to think of how to simplify.
    listener = new Box2D.Dynamics.b2ContactListener
    listener.PreSolve = (contact) =>
      contact_info = @contact_info(contact)
      if contact_info.same_types && contact_info.both[0].type == BULLET
        contact.SetEnabled(false)
      else if contact_info[BULLET] && contact_info[PARTICLE]
        contact.SetEnabled(false)

      else if contact_info[SHIP] && contact_info[BULLET] &&
      contact_info[BULLET].source_object_guid == contact_info[SHIP].guid       # ignore contacts between ship and ship's own bullets
        contact.SetEnabled(false)
      else if (contact_info[ASTEROID]?.invuln_ticks || contact_info[JERK]?.invuln_ticks) && contact_info[SHIP]?.is_player
        contact.SetEnabled(false)       # player can't crash into invuln asteroid or jerk
      else if drop = _.clj_some(DROP_TYPES, (game_object_type) -> contact_info[game_object_type])
        contact.SetEnabled(false)
        if contact_info[SHIP]?.is_player
          drop.consume(contact_info[SHIP])
          drop.hp = 0

        # else if a instanceof Particle && b instanceof Particle
        #   contact.SetEnabled(false)

    listener.PostSolve = (contact, impulse) =>
      force = Math.abs(impulse.normalImpulses[0]) * 8.5
      contact_info = @contact_info(contact)

      force *= 120 if contact_info[BULLET]

      #_.log "Collision between #{a.type} and #{b.type}"

      if contact_info[ASTEROID] && contact_info[BULLET]
        contact_info[ASTEROID].hp -= force
        contact_info[BULLET].hp = 0
      else if contact_info.same_types && contact_info.both[0].type == ASTEROID
        contact_info.both[0].hp -= force
        contact_info.both[1].hp -= force
      else if contact_info[ASTEROID] && contact_info[SHIP]?.is_player
        if force > 0.25 # so player can push shit around a bit without getting hurt
          contact_info[ASTEROID].hp -= force
          contact_info[SHIP].hp -= force
      else if contact_info[SHIP]?.is_player && (contact_info[BULLET]?.source_object_guid != contact_info[SHIP].guid)
        contact_info[SHIP].hp -= force
      else if contact_info[JERK] && contact_info[SHIP]?.is_player
        contact_info[SHIP]?.hp -= force
      else if contact_info[BULLET] && (contact_info[JERK] || contact_info[BUB])
        (contact_info[JERK] || contact_info[BUB]).hp -= force
        contact_info[BULLET].hp = 0

    @world.SetContactListener(listener)

  shoot_bullet : (radius) ->
    x = @player.x + (@player.max_x + radius) * Math.cos(@player.angle)
    y = @player.y + (@player.max_x + radius) * Math.sin(@player.angle)
    bullet = create_game_object[BULLET](radius, x, y, @player.guid)
    @game_objects[bullet.guid] = bullet
    physics_helper.get_physics_setup_fn(bullet)(bullet, @world, @player_body, @player)
    @player.fire_juice = Math.max(@player.fire_juice - BASE_BULLET_COST, 0)

  # wrap object to other side of screen if its not on screen
  wrap_object : (body) ->
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

  gas : (game_object, physics_body, do_backwards, pow = 0.04) ->
    angle = if do_backwards then (game_object.angle + PI) % TWO_PI else game_object.angle
    physics_body.ApplyImpulse(new b2Vec2(Math.cos(angle) * pow,
      Math.sin(angle) * pow), physics_body.GetWorldCenter())

    radius = 0.1
    offset = if do_backwards then game_object.max_x + 0.1 else game_object.min_x + 0.1
    x = game_object.x + (offset + radius) * Math.cos(angle + PI)
    y = game_object.y + (offset + radius) * Math.sin(angle + PI)
    #_.log "player [#{player.x}, #{@player.y}, #{player.angle}] bullet [#{x}, #{y}]"
    particle = create_game_object[PARTICLE](radius, x, y)
    @game_objects[particle.guid] = particle
    particle_body = physics_helper.get_physics_setup_fn(particle)(particle, @world)
    particle_body.SetLinearVelocity(physics_body.GetLinearVelocity())
    particle_angle = (angle + PI) % TWO_PI
    particle_body.ApplyImpulse(new b2Vec2(Math.cos(particle_angle) * pow,
      Math.sin(particle_angle) * pow), physics_body.GetWorldCenter())

  handle_keyboard_input : ->
    if @keys.UP
      @gas(@player, @player_body, false)
    if @keys.DOWN
      @gas(@player, @player_body, true)
    if @keys.LEFT
      @player_body.ApplyTorque(-0.2)
    if @keys.RIGHT
      @player_body.ApplyTorque(0.2)
    if @keys.SPACE && @player.fire_juice > BASE_BULLET_COST
      @shoot_bullet(@player.bullet_radius)
    # if @keys.SHIFT
    #   if @player.fire_juice > 0
    #     @shoot_bullet 0.20

  handle_jerk_ai : (jerk, jerk_body) ->
    dx =  player.x - jerk.x
    dy = player.y - jerk.y
    attack_angle = _.normalize_angle(Math.atan2(dy, dx))
    jerk_angle = jerk.angle
    angle_diff = _.normalize_angle(jerk_angle - attack_angle)
    #_.log "dx : #{dx}, dy : #{dy}, Attack angle : #{attack_angle},
    #  angle delta : #{angle_diff}" if @num_update_ticks % 500 == 1
    is_off_screen = jerk.x > @width / SCALE || jerk.x < 0 || jerk.y < 0 || jerk.y > @width / SCALE
    if jerk.current_charge_start
      @gas(jerk, jerk_body, false, Math.max(0.07, jerk_base_engine_power * 3))
      if _.now() - jerk.current_charge_start > @jerk_charge_duration
        jerk.current_charge_start = null
    else if is_off_screen
      @gas(jerk, jerk_body, false, 0.07)
    else if Math.abs(angle_diff) < 0.05
      jerk.aim += 1
      if jerk.aim > JERK_AIM_TIME
        jerk.current_charge_start = _.now()
        _.log "ATTACK!"
      #@gas(jerk, jerk_body, false, jerk_base_engine_power) unless jerk.invuln_ticks
    else
      jerk.aim -= 0.1 if jerk.aim
      jerk.aim = 0 if jerk.aim && jerk.aim < 0
      # look ahead 1/3 sec. Applying the right torque gets complicated when we're already spinning
      future_jerk_angle = jerk_angle + jerk_body.GetAngularVelocity() / 3.0
      torque = (if _.is_clockwise_of(attack_angle, future_jerk_angle) then 1 else -1) * Math.abs(angle_diff) * 0.5
      jerk_body.ApplyTorque(torque)
      #if Math.abs(angle_diff < 0.2)
      #@gas(jerk, jerk_body, false, jerk_base_engine_power) unless jerk.invuln_ticks

  handle_bub_ai : (bub, bub_body) ->
    dx =  player.x - bub.x
    dy = player.y - bub.y
    attack_angle = _.normalize_angle(Math.atan2(dy, dx))
    bub_angle = bub.angle
    angle_diff = _.normalize_angle(bub_angle - attack_angle)
    is_off_screen = bub.x > @width / SCALE || bub.x < 0 || bub.y < 0 || bub.y > @width / SCALE

    if is_off_screen
      @gas(bub, bub_body, false, bub_base_engine_power * 2)
    else
      # look ahead 1/3 sec. Applying the right torque gets complicated when we're already spinning
      future_bub_angle = bub_angle + bub_body.GetAngularVelocity() / 3.0
      torque = (if _.is_clockwise_of(attack_angle, future_bub_angle) then 1 else -1) * Math.abs(angle_diff) * 0.5
      bub_body.ApplyTorque(torque)
      #if Math.abs(angle_diff < 0.2)
      @gas(bub, bub_body, false, bub_base_engine_power) unless bub.invuln_ticks


  update : ->
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
              drop_body = physics_helper.get_physics_setup_fn(drop)(drop, @world)
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
          @handle_bub_ai(game_object, body) if game_object.type == BUB
      @enemies_remaining += 1 if POINTS_BY_TYPE[game_object.type]?
      game_object.invuln_ticks -= 1 if game_object.invuln_ticks
      body = body.m_next

    for o in graveyard
      point_value = POINTS_BY_TYPE[o.type]
      @score += point_value if point_value?
      if graveyards_by_type[o.type]?
        graveyards_by_type[o.type].push o
      delete @game_objects[o.guid]

    # if @enemies_remaining == 0
    #   @finished = true

    @prev_update_millis = @millis

    @advance_level_check() if @num_update_ticks % 20 == 1

    #@spawn_enemies_tick() if @num_update_ticks % 20 == 1
    @num_update_ticks += 1

  advance_level_check : () ->
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

  random_x_coord : () ->
    random(@width / 10 / SCALE, (@width - @width / 10) / SCALE)

  random_y_coord : () ->
    _.random(@height / 10 / SCALE, (@height - @height / 10) / SCALE)

  toggle_debug: () ->
    if @debug?
     @debug = !@debug
    else
     @debug = true
     @autoclear = false
     debugDraw = new b2DebugDraw()
     debugDraw.SetSprite(this)
     debugDraw.SetDrawScale(SCALE)
     debugDraw.SetFillAlpha(0.3)
     debugDraw.SetLineThickness(1.0)
     debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)
     @world.SetDebugDraw(debugDraw)

  draw_hp_bar : ->
    bar_w = 100
    bar_h = 6
    @strokeStyle = "#cd5c5c"
    @strokeRect(10, 10, bar_w, bar_h)

    @fillStyle = "#cd5c5c"
    @fillRect(10, 10, (@player.hp / @player.max_hp) * bar_w,  bar_h)

  draw_fire_juice_bar : ->
    bar_w = 100
    bar_h = 6
    @strokeStyle = "#63D1F4"
    @strokeRect(10, 20, bar_w, bar_h)

    @fillStyle = "#63D1F4"
    @fillRect(10, 20, (@player.fire_juice / MAX_PLAYER_FIRE_JUICE) * bar_w,  bar_h)

  draw_score : () ->
    @textAlign = "right"
    @font = "30px monospace"
    @strokeStyle = "#63D1F4"
    @strokeText("#{@score}", @width - 5, 30)

  draw_level_intro : () ->
    d = _.now() - @level_start_time
    if d <= LEVEL_INTRO_TIME
      @textAlign = "center"
      @font = "50px monospace"
      eased_alpha = Math.sin(d / LEVEL_INTRO_TIME * Math.PI)
      @strokeStyle = "rgba(99, 209, 244, #{eased_alpha})"
      @strokeText("Level #{@level_idx + 1}", @width / 2, @height / 2 - 100)

  draw : ->
    return if @debug
    for key, game_object of @game_objects
      game_object_type_name = ENUM_NAME_BY_TYPE[game_object.type]
      drawing["draw_#{game_object_type_name}"](this, game_object)

    @draw_hp_bar()
    @draw_fire_juice_bar()
    @draw_score()
    @draw_level_intro()

    if @finished
      @textAlign = "center"
      @font = "70px sans-serif"
      if @enemies_remaining == 0
        @fillStyle = "#63D1F4"
        @fillText("YOU WIN", @width / 2 , @height / 2)
      else
        @fillStyle = '#f14'
        @fillText("GAME OVER", @width / 2 , @height / 2)
