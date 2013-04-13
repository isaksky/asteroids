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

LEVEL_INTRO_TIME = 2500

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

    @player_body = @setup_physics_for_game_object(player)
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
        _(quantity).times =>
          invuln_ticks = if @level_idx == 0 && wave_idx == 0 then 0 else 60
          game_object = create_game_object[object_type](@random_x_coord(), @random_y_coord(), invuln_ticks)
          @game_objects[game_object.guid] = game_object

          @setup_physics_for_game_object(game_object)

    else if levels[@level_idx + 1]?
      _.log "Advancing levels!"
      JERK_AIM_TIME = Math.ceil(JERK_AIM_TIME * 0.9)
      @level_idx += 1
      @prev_wave_spawned_by_level[@level_idx] = -1
      @level_start_time = _.now()
      return @start_next_wave_or_level()
    else
      _.log "hmm"


  start_collision_detection : ->
    #NOTE: This part of the code is a total shitshow. Trying to think of how to simplify.
    listener = new Box2D.Dynamics.b2ContactListener
    listener.PreSolve = (contact) =>
      guid_a = contact.GetFixtureA().GetBody().GetUserData()
      guid_b = contact.GetFixtureB().GetBody().GetUserData()
      if guid_a && guid_b && @game_objects[guid_a] && @game_objects[guid_b] # we dont care about boundaries for now
        # Sort the objects. This eliminates duplicate logic below
        if @game_objects[guid_a].type < @game_objects[guid_b].type
          a = @game_objects[guid_a]
          b = @game_objects[guid_b]
        else
          a = @game_objects[guid_b]
          b = @game_objects[guid_a]

        if a.type == b.type == BULLET
          contact.SetEnabled(false)

        if a.type == BULLET && b.type == PARTICLE
          contact.SetEnabled(false)

        # ignore contacts between player and his own bullets
        if b.is_player && a.type == BULLET && a.source_object_guid == b.guid
          contact.SetEnabled(false)

        # player can't crash into invuln asteroid or jerk
        if (a.type == ASTEROID || a.type == JERK) && a.invuln_ticks && b.is_player
          contact.SetEnabled(false)

        if a.type in DROP_TYPES || b.type in DROP_TYPES
          contact.SetEnabled(false)
          if b.is_player
            a.consume(b)
            a.hp = 0

        # else if a instanceof Particle && b instanceof Particle
        #   contact.SetEnabled(false)

    listener.PostSolve = (contact, impulse) =>
      force = Math.abs(impulse.normalImpulses[0]) * 8.5
      guid_a = contact.GetFixtureA().GetBody().GetUserData()
      guid_b = contact.GetFixtureB().GetBody().GetUserData()
      if guid_a && guid_b && @game_objects[guid_a] && @game_objects[guid_b]
        #Sort the objects. This eliminates duplicate logic below
        if @game_objects[guid_a].type < @game_objects[guid_b].type
          a = @game_objects[guid_a]
          b = @game_objects[guid_b]
        else
          a = @game_objects[guid_b]
          b = @game_objects[guid_a]

        force *= 120 if a.type == BULLET || b.type == BULLET

        #_.log "Collision between #{a.type} and #{b.type}"

        if a.type == ASTEROID && b.type == BULLET
          a.hp -= force
          b.hp = 0
        else if a.type == ASTEROID && b.type == ASTEROID
          a.hp -= force
          b.hp -= force
        else if a.type == ASTEROID && b.is_player
          #_.log "A-P force : #{force}"
          if force > 0.25 # so player can push shit around without getting hurt
            a.hp -= force
            b.hp -= force
        else if b.is_player && (a.type == BULLET && a.source_object_guid == b.guid)
          a.hp -= force
        else if a.type == JERK && b.is_player
          b.hp -= force
        else if a.type == BULLET && b.type == JERK
          b.hp -= force
          a.hp = 0

    @world.SetContactListener(listener)

  setup_physics_for_game_object: (game_object) ->
    body = if game_object.radius?
      @setup_circular_physics_body(game_object)
    else
      @setup_physics_for_polygon(game_object)

    if game_object.type == JERK
      body.SetAngularDamping(4.5)
      body.SetLinearDamping(1.5)

    if game_object.type == ASTEROID
      body.ApplyImpulse(new b2Vec2(_.random(-1, 1), _.random(-1, 1)), body.GetWorldCenter())

    body

  setup_physics_for_polygon: (game_object) ->
    fix_def = new b2FixtureDef
    fix_def.density = 1.0
    fix_def.friction = 0.5
    fix_def.restitution = 0.2
    body_def = new b2BodyDef
    body_def.type = b2Body.b2_dynamicBody
    fix_def.shape = new b2PolygonShape
    fix_def.restitution = 0.4
    shape_points = []
    for p in game_object.points
      vec = new b2Vec2
      vec.Set(p.x, p.y)
      shape_points.push(vec)
    fix_def.shape.SetAsArray(shape_points, shape_points.length)
    body_def.position.x = game_object.x
    body_def.position.y = game_object.y
    body_def.userData = game_object.guid
    #_.log guid
    return @world.CreateBody(body_def).CreateFixture(fix_def).GetBody()

  setup_circular_physics_body: (game_object) ->
    body_def = new b2BodyDef
    body_def.type = b2Body.b2_dynamicBody
    fix_def = new b2FixtureDef
    if game_object.type == BULLET
      fix_def.density = 0.20
    else
      fix_def.density = 1.0
    fix_def.friction = 0.5
    fix_def.restitution = 0.2

    fix_def.shape = new b2CircleShape(game_object.radius)
    fix_def.restitution = 0.4
    body_def.position.x = game_object.x
    body_def.position.y = game_object.y
    body_def.userData = game_object.guid
    @world.CreateBody(body_def).CreateFixture(fix_def).GetBody()

  setup_physics_for_bullet: (bullet) ->
    bullet_body = @setup_circular_physics_body(bullet)
    player_vel = @player_body.GetLinearVelocity()
    bullet_vel = new b2Vec2(
      player_vel.x + Math.cos(@player.angle) * BASE_BULLET_SPEED
      player_vel.y + Math.sin(@player.angle) * BASE_BULLET_SPEED
    )
    bullet_body.SetLinearVelocity(bullet_vel)
    # bullet_body.ApplyImpulse(new b2Vec2(Math.cos(@player.angle) * pow,
    #   Math.sin(@player.angle) * pow), @player_body.GetWorldCenter())

  shoot_bullet : (radius) ->
    x = @player.x + (@player.max_x + radius) * Math.cos(@player.angle)
    y = @player.y + (@player.max_x + radius) * Math.sin(@player.angle)
    #_.log "player [#{player.x}, #{@player.y}, #{player.angle}] bullet [#{x}, #{y}]"
    bullet = create_game_object[BULLET](radius, x, y, @player.guid)
    @game_objects[bullet.guid] = bullet
    @setup_physics_for_bullet(bullet)
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
    offset = if do_backwards then game_object.max_x + 0.1 else game_object.min_x - 0.1
    x = game_object.x + (offset + radius) * Math.cos(angle + PI % TWO_PI)
    y = game_object.y + (offset + radius) * Math.sin(angle + PI % TWO_PI)
    #_.log "player [#{player.x}, #{@player.y}, #{player.angle}] bullet [#{x}, #{y}]"
    particle = create_game_object[PARTICLE](radius, x, y)
    @game_objects[particle.guid] = particle
    body_def = new b2BodyDef
    body_def.type = b2Body.b2_dynamicBody
    fix_def = new b2FixtureDef
    fix_def.density = 0.5
    fix_def.friction = 5.0
    fix_def.restitution = 0.2

    fix_def.shape = new b2CircleShape(particle.radius)
    fix_def.restitution = 0.4
    body_def.position.x = particle.x
    body_def.position.y = particle.y
    body_def.userData = particle.guid
    particle_body = @world.CreateBody(body_def).CreateFixture(fix_def).GetBody()
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
    if @keys.SPACE
      if @player.fire_juice > BASE_BULLET_COST
        @shoot_bullet @player.bullet_radius
    # if @keys.SHIFT
    #   if @player.fire_juice > 0
    #     @shoot_bullet 0.20

  handle_jerk_ai : (jerk, jerk_body) ->
    dx =  player.x - jerk.x
    dy = player.y - jerk.y
    attack_angle = _.normalize_angle(Math.atan2(dy, dx))
    jerk_angle = jerk.angle
    angle_diff = _.normalize_angle(jerk_angle - attack_angle)
    _.log "dx : #{dx}, dy : #{dy}, Attack angle : #{attack_angle},
      angle delta : #{angle_diff}" if @num_update_ticks % 500 == 1
    is_off_screen = jerk.x > @width / SCALE || jerk.x < 0 || jerk.y < 0 || jerk.y > @width / SCALE
    if jerk.current_charge_start
      @gas(jerk, jerk_body, false, 0.07)
      if _.now() - jerk.current_charge_start > @jerk_charge_duration
        jerk.current_charge_start = null
    else if is_off_screen
      @gas(jerk, jerk_body, false, 0.07)
    else if Math.abs(angle_diff) < 0.05
      jerk.aim += 1
      if jerk.aim > JERK_AIM_TIME
        jerk.current_charge_start = _.now()
        _.log "ATTACK!"
    else
      jerk.aim = 0 if jerk.aim
      # look ahead 1/3 sec. Applying the right torque gets complicated when we're already spinning
      future_jerk_angle = jerk_angle + jerk_body.GetAngularVelocity() / 3.0
      torque = if _.is_clockwise_of(attack_angle, future_jerk_angle) then 0.1 else -0.1
      jerk_body.ApplyTorque(torque)


  update : _.benchmark () ->
    return if @finished
    @player.fire_juice += 0.5
    @player.fire_juice = MAX_PLAYER_FIRE_JUICE if @player.fire_juice > MAX_PLAYER_FIRE_JUICE #Math.min(@player.fire_juice, 100)

    @handle_keyboard_input()

    #bottom
    @world.Step(1 / 60, 10, 10)
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

  draw : _.benchmark () ->
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
