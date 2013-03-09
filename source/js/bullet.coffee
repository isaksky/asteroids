COLORS = ["rgba(233, 244, 0, 0)", "rgba(233, 0, 0, 0)", "rgba(0, 244, 0, 0)", "rgba(0, 0, 255, 0)"]

class @Bullet
  constructor : (radius, x, y, source_object_guid) ->
    @init(radius, x, y, source_object_guid)

  init : (@radius, @x, @y, @source_object_guid) ->
    @mass = @radius # i know
    @guid = get_guid()
    @color = _.random(COLORS)
    @hp = 1
    @start_time = _.now()

  update : (state) ->
    @x = state.x
    @y = state.y
