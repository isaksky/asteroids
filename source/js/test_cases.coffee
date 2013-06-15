import_asteroids_globals(@)

# to make testing the floating point arithmetic easier
Number.prototype.round = (places) ->
  Math.round(@ * Math.pow(10, places)) / Math.pow(10, places)

test "each unique pair", ->
  ary = [1,2,3,4]
  pairs = []
  _.each_unique_pair ary, (e1,e2) ->
    pairs.push([e1, e2])
  equal(6, pairs.length)

test "normalize_angle", ->
  HALF_PI = Math.PI / 2
  equal _.normalize_angle(1), 1
  equal _.normalize_angle(3), 3
  equal _.normalize_angle(Math.PI * 3 / 2), -Math.PI / 2
  equal _.normalize_angle(Math.PI * 4), 0
  equal _.normalize_angle(-Math.PI * 6), 0
  equal _.normalize_angle(HALF_PI * 3), -HALF_PI
  equal _.normalize_angle(Math.PI * 6.5).round(4), _.normalize_angle(-HALF_PI * 3).round(4)

test "normalize_angle_pos", ->
  equal _.normalize_angle_pos(0), 0
  equal _.normalize_angle_pos(Math.PI * 2), 0
  equal _.normalize_angle_pos(Math.PI * 3), Math.PI
  equal _.normalize_angle_pos(-Math.PI), Math.PI
  equal _.normalize_angle_pos(-Math.PI / 2), Math.PI * 3 / 2

test "is_clockwise_of", ->
  equal _.is_clockwise_of(2,1), true
  equal _.is_clockwise_of(2,3), false
  equal _.is_clockwise_of(Math.PI * 2, -Math.PI), true
  for i in [0..12]
    a1 = (i + 1) * 0.5
    a2 = i * 0.5
    equal _.is_clockwise_of(a1, a2), true, "#i: #{i}"

test "revolve_points_in_quadrant", ->
  deepEqual _.revolve_points_in_quadrant([{x:1,y:1}]), [{"x":1,"y":1},{"x":-1,"y":1},{"x":-1,"y":-1},{"x":1,"y":-1}]
  # dont duplicate points that lie on axis
  equal _.revolve_points_in_quadrant([{x:1,y:0}, {x:0.1, y:0.1}, {x:0, y:1}]).length, 8
