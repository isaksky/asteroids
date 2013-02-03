COLORS = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]

random = ( min, max ) ->
  if ( min && typeof min.length == 'number' && !!min.length )
    return min[ Math.floor( Math.random() * min.length ) ]
  if ( typeof max != 'number' )
    max = min || 1
    min = 0
  return min + Math.random() * (max - min)

class Asteroid
  constructor : (@points, @x, @y) ->
    @guid = get_guid()
    @color = random(COLORS)

  update : (state) ->
    @x = state.x
    @y = state.y
    @angle = state.angle

  draw : (ctx) ->
    ctx.save()
    ctx.translate(@x * SCALE, @y * SCALE)
    ctx.rotate(@angle)
    ctx.translate(-(@x) * SCALE, -(@y) * SCALE)
    ctx.fillStyle = @color

    ctx.beginPath()
    ctx.moveTo((@x + @points[0].x) * SCALE, (@y + @points[0].y) * SCALE)
    for point in @points
       ctx.lineTo((point.x + @x) * SCALE, (point.y + @y) * SCALE)
    ctx.lineTo((@x + @points[0].x) * SCALE, (@y + @points[0].y) * SCALE)
    ctx.closePath()
    ctx.fill()
    ctx.stroke()
    ctx.restore()

@Asteroid = Asteroid
