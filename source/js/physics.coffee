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

@physics_helper =
    setup_physics_for : {}

@physics_helper.setup_physics_for[SHIP] = (ship, world) ->
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

  fuselage_pts = fuselage_pts.reverse()
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
