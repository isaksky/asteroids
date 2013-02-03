@requestAnimFrame =
  window.requestAnimationFrame       ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame    ||
  window.oRequestAnimationFrame      ||
  window.msRequestAnimationFrame     ||
  (callback, element) ->
    window.setTimeout(callback, 1000 / 60)

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

@SCALE = 60
@dbg_canvas = document.getElementById('c1')
@dbg_ctx = dbg_canvas.getContext('2d')
@canvas = document.getElementById('c0')
@ctx = canvas.getContext('2d')
WIDTH = @canvas.width / SCALE
HEIGHT = @canvas.height / SCALE
#@COLORS = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]

@get_guid = (() ->
  guid_idx = 0
  (() ->
    guid_idx += 1
    "#{guid_idx}"))()

@random = ( min, max ) ->
  if ( min && typeof min.length == 'number' && !!min.length )
    return min[ Math.floor( Math.random() * min.length ) ]
  if ( typeof max != 'number' )
    max = min || 1
    min = 0
  return min + Math.random() * (max - min)



@random_polygon_points = (radius, num_sides) ->
  angle_step = Math.PI * 2 / num_sides
  points = []
  angle = - (Math.PI / 2) #0 #angle_step
  for n in [1..num_sides]
    angle_adj = 0.2 * random(-angle_step, angle_step)
    radius_adj = 0.20 * random(-radius, radius)
    point =
      x: Math.cos(angle + angle_adj) * (radius + radius_adj)
      y: Math.sin(angle + angle_adj) * (radius + radius_adj)
    points.push(point)
    angle += angle_step
  points

@physics_objects = {}

for n in [0..15]
  random_points = random_polygon_points(random(0.25, 1), random(5, 8))
  asteroid = new Asteroid(random_points, random(WIDTH), random(HEIGHT))
  @physics_objects[asteroid.guid] = asteroid

gravity = new b2Vec2(random(-0.5, 0.5), random(-0.5, 0.5))
allow_sleep = true
@world = new b2World(gravity, allow_sleep)

fix_def = new b2FixtureDef
fix_def.density = 1.0
fix_def.friction = 0.5
fix_def.restitution = 0.2

#bottom
edge_padding = 0.05
body_def = new b2BodyDef
body_def.type = b2Body.b2_staticBody
body_def.position.x = canvas.width / 2 / SCALE
body_def.position.y = (canvas.height / SCALE)
fix_def.shape = new b2PolygonShape
fix_def.shape.SetAsBox((dbg_canvas.width / SCALE) / 2, edge_padding)
world.CreateBody(body_def).CreateFixture(fix_def)

#top
edge_padding = 0.05
body_def = new b2BodyDef
body_def.type = b2Body.b2_staticBody
body_def.position.x = canvas.width / 2 / SCALE
body_def.position.y = 0
fix_def.shape = new b2PolygonShape
fix_def.shape.SetAsBox((dbg_canvas.width / SCALE) / 2, edge_padding)
world.CreateBody(body_def).CreateFixture(fix_def)


#right
body_def = new b2BodyDef
body_def.type = b2Body.b2_staticBody
body_def.position.x = canvas.width / SCALE
body_def.position.y = (canvas.height / SCALE) / 2
fix_def.shape = new b2PolygonShape
fix_def.shape.SetAsBox(edge_padding, canvas.height / SCALE / 2)
world.CreateBody(body_def).CreateFixture(fix_def)

#left
body_def = new b2BodyDef
body_def.type = b2Body.b2_staticBody
body_def.position.x = 0
body_def.position.y = (canvas.height / SCALE) / 2
fix_def.shape = new b2PolygonShape
fix_def.shape.SetAsBox(edge_padding, canvas.height / SCALE / 2)
world.CreateBody(body_def).CreateFixture(fix_def)

for k of physics_objects
  po = physics_objects[k]
  #console.log k
  #console.log po
  continue unless po?.points?
  body_def.type = b2Body.b2_dynamicBody
  fix_def.shape = new b2PolygonShape
  fix_def.restitution = 0.4
  shape_points = []
  #for p in [{x: 0, y: -2}, {x: 2, y: 0}, {x: 0, y:2}, {x:-0.5, y: 1.5}]
  for p in po.points
    vec = new b2Vec2
    vec.Set(p.x, p.y)
    shape_points.push(vec)
  fix_def.shape.SetAsArray(shape_points, shape_points.length)
  body_def.position.x = po.x
  body_def.position.y = po.y
  body_def.userData = po.guid
  world.CreateBody(body_def).CreateFixture(fix_def)

debugDraw = new b2DebugDraw
debugDraw.SetSprite(dbg_ctx)
debugDraw.SetDrawScale(SCALE)
debugDraw.SetFillAlpha(0.3)
debugDraw.SetLineThickness(1.0)
debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)
@world.SetDebugDraw(debugDraw)

update = =>
  world.Step(1 / 60, 10, 10)
  world.DrawDebugData()
  world.ClearForces()
  canvas.width = canvas.width
  #SCALE = 60
  b = world.GetBodyList()

  while true
    break unless b?
    if b.GetUserData()?
      window.bb = b
      pos = b.GetPosition()
      physics_object = @physics_objects[b.GetUserData()]
      state =
        x : pos.x
        y : pos.y
        angle : b.GetAngle()

      physics_object.update(state)
      physics_object.draw(ctx)

    b = b.m_next

  requestAnimFrame(update)

setTimeout((-> requestAnimFrame(update)), 1200)
