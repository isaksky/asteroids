import_asteroids_globals(@)
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
b2RevoluteJointDef = Box2D.Dynamics.Joints.b2RevoluteJointDef
b2RevoluteJoint = Box2D.Dynamics.Joints.b2RevoluteJoint
b2DistanceJointDef = Box2D.Dynamics.Joints.b2DistanceJointDef
b2DistanceJoint = Box2D.Dynamics.Joints.b2DistanceJoint



class @Ai
  constructor : ({@world, @player, @player_body, @world_width, @world_height, @game_objects, @game_object_settings}) ->

  use_engine : (game_object, physics_body, pow = 0.04) ->
     physics_body.ApplyImpulse(new b2Vec2(Math.cos(game_object.angle) * pow,
       Math.sin(game_object.angle) * pow), physics_body.GetWorldCenter())
     game_object.engines_last_used_at = _.now()
     game_object.engine_power_last_applied = pow

@Ai.prototype[JERK] = (jerk, jerk_body) ->
  dx =  @player.x - jerk.x
  dy = @player.y - jerk.y
  attack_angle = _.normalize_angle(Math.atan2(dy, dx))
  jerk_angle = jerk.angle
  angle_diff = _.normalize_angle(jerk_angle - attack_angle)
  #_.log "dx : #{dx}, dy : #{dy}, Attack angle : #{attack_angle},
  #  angle delta : #{angle_diff}" if @num_update_ticks % 500 == 1
  is_off_screen = jerk.x > @world_width || jerk.x < 0 || jerk.y < 0 || jerk.y > @world_height
  if jerk.current_charge_start
    @use_engine(jerk, jerk_body, Math.max(0.07, @game_object_settings.jerk_base_engine_power * 3))
    if _.now() - jerk.current_charge_start > @game_object_settings.jerk_charge_duration
      jerk.current_charge_start = null
    jerk.aim -= 0.3 if jerk.aim
    jerk.aim = 0 if jerk.aim && jerk.aim < 0
  else if is_off_screen
    @use_engine(jerk, jerk_body, 0.07)
  else if Math.abs(angle_diff) < 0.05
    jerk.aim += 1
    if jerk.aim > JERK_AIM_TIME
      jerk.current_charge_start = _.now()
      _.log "ATTACK!"
  else
    jerk.aim -= 0.2 if jerk.aim
    jerk.aim = 0 if jerk.aim && jerk.aim < 0
    # look ahead 1/3 sec. Applying the right torque gets complicated when we're already spinning
    future_jerk_angle = jerk_angle + jerk_body.GetAngularVelocity() / 3.0
    torque = (if _.is_clockwise_of(attack_angle, future_jerk_angle) then 1 else -1) * Math.abs(angle_diff) * 0.5
    jerk_body.ApplyTorque(torque)



@Ai.prototype[BUB] = (bub, bub_body) ->
  dx =  @player.x - bub.x
  dy = @player.y - bub.y
  attack_angle = _.normalize_angle(Math.atan2(dy, dx))
  bub_angle = bub.angle
  angle_diff = _.normalize_angle(bub_angle - attack_angle)
  is_off_screen = bub.x > @world_width || bub.x < 0 || bub.y < 0 || bub.y > @world_height

  if is_off_screen
    @use_engine(bub, bub_body, @game_object_settings.bub_base_engine_power * 2)
  else
    # look ahead 1/3 sec. Applying the right torque gets complicated when we're already spinning
    future_bub_angle = bub_angle + bub_body.GetAngularVelocity() / 3.0
    torque = (if _.is_clockwise_of(attack_angle, future_bub_angle) then 1 else -1) * Math.abs(angle_diff) * 0.5
    bub_body.ApplyTorque(torque)
    #if Math.abs(angle_diff < 0.2)
    @use_engine(bub, bub_body, @game_object_settings.bub_base_engine_power) unless bub.invuln_ticks

@Ai.prototype[SOB] = (sob, sob_body) ->
  if !sob_body.GetJointList() #no asteroids yet?
    aabb = new b2AABB
    aabb.lowerBound.Set(sob.x - 1, sob.y - 1)
    aabb.upperBound.Set(sob.x + 1, sob.y + 1)
    sob.nearby_game_objects = {}
    sob.nearby_game_object_bodies = {}
    @world.QueryAABB (fixture) =>
      body = fixture.GetBody()
      guid = body.GetUserData()
      game_object = @game_objects[guid]
      if game_object.type == ASTEROID && !(sob.last_game_object_guid_released == guid && (_.now() - sob.last_released_at) < 1000)
        sob.nearby_game_objects[guid] = game_object
        sob.nearby_game_object_bodies[guid] = body
        false
      else
        true
    , aabb

    @use_engine(sob, sob_body, 0.2)
    #sob_body.ApplyImpulse(new b2Vec2(_.random(-1, 1), _.random(-1, 1)), sob_body.GetWorldCenter())
    #sob_body.ApplyImpulse(new b2Vec2(3,0), sob_body.GetWorldCenter())
    # the above thing is synchronous, so it is ok to do this:
    for guid, game_object of sob.nearby_game_objects
      body = sob.nearby_game_object_bodies[guid]
      unless body.GetJointList() # other object already attached to something?
        #joint_def = new b2DistanceJointDef
        joint_def = new b2RevoluteJointDef
        v = sob_body.GetPosition()
        #v = sob_body.GetLocalPoint(new b2Vec2(0.65,0.65))
        #v = new b2Vec2(0.65,0.65)
        joint_def.Initialize(sob_body, body, v)
        # joint_def.bodyA = sob_body
        # joint_def.bodyB = body
        # joint_def.localAnchorA = new b2Vec2(0,0 )#sob_body.GetLocalCenter()
        # joint_def.localAnchorB = new b2Vec2(0,0) #body.GetLocalCenter()
        #joint_def.anchorPoint = sob_body.GetLocalCenter()
        #joint_def.length = 1.5
        joint_def.collideConnected = true
        joint_def.lowerAngle = 0.1
        joint_def.upperAngle = 0.3
        joint_def.enableLimit = true
        joint = @world.CreateJoint(joint_def)
  else # we have an asteroid!
    if sob_body.GetAngularVelocity() < 3 # gather up speed
      sob_body.prev_torque ||= 3
      new_torque = sob_body.prev_torque += 0.1
      sob_body.ApplyTorque(new_torque)
      sob_body.prev_torque = new_torque
    else
      # Find out if we're aiming at the @player
      joint = sob_body.GetJointList().joint
      attached_body = joint.GetBodyB()
      attached_body_vel = attached_body.GetLinearVelocity()
      dx = @player.x - attached_body.GetPosition().x
      dy = @player.y - attached_body.GetPosition().y
      desired_attack_angle = _.normalize_angle(Math.atan2(dy, dx))
      actual_angle = _.normalize_angle(Math.atan2(attached_body_vel.y, attached_body_vel.x))

      if Math.abs(actual_angle - desired_attack_angle) < 0.05
        _.log "Releasing!!!"
        @world.DestroyJoint(joint)
        sob.last_released_at = _.now()
        sob.last_game_object_guid_released = attached_body.GetUserData()