COLORS = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]

random = ( min, max ) ->
  if ( min && typeof min.length == 'number' && !!min.length )
    return min[ Math.floor( Math.random() * min.length ) ]
  if ( typeof max != 'number' )
    max = min || 1
    min = 0
  return min + Math.random() * (max - min)

class Bullet
  constructor : (@radius, @x, @y) ->
    @guid = get_guid()
    @color = random(COLORS)
    @hp = 1

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
    ctx.arc(SCALE * (@x - @radius), SCALE * (@y - @radius), SCALE * @radius, 0, TWO_PI, true)

    ctx.closePath()
    ctx.fill()
    ctx.restore()

@Bullet = Bullet
