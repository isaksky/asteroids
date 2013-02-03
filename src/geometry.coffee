x_stats = new RunningStatistics
y_stats = new RunningStatistics

@center_of_mass = (points) ->
  x_stats.reset()
  y_stats.reset()
  for point in points
    x_stats.push(point.x)
    y_stats.push(point.y)
  center_of_mass =
    x: x_stats.mean()
    y: y_stats.mean()

@bounding_rect = (points) ->
  x_stats.reset()
  y_stats.reset()
  for point in points
    x_stats.push(point.x)
    y_stats.push(point.y)
  bounding_rect =
    min_x: x_stats.minimum()
    min_y: y_stats.minimum()
    max_x: x_stats.maximum()
    max_y: y_stats.maximum()

@translate_points = (points, dx, dy) ->
  #console.log ["ds", dx, dy]
  for point in points
    point.x += dx
    point.y += dy
  points

@center_of_mass = (points) ->
  x_stats.reset()
  y_stats.reset()
  for point in points
    x_stats.push(point.x)
    y_stats.push(point.y)
  center_of_mass =
    x: x_stats.mean()
    y: y_stats.mean()

@rotate_points = (points, pivot, dt) ->
  sin = Math.sin(dt)
  cos = Math.cos(dt)
  #console.log ["ds", dx, dy]
  for point in points
    dx = point.x - pivot.x
    dy = point.y - pivot.y
    new_dx = cos * dx - sin * dy
    new_dy = sin * dx + cos * dy
    point.x = pivot.x + new_dx
    point.y = pivot.y + new_dy
  points

@compare = (n1, n2) ->
  if n1 < n2
    -1
  else if n1 > n2
    1
  else
    0

@rect_compare = (r1, r2) ->
  x = y = null
  if r1.min_x >= r2.min_x && r1.max_x <= r2.max_x
    x = 0
  else if r1.min_x > r2.max_x
    x = r1.min_x - r2.max_x
  else if r1.max_x < r2.min_x
    x = r1.max_x - r2.min_x

  if r1.min_y >= r2.min_y && r1.max_y <= r2.max_y
    y = 0
  else if r1.min_y > r2.max_y
    y = r1.min_y - r2.max_y
  else if r1.max_y < r2.min_y
    y = r1.max_y - r2.min_y
  {x,y}

@circles_intersect = (c1x, c1y, c1r, c2x, c2y, c2r) ->
  cdx = c2x - c1x
  cdy = c2y - c2y
  center_delta = Math.sqrt(cdx * cdx + cdy * cdy)
  rsum = c1r + c2r
  if center_delta < rsum
    1 #intersect
  else if center_delta == rsum
    2 #touch
  else
    0 #no

@each_unique_pair = (ary, fn) ->
  for i in [0...(ary.length - 1)]
    e1 = ary[i]
    for j in [(i+1)...ary.length]
      e2 = ary[j]
      fn(e1, e2)
  null
