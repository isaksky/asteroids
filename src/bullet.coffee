COLORS = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]

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

  draw : (ctx) ->
    return if @hp <= 0
    ctx.save()
    ctx.globalCompositeOperation = "lighter"
    #ctx.globalAlpha = 0.6
    ctx.fillStyle = @color

    ctx.beginPath()
    ctx.arc(SCALE * (@x), SCALE * (@y), SCALE * @radius, 0, TWO_PI, true)

    ctx.closePath()
    ctx.fill()
    ctx.restore()
