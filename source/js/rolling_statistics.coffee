class @RollingStatistics
  constructor : (@max = 60) ->
    @ary = new Array(@max)
    @i = 0 #what slot to place new value in
    @n = 0 #number of items

  push : (v) ->
    console.assert(_.isNumber(v))
    @ary[@i] = v
    @i = (@i + 1) % @max
    @n += 1 if @n < @max

  mean : ->
    avg = 0
    for j in [0...@n]
      avg += @ary[j] / @n
    avg
