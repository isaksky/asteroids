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
