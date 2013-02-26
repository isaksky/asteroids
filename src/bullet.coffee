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

  draw : (ctx) ->
    return if @hp <= 0
    age = _.now() - @start_time
    ctx.save()
    ctx.globalCompositeOperation = "lighter"
    #ctx.globalAlpha = 0.6
    ctx.fillStyle = @color

    x = @x * SCALE
    y = @y * SCALE
    inner_circle_size = SCALE * @radius * 0.95
    gradient_size = SCALE * @radius * 2
    ctx.beginPath()
    ctx.arc(x, y, gradient_size, 0, TWO_PI, true)
    gradient = ctx.createRadialGradient(x, y, 0, x, y, gradient_size)
    gradient.addColorStop(inner_circle_size / gradient_size, "rgba(255,255,255, 1)")
    gradient.addColorStop(1, @color) #'#69D2E7'
    ctx.fillStyle = gradient
    ctx.closePath()
    ctx.fill()
    ctx.restore()
