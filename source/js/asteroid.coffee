COLORS = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]



class @Asteroid
  constructor : (@points, @x, @y, @invuln_ticks = 0) ->
    @guid = get_guid()
    @color = _.random(COLORS)
    @hp = 100

  update : ({@x, @y, @angle}) ->
