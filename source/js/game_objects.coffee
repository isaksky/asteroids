import_asteroids_globals(@)

@graveyards_by_type = {}
@graveyards_by_type[PARTICLE] = []
@graveyards_by_type[BULLET] = []

flip_around_hor = (pt) ->
  {x:pt.x, y: -pt.y}

reflect_finish = (pts) ->
  i = pts.length - 1
  while i
    pts.push(flip_around_hor(pts[i]))
    i--
  pts

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

get_guid = do ->
  guid_idx = 0
  ->
    guid_idx += 1
    "#{guid_idx}"

COLOR_PALLETE_1 = ["rgba(233, 244, 0, 0)", "rgba(233, 0, 0, 0)", "rgba(0, 244, 0, 0)", "rgba(0, 0, 255, 0)"]
COLOR_PALETTE_2 = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]

@create_game_object = {}

# Gotta use this type of object construction instead of object literal,
# because coffeescript doesn't eval the keys :(
@create_game_object[PARTICLE] = (radius, x, y) ->
  particle = graveyards_by_type[PARTICLE].pop() || {}
  particle.radius = radius
  particle.x = x
  particle.y = y
  particle.hp = 1

  particle.mass = radius / 100
  particle.start_time = _.now()
  particle

@create_game_object[SHIP] = (x,y) ->
  ship = {x, y, angle: 0, hp: 25, max_hp: 25, fire_juice: 0, bullet_radius: 0.05}
  ship.points = reflect_finish([{x: 0.75, y: 0}, {x: 0.2, y: 0.1}, {x: 0, y: 0.3}])
  calc_game_object_bounds(ship)
  ship

@create_game_object[BULLET] = (radius, x, y, source_object_guid) ->
  bullet = graveyards_by_type[BULLET].pop() || {}
  bullet.radius = radius
  bullet.x = x
  bullet.y = y
  bullet.source_object_guid = source_object_guid
  bullet.hp = 1
  bullet.mass = radius
  bullet.start_time = _.now()
  bullet.color = if radius > SMALLEST_BULLET_RADIUS then _.random(COLOR_PALLETE_1) else _.random(COLOR_PALETTE_2)
  bullet

@create_game_object[ASTEROID] = (x, y, invuln_ticks = 0, points = null) ->
  unless points?
    points = util.random_polygon_points(_.random(0.25, 1), _.random(5, 8))
  asteroid = {points, x, y, invuln_ticks, hp: 30}
  asteroid.color = _.random(COLOR_PALETTE_2)
  calc_game_object_bounds(asteroid)
  asteroid

@create_game_object[JERK] = (x, y, invuln_ticks = 0) ->
  jerk = {x, y, invuln_ticks, aim: 0, current_charge_start: null}
  jerk.color = '#cd6090'
  jerk.hp = jerk.max_hp = 20
  jerk.points = [
    {x: 1, y: 0}
    {x: 0.6, y: 0.2}
    {x: 0, y: 0.3}
    {x: 0, y:-0.3}
    {x: 0.6, y: -0.2}
    ]
  calc_game_object_bounds(jerk)
  jerk

@create_game_object[BUB] = (x, y, invuln_ticks = 30) ->
  bub = {x, y, invuln_ticks}
  bub.color = '#24913C'
  bub.hp = bub.max_hp = 15
  bub.points = reflect_finish([{x: 0.475, y: 0}, {x: 0.375, y: 0.1}, {x : 0.15, y : 0.1}, {x: 0, y: 0.2}]) #reflect_finish([{x: 0.75, y: 0}, {x: 0.6, y: 0.2}, {x: 0, y: 0.3}])
  calc_game_object_bounds(bub)
  bub

@create_game_object[SOB] = (x, y, invuln_ticks = 0) ->
  sob = {x, y, invuln_ticks}
  sob.color = '#FFBC00'
  sob.hp = sob.max_hp = 350
  sob.points = _.revolve_points_in_quadrant([{x:0.65, y: 0}, {x : 0.17, y : 0.17}, {x : 0, y: 0.65}])
  calc_game_object_bounds(sob)
  sob

@create_game_object[HEALTH_PACK] = (x, y, amt = 8) ->
  powerup = {x, y, hp:1}
  powerup.radius = 0.2
  powerup.color = "#cd5c5c"
  powerup.consume = (ship) ->
    ship.hp = Math.min(ship.hp + amt, ship.max_hp)
  powerup

@create_game_object[BULLET_RADIUS_POWERUP] = (x, y) ->
  powerup = {x, y, hp:1}
  powerup.radius = 0.2
  powerup.color = "#0033ff"
  powerup.consume = (ship) ->
    ship.bullet_radius *= 1.02
  powerup

# Add the type field to all the game objects
for object_type, creation_fn of @create_game_object
  @create_game_object[object_type] = do (object_type) ->
    _.compose (game_object) ->
      game_object.type = parseInt(object_type, 10) # because the key will have gotten coerced to a string, which we dont want
      game_object.guid = get_guid()
      game_object
    , creation_fn
