test "rect_compare r1 fits inside r2", ->
  r1 = {min_x:200, min_y:200, max_x:300, max_y:300}
  r2 = {min_x:0, min_y:0, max_x:1200, max_y:1200}
  res = rect_compare(r1, r2)
  equal(res.x, 0)
  equal(res.y, 0)

test "rect_compare r1 to the left of r2", ->
  r1 = {min_x:200, min_y:200, max_x:300, max_y:300}
  r2 = {min_x:400, min_y:200, max_x:600, max_y:300}
  res = rect_compare(r1, r2)
  ok(res.x < 0)
  equal(res.y, 0)

test "rect_compare r1 below r2", ->
  r1 = {min_x:400, min_y:10, max_x:600, max_y:20}
  r2 = {min_x:400, min_y:200, max_x:600, max_y:300}
  res = rect_compare(r1, r2)
  equal(res.x, 0)
  ok(res.y < 0)

test "rect_compare r1 below and left of  r2", ->
  r1 = {min_x:0, min_y:0, max_x:10, max_y:10}
  r2 = {min_x:20, min_y:20, max_x:30, max_y:30}
  res = rect_compare(r1, r2)
  ok(res.x < 0)
  ok(res.y < 0)

test "rect_compare r1 above and right of  r2", ->
  r1 = {min_x:20, min_y:20, max_x:30, max_y:30}
  r2 = {min_x:0, min_y:0, max_x:10, max_y:10}
  res = rect_compare(r1, r2)
  ok(res.x > 0)
  ok(res.y > 0)

test "bounding rect", ->
  points = [{x:1, y:1}, {x:2, y:2}, {x:3, y:3}, {x:-1, y:-1}]
  r = bounding_rect(points)
  equal(r.min_x, -1)
  equal(r.max_x, 3)
  equal(r.min_y, -1)
  equal(r.max_y, 3)

test "circles intersect", ->
  equal(circles_intersect(5, 5, 1, 10, 10, 5), 1)
  equal(circles_intersect(5, 5, 2.5, 10, 10, 2.5), 2)

test "each unique pair", ->
  ary = [1,2,3,4]
  pairs = []
  each_unique_pair ary, (e1,e2) ->
    pairs.push([e1, e2])
  ok(pairs.length == 6)
