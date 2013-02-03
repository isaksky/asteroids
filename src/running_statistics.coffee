class RunningStatistics
  constructor: ->
    @n = 0
  push: (v) ->
    @n += 1
    #See Knuth TAOCP vol 2, 3rd edition, page 232
    if (@n == 1)
      @old_mean = @new_mean = @min = @max = v
      @old_s = 0.0
    else
      @new_mean = @old_mean + ((v - @old_mean) / @n)
      @new_s = @old_s + ((v - @old_mean) * (v - @new_mean))
      #set up for next iteration
      @old_mean = @new_mean
      @old_s = @new_s
      @min = Math.min(@min, v)
      @max = Math.max(@max, v)
    v
  mean: ->
    if @n > 0 then @new_mean else 0.0
  variance: ->
    if @n > 1 then @new_s / (@n - 1) else 0.0
  stdev: ->
    Math.pow(@variance(), 0.5)
  maximum: ->
    @max
  minimum: ->
    @min
  reset: ->
    @n = 0

@RunningStatistics = RunningStatistics
