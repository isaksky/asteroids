_.mixin
  random : (min, max) ->
    if ( min && typeof min.length == 'number' && !!min.length )
      return min[ Math.floor( Math.random() * min.length ) ]
    if ( typeof max != 'number' )
      max = min || 1
      min = 0
    return min + Math.random() * (max - min)
