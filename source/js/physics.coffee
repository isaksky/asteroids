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

PI         = Math.PI
TWO_PI     = Math.PI * 2
HALF_PI    = Math.PI / 2
QUARTER_PI = Math.PI / 4

extract_contact_info = (contact) ->
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

@start_collision_detection = ->
  #NOTE: This part of the code is a total shitshow. Trying to think of how to simplify.
  listener = new Box2D.Dynamics.b2ContactListener
  listener.PreSolve = (contact) =>
    contact_info = extract_contact_info(contact)
    if contact_info.same_types && contact_info.both[0].type == BULLET
      contact.SetEnabled(false)
    else if (contact_info.same_types && contact_info.both[0].type == PARTICLE) || contact_info[PARTICLE]
      contact.SetEnabled(false)
    else if contact_info[SHIP] && contact_info[BULLET] &&
    contact_info[BULLET].source_object_guid != contact_info[SHIP].guid       # ignore contacts between ship and ship's own bullets
      contact.SetEnabled(false)
    else if (contact_info[ASTEROID]?.invuln_ticks || contact_info[JERK]?.invuln_ticks) && contact_info[SHIP]?.is_player
      contact.SetEnabled(false)       # player can't crash into invuln asteroid or jerk
    else if drop = _.clj_some(DROP_TYPES, (game_object_type) -> contact_info[game_object_type])
      contact.SetEnabled(false)
      if contact_info[SHIP]?.is_player
        @consume_powerup[drop.type](drop, contact_info[SHIP])
        #drop.consume(contact_info[SHIP])
        drop.hp = 0


      # else if a instanceof Particle && b instanceof Particle
      #   contact.SetEnabled(false)

  listener.PostSolve = (contact, impulse) =>
    force = Math.abs(impulse.normalImpulses[0]) * 8.5
    contact_info = extract_contact_info(contact)
    force *= 120 if contact_info[BULLET]

    #log "Collision between #{a.type} and #{b.type}"

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
    else if contact_info[BULLET] && contact_info[JERK]
      contact_info[JERK].hp -= force
      contact_info[BULLET].hp = 0

  @world.SetContactListener(listener)

@setup_physics_for_game_object = (game_object) ->
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

@setup_physics_for_polygon = (game_object) ->
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
  #log guid
  return @world.CreateBody(body_def).CreateFixture(fix_def).GetBody()

@setup_circular_physics_body = (game_object) ->
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

@setup_physics_for_bullet = (bullet) ->
  bullet_body = @setup_circular_physics_body(bullet)
  player_vel = @player_body.GetLinearVelocity()
  bullet_vel = new b2Vec2(
    player_vel.x + Math.cos(@player.angle) * BASE_BULLET_SPEED
    player_vel.y + Math.sin(@player.angle) * BASE_BULLET_SPEED
  )
  bullet_body.SetLinearVelocity(bullet_vel)
  # bullet_body.ApplyImpulse(new b2Vec2(Math.cos(@player.angle) * pow,
  #   Math.sin(@player.angle) * pow), @player_body.GetWorldCenter())

@shoot_bullet = (radius) ->
  x = @player.x + (@player.max_x + radius) * Math.cos(@player.angle)
  y = @player.y + (@player.max_x + radius) * Math.sin(@player.angle)
  #log "player [#{player.x}, #{@player.y}, #{player.angle}] bullet [#{x}, #{y}]"
  bullet = create_game_object[BULLET](radius, x, y, @player.guid)
  @game_objects[bullet.guid] = bullet
  @setup_physics_for_bullet(bullet)
  @player.fire_juice = Math.max(@player.fire_juice - BASE_BULLET_COST, 0)

@gas = (game_object, physics_body, do_backwards, pow = 0.04) ->
  angle = if do_backwards then (game_object.angle + PI) % TWO_PI else game_object.angle
  physics_body.ApplyImpulse(new b2Vec2(Math.cos(angle) * pow,
    Math.sin(angle) * pow), physics_body.GetWorldCenter())

  radius = 0.1
  offset = if do_backwards then game_object.max_x + 0.1 else game_object.min_x - 0.1
  x = game_object.x + (offset + radius) * Math.cos(angle + PI % TWO_PI)
  y = game_object.y + (offset + radius) * Math.sin(angle + PI % TWO_PI)
  #log "player [#{player.x}, #{@player.y}, #{player.angle}] bullet [#{x}, #{y}]"
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
