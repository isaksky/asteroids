COLORS = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]

MIN_LINE_WIDTH = 0.5

class Asteroid
  constructor : (@points, @x, @y) ->
    @guid = get_guid()
    @color = _.random(COLORS)
    @hp = 100

  update : ({@x, @y, @angle}) ->

  draw : (ctx) ->
    ctx.save()
    ctx.globalCompositeOperation = "lighter"
    #ctx.globalAlpha = 0.6
    ctx.translate(@x * SCALE, @y * SCALE)
    ctx.rotate(@angle)
    ctx.translate(-(@x) * SCALE, -(@y) * SCALE)
    #ctx.fillStyle = @color
    ctx.strokeStyle = @color
    line_width = MIN_LINE_WIDTH + @hp * 4 / 100
    ctx.lineWidth = line_width

    ctx.beginPath()
    #ctx.moveTo((@x + @points[0].x) * SCALE, (@y + @points[0].y) * SCALE)
    for point, i in @points
      x_offset = 0
      # if point.x > @x
      #   x_offset = -line_width * 2
      # else if point.x < @x
      #   x_offset = line_width * 2

      y_offset = 0
      # if point.y > @y
      #   y_offset = -line_width * 2
      # else if point.y < @y
      #   y_offset = line_width * 2
      f = if i == 0 then 'moveTo' else 'lineTo'
      ctx[f](x_offset + ((point.x + @x) * SCALE), y_offset + ((point.y + @y) * SCALE))
    ctx.closePath()
    #ctx.fill()
    ctx.stroke()
    ctx.restore()

@Asteroid = Asteroid
