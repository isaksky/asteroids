TWO_PI = Math.PI * 2
QUARTER_PI = Math.PI / 4

_.mixin
  random : (min, max) ->
    if ( min && typeof min.length == 'number' && !!min.length )
      return min[ Math.floor( Math.random() * min.length ) ]
    if ( typeof max != 'number' )
      max = min || 1
      min = 0
    return min + Math.random() * (max - min)

  now : Date.now || () -> (new Date).getTime()

  merge : (target, source) ->
    for k, v of source
      target[k] = v
    target

  each_unique_pair : (ary, fn) ->
    for i in [0...(ary.length - 1)]
      e1 = ary[i]
      for j in [(i+1)...ary.length]
        e2 = ary[j]
        fn(e1, e2)
    null

  # Normalize the angle to be between -PI and PI
  normalize_angle : (angle) ->
    two_pi = TWO_PI
    angle = angle % two_pi
    angle = (angle + two_pi) % two_pi
    if angle > Math.PI
      angle -= two_pi
    angle

  # Normalize the angle to be between 0 and 2 PI
  normalize_angle_pos : (angle) ->
    angle = angle % TWO_PI
    if angle < 0 || angle > TWO_PI
      Math.abs(TWO_PI - Math.abs(angle))
    else
      angle

  # Is a1 clockwise of a2?
  is_clockwise_of : (a1, a2) ->
    a1 = _.normalize_angle_pos(a1)
    a2 = _.normalize_angle_pos(a2)
    d =  _.normalize_angle(a1 - a2)
    d >= 0

  ease_in_out : (v) ->
    if v < 0.5
      4 * v * v * v
    else
      f = (2 * v) - 2
      0.5 * f * f * f + 1

  log : (msg) ->
    console?.log?(msg)

  # like http://clojuredocs.org/clojure_core/clojure.core/some
  clj_some : (list, pred) ->
    res = null
    for v in list
      res = pred(v)
      break if res
    res

  # revolve_points_in_quadrant : (pts) ->
  #   ret = pts.slice()
  #   for angle in [HALF_PI..(3 * HALF_PI)] by HALF_PI
  #     for pt in pts
  #       d = Math.sqrt(pt.x * pt.x + pt.y * pt.y)
  #       orig_angle = Math.atan2(pt.y, pt.x)
  #       new_angle = orig_angle + angle
  #       new_x = d * Math.cos(new_angle)
  #       new_y = d * Math.sin(new_angle)
  #       ret.push({x : new_x, y : new_y})
  #   ret

  revolve_points_in_quadrant : (pts) ->
    ret = pts.slice()
    # copy around vertical
    i = pts.length
    while i
      i -= 1
      pt_to_flip = pts[i]
      unless pt_to_flip.x == 0
        pt = {x: -pt_to_flip.x, y : pt_to_flip.y}
        ret.push(pt)

    # copy around horizontal
    i = ret.length
    while i
      i -= 1
      pt_to_flip = ret[i]
      unless pt_to_flip.y == 0
        pt = {x: pt_to_flip.x, y : -pt_to_flip.y}
        ret.push(pt)
    ret

  is_point_in_rect : (x, y, rect_x_min, rect_y_min, rect_x_max, rect_y_max) ->
    x >= rect_x_min && x <= rect_x_max && y >= rect_y_min && y <= rect_y_max

  frequencies : (xs) ->
    h = {}
    for x in xs
      h[x] ||= 0
      h[x] += 1
    h
