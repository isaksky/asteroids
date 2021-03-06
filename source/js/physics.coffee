# TODO: clean up the repetition between the fns in this file

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

setup_physics_for_polygon = (game_object, world, seperate, density = 1.0) ->
  fix_def = new b2FixtureDef
  fix_def.density = density
  fix_def.friction = 0.5

  body_def = new b2BodyDef
  body_def.type = b2Body.b2_dynamicBody
  fix_def.shape = new b2PolygonShape
  fix_def.restitution = 0.4

  shape_pts = _.map game_object.points, (pt) ->
    vec = new b2Vec2
    vec.Set(pt.x, pt.y)
    vec
  fix_def.shape.SetAsArray(shape_pts, shape_pts.length)

  body_def.position.x = game_object.x
  body_def.position.y = game_object.y
  body_def.userData = game_object.guid
  body = world.CreateBody(body_def) #.CreateFixture(fix_def).GetBody()

  if seperate
    Box2DSeparator.separate(body, fix_def, shape_pts, SCALE)
  else
    body.CreateFixture(fix_def)

  if game_object.angle
    body.SetAngle(game_object.angle)

  body

setup_circular_physics_body = (game_object, world, density = 1.0) ->
  body_def = new b2BodyDef
  body_def.type = b2Body.b2_dynamicBody
  fix_def = new b2FixtureDef
  fix_def.density = density
  fix_def.friction = 0.5
  fix_def.restitution = 0.2

  fix_def.shape = new b2CircleShape(game_object.radius)
  fix_def.restitution = 0.4
  body_def.position.x = game_object.x
  body_def.position.y = game_object.y
  body_def.userData = game_object.guid
  world.CreateBody(body_def).CreateFixture(fix_def).GetBody()

setup_physics_fns_by_type = {}

setup_physics_fns_by_type[SHIP] = (ship, world) ->
  body = setup_physics_for_polygon(ship, world, true)
  body

setup_physics_fns_by_type[JERK] = (jerk, world) ->
  body = setup_physics_for_polygon(jerk, world, false)
  body.SetAngularDamping(4.5)
  body.SetLinearDamping(1.5)
  body

setup_physics_fns_by_type[BUB] = (bub, world) ->
  body = setup_physics_for_polygon(bub, world, false)
  body.SetAngularDamping(4.5)
  body.SetLinearDamping(1.5)
  body

setup_physics_fns_by_type[SOB] = (sob, world) ->
  body = setup_physics_for_polygon(sob, world, true, 4.0)
  body.SetAngularDamping(4.5)
  body.SetLinearDamping(1.5)
  body

setup_physics_fns_by_type[ASTEROID] = (asteroid, world) ->
  body = setup_physics_for_polygon(asteroid, world, true)
  body.ApplyImpulse(new b2Vec2(_.random(-1, 1), _.random(-1, 1)), body.GetWorldCenter())
  body

setup_physics_fns_by_type[BULLET] = (bullet, world, player_body, player) ->
  body = setup_circular_physics_body(bullet, world, 0.2)
  player_vel = player_body.GetLinearVelocity()
  bullet_vel = new b2Vec2(
      player_vel.x + Math.cos(player.angle) * BASE_BULLET_SPEED
      player_vel.y + Math.sin(player.angle) * BASE_BULLET_SPEED
    )
  body.SetLinearVelocity(bullet_vel)

setup_physics_fns_by_type[ORB] = (orb, world, player_body, player) ->
  body = setup_circular_physics_body(orb, world, 0.2)
  player_vel = player_body.GetLinearVelocity()
  orb_vel = new b2Vec2(
      player_vel.x + Math.cos(player.angle) * BASE_ORB_SPEED
      player_vel.y + Math.sin(player.angle) * BASE_ORB_SPEED
    )
  body.SetLinearVelocity(orb_vel)
  body.ApplyTorque(0.2)

setup_physics_fns_by_type[PARTICLE] = (particle, world) ->
  body = setup_circular_physics_body(particle, world, 0.5)
  body

@physics_helper =
  get_physics_setup_fn : (game_object) ->
    setup_physics_fns_by_type[game_object.type] || if game_object.radius? then setup_circular_physics_body else setup_physics_for_polygon
