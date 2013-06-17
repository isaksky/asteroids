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

setup_physics_for_polygon = (game_object, world) ->
  fix_def = new b2FixtureDef
  fix_def.density = 1.0
  fix_def.friction = 0.5
  fix_def.restitution = 0.2
  body_def = new b2BodyDef
  body_def.type = b2Body.b2_dynamicBody
  fix_def.shape = new b2PolygonShape
  fix_def.restitution = 0.4
  shape_points = []
  unless game_object.points?
    debugger
  for p in game_object.points
    vec = new b2Vec2
    vec.Set(p.x, p.y)
    shape_points.push(vec)
  fix_def.shape.SetAsArray(shape_points, shape_points.length)
  body_def.position.x = game_object.x
  body_def.position.y = game_object.y
  body_def.userData = game_object.guid
  #_.log guid
  body = world.CreateBody(body_def) #.CreateFixture(fix_def).GetBody()
  Box2DSeparator.separate(body, fix_def, shape_points, SCALE)
  body

setup_circular_physics_body = (game_object, world) ->
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
  world.CreateBody(body_def).CreateFixture(fix_def).GetBody()

setup_physics_fns_by_type = {}

setup_physics_fns_by_type[SHIP] = (ship, world) ->
  fix_def = new b2FixtureDef
  fix_def.density = 1.0
  fix_def.friction = 0.5
  fix_def.restitution = 0.2
  fix_def.shape = new b2PolygonShape
  fix_def.restitution = 0.4

  fuselage_pts = _.map ship.points, (pt) ->
    vec = new b2Vec2
    vec.Set(pt.x, pt.y)
    vec

  #fuselage_pts = fuselage_pts.reverse()
  fix_def.shape.SetAsArray(fuselage_pts, fuselage_pts.length)

  body_def = new b2BodyDef
  body_def.type = b2Body.b2_dynamicBody
  body_def.position.x = ship.x
  body_def.position.y = ship.y
  body_def.userData = ship.guid
  body = world.CreateBody(body_def)

  Box2DSeparator.separate(body, fix_def, fuselage_pts, SCALE)
  body.CreateFixture(fix_def)
  body

setup_physics_fns_by_type[JERK] = _.compose (body) ->
  body.SetAngularDamping(4.5)
  body.SetLinearDamping(1.5)
  body
, setup_physics_for_polygon

setup_physics_fns_by_type[BUB] = (bub, world) ->
  # TODO: clean up this code repetition /w above
  fix_def = new b2FixtureDef
  fix_def.density = 1.0
  fix_def.friction = 0.5
  fix_def.restitution = 0.2
  fix_def.shape = new b2PolygonShape
  fix_def.restitution = 0.4

  fuselage_pts = _.map bub.points, (pt) ->
    vec = new b2Vec2
    vec.Set(pt.x, pt.y)
    vec

  fix_def.shape.SetAsArray(fuselage_pts, fuselage_pts.length)

  body_def = new b2BodyDef
  body_def.type = b2Body.b2_dynamicBody
  body_def.position.x = bub.x
  body_def.position.y = bub.y
  body_def.userData = bub.guid
  body = world.CreateBody(body_def)

  Box2DSeparator.separate(body, fix_def, fuselage_pts, SCALE)
  body.CreateFixture(fix_def)
  body.SetAngularDamping(4.5)
  body.SetLinearDamping(1.5)
  body

setup_physics_fns_by_type[SOB] = (sob, world) ->
  # TODO: clean up this code repetition /w above
  fix_def = new b2FixtureDef
  fix_def.density = 4.0
  fix_def.friction = 0.5
  fix_def.restitution = 0.2
  fix_def.shape = new b2PolygonShape
  fix_def.restitution = 0.4

  fuselage_pts = _.map sob.points, (pt) ->
    vec = new b2Vec2
    vec.Set(pt.x, pt.y)
    vec

  fix_def.shape.SetAsArray(fuselage_pts, fuselage_pts.length)

  body_def = new b2BodyDef
  body_def.type = b2Body.b2_dynamicBody
  body_def.position.x = sob.x
  body_def.position.y = sob.y
  body_def.userData = sob.guid
  body = world.CreateBody(body_def)

  Box2DSeparator.separate(body, fix_def, fuselage_pts, SCALE)
  body.CreateFixture(fix_def)
  body.SetAngularDamping(4.5)
  body.SetLinearDamping(1.5)
  body

setup_physics_fns_by_type[ASTEROID] = _.compose (body) ->
  body.ApplyImpulse(new b2Vec2(_.random(-1, 1), _.random(-1, 1)), body.GetWorldCenter())
  body
, setup_physics_for_polygon

setup_physics_fns_by_type[BULLET] = (bullet, world, player_body, player) ->
  body = setup_circular_physics_body(bullet, world)
  player_vel = player_body.GetLinearVelocity()
  bullet_vel = new b2Vec2(
      player_vel.x + Math.cos(player.angle) * BASE_BULLET_SPEED
      player_vel.y + Math.sin(player.angle) * BASE_BULLET_SPEED
    )
  body.SetLinearVelocity(bullet_vel)

setup_physics_fns_by_type[PARTICLE] = (particle, world) ->
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
  particle_body = world.CreateBody(body_def).CreateFixture(fix_def).GetBody()
  particle_body

@physics_helper =
  get_physics_setup_fn : (game_object) ->
    setup_physics_fns_by_type[game_object.type] || if game_object.radius? then setup_circular_physics_body else setup_physics_for_polygon
