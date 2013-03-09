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

calc_game_object_bounds = (game_object) ->
  return if game_object.min_x?
  if game_object.points?
    for p in game_object.points
      game_object.min_x = p.x if !game_object.min_x? || p.x < game_object.min_x
      game_object.max_x = p.x if !game_object.max_x? || p.x > game_object.max_x
      game_object.min_y = p.y if !game_object.min_y? || p.y < game_object.min_y
      game_object.max_y = p.y if !game_object.max_y? || p.y > game_object.max_y
  else
    throw new Error("Dont know how to calculate bounds for #{game_object.type}")

@game = Sketch.create
  container : document.getElementById "container"
  max_pixels : 1280 * 800
  setup : ->
    @score = @num_update_ticks = 0
    @finished = false
    @prev_spawn_time = _.now()
    @game_objects = {}
    num_asteroids = Math.floor(@height * @width * ASTEROIDS_PER_PIXEL)
    for n in [1..num_asteroids]
      random_points = random_polygon_points(_.random(0.25, 1), _.random(5, 8))
      asteroid = create_asteroid(random_points, random(@width / 10 / SCALE, (@width - @width / 10) / SCALE), _.random(@height / 10 / SCALE, (@height - @height / 10) / SCALE))
      @game_objects[asteroid.guid] = asteroid

    @player = create_ship(@width / SCALE / 2, @height / SCALE / 2)
    @player.is_player = true
    calc_game_object_bounds(@player)

    window.player = @player
    @game_objects[@player.guid] = @player

    gravity = new b2Vec2(0, 0)#random(-0.5, 0.5), random(-0.5, 0.5))
    allow_sleep = true
    @world = new b2World(gravity, allow_sleep)
    window.world = @world

    for guid, game_object of @game_objects
      #continue unless po?.points?
      fixture = @setup_physics_for_polygon game_object
      if game_object.type == ASTEROID
        fixture.GetBody().ApplyImpulse(new b2Vec2(_.random(-1, 1), _.random(-1, 1)), fixture.GetBody().GetWorldCenter())
      if game_object.is_player
        window.player_body = @player_body = fixture.GetBody()
        @player_body.SetAngularDamping(2.5)
        @player_body.SetLinearDamping(1)

    @start_collision_detection()

  start_collision_detection : ->
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
        #console.log "Collision between #{a.constructor.name} and #{b.constructor.name}"

        if a.type == b.type == BULLET
          contact.SetEnabled(false)

        # ignore contacts between player and his own bullets
        if b.is_player && a.type == BULLET && a.source_object_guid == b.guid
          contact.SetEnabled(false)

        if a.type == ASTEROID && a.invuln_ticks && b.is_player
          contact.SetEnabled(false)
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

        if a.type == ASTEROID && b.type == BULLET
          a.hp -= force
          b.hp = 0
        else if a.type == ASTEROID && b.type == ASTEROID
          a.hp -= force
          b.hp -= force
        else if a.type == ASTEROID && b.is_player
          #console.log "A-P force : #{force}"
          if force > 0.25 # so player can push shit around without getting hurt
            a.hp -= force
            b.hp -= force
          else if b.is_player && (a.type == BULLET && a.source_object_guid == b.guid)
            a.hp -= force

    @world.SetContactListener(listener)

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
    #console.log guid
    return @world.CreateBody(body_def).CreateFixture(fix_def)

  setup_physics_for_bullet: (bullet) ->
    body_def = new b2BodyDef
    body_def.type = b2Body.b2_dynamicBody
    fix_def = new b2FixtureDef
    fix_def.density = 1.0
    fix_def.friction = 0.5
    fix_def.restitution = 0.2

    fix_def.shape = new b2CircleShape(bullet.radius)
    fix_def.restitution = 0.4
    body_def.position.x = bullet.x
    body_def.position.y = bullet.y
    body_def.userData = bullet.guid
    bullet_body = @world.CreateBody(body_def).CreateFixture(fix_def).GetBody()
    pow = 0.1 * (bullet.radius / 0.05)
    pow *= 3 if bullet.radius > SMALLEST_BULLET_RADIUS
    bullet_body.SetLinearVelocity(@player_body.GetLinearVelocity())
    bullet_body.ApplyImpulse(new b2Vec2(Math.cos(@player.angle) * pow,
      Math.sin(@player.angle) * pow), @player_body.GetWorldCenter())

  shoot_bullet : (radius) ->
    x = @player.x + (@player.max_x + radius) * Math.cos(@player.angle)
    y = @player.y + (@player.max_x + radius) * Math.sin(@player.angle)
    #console.log "player [#{player.x}, #{@player.y}, #{player.angle}] bullet [#{x}, #{y}]"
    bullet = create_bullet(radius, x, y, @player.guid)
    @game_objects[bullet.guid] = bullet
    @setup_physics_for_bullet(bullet)
    @player.fire_juice -= radius * 50

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

  gas : (game_object, physics_body, do_backwards) ->
    angle = if do_backwards then (game_object.angle + PI) % TWO_PI else game_object.angle
    pow = 0.04#if do_backwards then 0.02 else 0.04
    physics_body.ApplyImpulse(new b2Vec2(Math.cos(angle) * pow,
      Math.sin(angle) * pow), physics_body.GetWorldCenter())

    radius = 0.1
    calc_game_object_bounds(game_object)
    offset = if do_backwards then game_object.max_x + 0.1 else game_object.min_x - 0.1
    x = game_object.x + (offset + radius) * Math.cos(angle + PI % TWO_PI)
    y = game_object.y + (offset + radius) * Math.sin(angle + PI % TWO_PI)
    #console.log "player [#{player.x}, #{@player.y}, #{player.angle}] bullet [#{x}, #{y}]"
    particle = create_particle(radius, x, y)
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

  update : ->
    return if @finished
    @player.fire_juice += 1.5
    @player.fire_juice = MAX_PLAYER_FIRE_JUICE if @player.fire_juice > MAX_PLAYER_FIRE_JUICE #Math.min(@player.fire_juice, 100)

    if @keys.UP
      @gas(@player, @player_body, false)
    if @keys.DOWN
      @gas(@player, @player_body, true)
    if @keys.LEFT
      @player_body.ApplyTorque(-0.2)
    if @keys.RIGHT
      @player_body.ApplyTorque(0.2)
    if @keys.SPACE
      if @player.fire_juice > 0
        @shoot_bullet 0.05
    if @keys.SHIFT
      if @player.fire_juice > 0
        @shoot_bullet 0.20

    #bottom
    @world.Step(1 / 60, 10, 10)
    @world.DrawDebugData() if @debug
    @world.ClearForces()

    graveyard = []
    body = @world.GetBodyList()
    @asteroids_remaining = 0
    while body?
      if body.GetUserData()?
        pos = body.GetPosition()
        game_object = @game_objects[body.GetUserData()]
        if game_object.hp <= 0
          graveyard.push(game_object)
          @world.DestroyBody(body)
          @finished = true if game_object == @player

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
      @asteroids_remaining += 1 if game_object.type == ASTEROID
      game_object.invuln_ticks -= 1 if game_object.invuln_ticks
      body = body.m_next

      for o in graveyard
        @score += 50 if o.type == ASTEROID
        delete @game_objects[o.guid]

    if @asteroids_remaining == 0
      @finished = true

    @prev_update_millis = @millis
    @spawn_enemies_tick() if @num_update_ticks % 20 == 1
    @num_update_ticks += 1

  spawn_enemies_tick: () ->
    time_since_last_spawn = _.now() - @prev_spawn_time
    min_delay = if @millis < 15000
      60000
    else if @millis < 25000
      40000
    else if @millis < 35000
      30000
    else if @millis < 40000
      7500
    else
      3500

    if time_since_last_spawn > min_delay
      console.log "Spawning enemy!"
      @prev_spawn_time = _.now()
      random_points = random_polygon_points(_.random(0.25, 1), _.random(5, 8))
      a = create_asteroid(random_points, random(@width / 10 / SCALE, (@width - @width / 10) / SCALE), _.random(@height / 10 / SCALE, (@height - @height / 10) / SCALE), 60)
      @game_objects[a.guid] = a
      fixture = @setup_physics_for_polygon(a)
      fixture.GetBody().ApplyImpulse(new b2Vec2(_.random(-1, 1), _.random(-1, 1)), fixture.GetBody().GetWorldCenter())

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

  draw : () ->
    return if @debug
    for key, game_object of @game_objects
      game_object_type_name = ENUM_NAME_BY_TYPE[game_object.type]
      drawing["draw_#{game_object_type_name}"](this, game_object)

    @draw_hp_bar()
    @draw_fire_juice_bar()

    @textAlign = "right"
    @font = "30px monospace"
    @strokeStyle = "#63D1F4"
    @strokeText("#{@score}", @width - 5, 30)

    if @finished
      @textAlign = "center"
      @font = "70px sans-serif"
      if @asteroids_remaining == 0
        @fillStyle = "#63D1F4"
        @fillText("YOU WIN", @width / 2 , @height / 2)
      else
        @fillStyle = '#f14'
        @fillText("GAME OVER", @width / 2 , @height / 2)
