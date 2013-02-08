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
# @dbg_canvas = document.getElementById('c1')
# @dbg_ctx = dbg_canvas.getContext('2d')
# @canvas = document.getElementById('c0')
# @ctx = canvas.getContext('2d')

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

@wake_all = () ->
  b = world.GetBodyList()
  while true
    break unless b?
    if b.GetUserData()?
      b.SetAwake(true)
    b = b.m_next

@sketch = Sketch.create
  container : document.getElementById "container"
  setup : ->
    @game_objects = {}

    for n in [0..15]
      random_points = random_polygon_points(random(0.25, 1), random(5, 8))
      asteroid = new Asteroid(random_points, random(@width / SCALE), random(@height / SCALE))
      @game_objects[asteroid.guid] = asteroid

    @player = new Player(@width / SCALE / 2, @height / SCALE / 2)
    window.player = @player
    @game_objects[@player.guid] = @player

    gravity = new b2Vec2(random(-0.5, 0.5), random(-0.5, 0.5))
    allow_sleep = true
    @world = new b2World(gravity, allow_sleep)
    window.world = @world

    fix_def = new b2FixtureDef
    fix_def.density = 1.0
    fix_def.friction = 0.5
    fix_def.restitution = 0.2

    #bottom
    edge_padding = 0.05
    body_def = new b2BodyDef
    body_def.type = b2Body.b2_staticBody
    body_def.position.x = @width / 2 / SCALE
    body_def.position.y = (@height / SCALE)
    fix_def.shape = new b2PolygonShape
    fix_def.shape.SetAsBox((@width / SCALE) / 2, edge_padding)
    @world.CreateBody(body_def).CreateFixture(fix_def)

    #top
    edge_padding = 0.05
    body_def = new b2BodyDef
    body_def.type = b2Body.b2_staticBody
    body_def.position.x = @width / 2 / SCALE
    body_def.position.y = 0
    fix_def.shape = new b2PolygonShape
    fix_def.shape.SetAsBox((@width / SCALE) / 2, edge_padding)
    @world.CreateBody(body_def).CreateFixture(fix_def)

    #right
    body_def = new b2BodyDef
    body_def.type = b2Body.b2_staticBody
    body_def.position.x = @width / SCALE
    body_def.position.y = (@height / SCALE) / 2
    fix_def.shape = new b2PolygonShape
    fix_def.shape.SetAsBox(edge_padding, @height / SCALE / 2)
    @world.CreateBody(body_def).CreateFixture(fix_def)

    #left
    body_def = new b2BodyDef
    body_def.type = b2Body.b2_staticBody
    body_def.position.x = 0
    body_def.position.y = (@height / SCALE) / 2
    fix_def.shape = new b2PolygonShape
    fix_def.shape.SetAsBox(edge_padding, @height / SCALE / 2)
    @world.CreateBody(body_def).CreateFixture(fix_def)

    for guid, po of @game_objects
      #continue unless po?.points?
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
      #console.log guid
      if guid == "player"
        @player_body = @world.CreateBody(body_def).CreateFixture(fix_def).GetBody()
      else
        @world.CreateBody(body_def).CreateFixture(fix_def)

    listener = new Box2D.Dynamics.b2ContactListener
    listener.BeginContact = (contact) =>
      guid_a = contact.GetFixtureA().GetBody().GetUserData()
      guid_b = contact.GetFixtureB().GetBody().GetUserData()
      if guid_a && guid_b && @game_objects[guid_a] && @game_objects[guid_b] # we dont care about boundaries for now
        #console.log "collision between #{guid_a} and #{guid_b}"
        a = @game_objects[guid_a]
        b = @game_objects[guid_b]

        # Dont care about two bullets
        return if a.constructor.name == b.constructor.name == "Bullet"

        if a.constructor.name in ["Asteroid", "Player"]
          a.hp -= 3
        else if a.constructor.name == "Bullet"
          a.hp = 0
        if b.constructor.name in ["Asteroid", "Player"]
          b.hp -= 3
        else if b.constructor.name == "Bullet"
          b.hp = 0

    @world.SetContactListener(listener)

  update : ->
    if @keys.UP
      pow = 0.1
      @player_body.ApplyImpulse(new b2Vec2(Math.cos(@player.angle) * pow,
        Math.sin(@player.angle) * pow), @player_body.GetWorldCenter())
    if @keys.DOWN
      pow = 0.1
      @player_body.ApplyImpulse(new b2Vec2(-Math.cos(@player.angle) * pow, -Math.sin(@player.angle) * pow), @player_body.GetWorldCenter())
    if @keys.LEFT
      @player_body.ApplyTorque(-0.2)
    if @keys.RIGHT
      @player_body.ApplyTorque(0.2)
    if @keys.SPACE
      x = @player.x + 0.95 * Math.cos(@player.angle)
      y = @player.y + 0.95 * Math.sin(@player.angle)
      #console.log "player [#{player.x}, #{@player.y}, #{player.angle}] bullet [#{x}, #{y}]"
      bullet = new Bullet(0.05, x, y)
      @game_objects[bullet.guid] = bullet
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
      pow = 0.1
      bullet_body.ApplyImpulse(new b2Vec2(Math.cos(@player.angle) * pow,
        Math.sin(@player.angle) * pow), @player_body.GetWorldCenter())
      #bullet_body.SetBullet(true)
      #bullet_body.ApplyImpulse(new b2Vec2(Math.cos(@player.angle) * pow,
      #  Math.sin(@player.angle) * pow), @player_body.GetWorldCenter())

    #bottom
    edge_padding = 0.05
    body_def = new b2BodyDef

    window.pb = @player_body
    @world.Step(1 / 60, 10, 10)
    @world.DrawDebugData()
    @world.ClearForces()

    graveyard = []
    b = @world.GetBodyList()
    while true
      break unless b?
      if b.GetUserData()?
        window.bb = b
        pos = b.GetPosition()
        physics_object = @game_objects[b.GetUserData()]
        if physics_object.hp <= 0
          graveyard.push(physics_object)
          @world.DestroyBody(b)
        else
          state =
            x : pos.x
            y : pos.y
            angle : b.GetAngle()
          physics_object.update(state)
      b = b.m_next

    delete @game_objects[o.guid] for o in graveyard
    #@width = @width
    #SCALE = 60

    @prev_update_millis = @millis

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


  draw : () ->
    return if @debug
    for k, po of @game_objects
      po.draw(@)
