get_guid = (() ->
  guid_idx = 0
  (() ->
    guid_idx += 1
    "#{guid_idx}"))()

@random_polygon_points = (radius, num_sides) ->
  angle_step = Math.PI * 2 / num_sides
  points = []
  angle = - (Math.PI / 2) #0 #angle_step
  for n in [1..num_sides]
    angle_adj = 0.2 * _.random(-angle_step, angle_step)
    radius_adj = 0.20 * _.random(-radius, radius)
    point =
      x: Math.cos(angle + angle_adj) * (radius + radius_adj)
      y: Math.sin(angle + angle_adj) * (radius + radius_adj)
    points.push(point)
    angle += angle_step
  points

@create_particle = (radius, x, y) ->
  particle =
    type    : PARTICLE
    x       : x
    y       : y
    radius  : radius
    hp      : 1
  particle.mass = radius / 100
  particle.guid = get_guid()
  particle.start_time = _.now()
  particle

@create_ship = (x,y) ->
  ship = {type: SHIP, x, y, angle: 0, hp: 25, max_hp: 25, fire_juice: 0}
  ship.guid = get_guid()
  ship.points = [
      {x: 0.75, y: 0}
      #{x: 0.15, y: 1}
      {x: 0, y: 0.25}
      #{x: -0.15, y: 0}
      {x: 0, y: -0.25}
      #{x:0.5, y:-1}
    ]
  ship

BULLET_COLORS = ["rgba(233, 244, 0, 0)", "rgba(233, 0, 0, 0)", "rgba(0, 244, 0, 0)", "rgba(0, 0, 255, 0)"]

@create_bullet = (radius, x, y, source_object_guid) ->
  bullet = {type: BULLET, radius, x, y, source_object_guid, hp: 1, mass : radius}
  bullet.guid = get_guid()
  bullet.start_time = _.now()
  bullet.color = _.random(BULLET_COLORS)
  bullet

ASTEROID_COLORS = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]

@create_asteroid = (points, x, y, invuln_ticks = 0) ->
  asteroid = {type: ASTEROID, points, x, y, invuln_ticks, hp: 100}
  asteroid.guid = get_guid()
  asteroid.color = _.random(ASTEROID_COLORS)
  asteroid
