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
    @fire_juice = 300

  update : ({@x, @y, @angle}) ->

  draw : (ctx) ->
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
    #ctx.fill()
    ctx.stroke()
    ctx.restore()
