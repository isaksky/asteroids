class @Particle
  @MAX_AGE : 400
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

  draw : (ctx) ->
    return if @hp <= 0
    age = _.now() - @start_time
    display_radius = SCALE * @radius * 5 # * (1 - age / Particle.MAX_AGE)
    ctx.save()
    #ctx.rotate(dToR(circle.rotation+185))
    #ctx.scale(1,1)
    ctx.beginPath()
    x = @x * SCALE
    y = @y * SCALE
    ctx.arc(x, y, display_radius, 0, TWO_PI, true)
    ctx.closePath()
    gradient3 = ctx.createRadialGradient(x, y, 0, x, y, display_radius)
        #(0, SCALE * @radius, 0, 0, SCALE * @radius, 30)
    gradient3.addColorStop(0.05, "rgba(255,255,255, #{0.7 * (1 - age / Particle.MAX_AGE)})")
    gradient3.addColorStop(1, "rgba(105, 210, 231, 0)") #'#69D2E7'
    ctx.fillStyle = gradient3
    ctx.fill()
    ctx.restore()
