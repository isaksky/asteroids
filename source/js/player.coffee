COLORS = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]
MIN_LINE_WIDTH = 0.75

class @Player
  constructor : (@x, @y) ->
    @guid = get_guid()
    @points = [
      {x: 0.75, y: 0}
      #{x: 0.15, y: 1}
      {x: 0, y: 0.25}
      #{x: -0.15, y: 0}
      {x: 0, y: -0.25}
      #{x:0.5, y:-1}
    ]
    @angle = 0
    @hp = 25
    @fire_juice = 0

  update : ({@x, @y, @angle}) ->

  draw : (ctx) ->
    inner_circle_size = 0.0  * SCALE
    gradient_size = 0.5 * SCALE
    x = @x * SCALE + (@max_x / 3 * SCALE) * Math.cos(@angle)
    y = @y * SCALE + (@max_x / 3 * SCALE) * Math.sin(@angle)
    ctx.save()

    ctx.beginPath()
    ctx.arc(x, y, gradient_size, 0, TWO_PI, true)
    gradient = ctx.createRadialGradient(x, y, 0, x, y, gradient_size)
    gradient.addColorStop(inner_circle_size / gradient_size, "rgba(255,255,255, 1)")
    gradient.addColorStop(0.01, "rgba(202,112,220,#{@fire_juice / 300})")
    gradient.addColorStop(1, "rgba(202,112,220,0)")
    ctx.fillStyle = gradient
    ctx.closePath()
    ctx.fill()
    ctx.restore()

    ctx.save()
    ctx.globalCompositeOperation = "lighter"
    #ctx.globalAlpha = 0.6
    ctx.translate(@x * SCALE, @y * SCALE)
    ctx.rotate(@angle)
    ctx.translate(-(@x) * SCALE, -(@y) * SCALE)
    #ctx.fillStyle = '#9370db'#'white'#'#32cd32'
    ctx.strokeStyle = '#9370db'#'white'#'#32cd32'
    ctx.lineWidth = MIN_LINE_WIDTH + @hp * 4 / 25
    ctx.beginPath()
    ctx.moveTo((@x + @points[0].x) * SCALE, (@y + @points[0].y) * SCALE)
    for point in @points
       ctx.lineTo((point.x + @x) * SCALE, (point.y + @y) * SCALE)
    ctx.lineTo((@x + @points[0].x) * SCALE, (@y + @points[0].y) * SCALE)
    ctx.closePath()
    ctx.stroke()
    ctx.restore()

    # ctx.fillStyle = "rgba(202,112,220,#{@fire_juice / 300})"#'white'#'#32cd32'
    # ctx.fill()
