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
