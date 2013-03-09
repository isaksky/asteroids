class @Particle
  constructor : (radius, x, y) ->
    @init(radius, x, y)

  init : (@radius, @x, @y) ->
    @mass = @radius / 100 # i know
    @guid = get_guid()
    #@color = random(COLORS)
    @hp = 1
    @start_time = _.now()

  update : (state) ->
    @x = state.x
    @y = state.y
