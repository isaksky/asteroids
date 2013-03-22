drawing =
  draw_asteroid : (ctx, asteroid) ->
    return if asteroid.invuln_ticks % 8 > 3
    ctx.save()
    ctx.globalCompositeOperation = "lighter"
    #ctx.globalAlpha = 0.6
    ctx.translate(asteroid.x * SCALE, asteroid.y * SCALE)
    ctx.rotate(asteroid.angle)
    ctx.translate(-asteroid.x * SCALE, -asteroid.y * SCALE)
    #ctx.fillStyle = asteroid.color
    ctx.strokeStyle = asteroid.color
    line_width = MIN_LINE_WIDTH + asteroid.hp * 4 / 100
    ctx.lineWidth = line_width
    #ctx.setLineDash([3]) if asteroid.invuln_ticks
    ctx.beginPath()
    #ctx.moveTo((asteroid.x + asteroid.points[0].x) * SCALE, (asteroid.y + asteroid.points[0].y) * SCALE)
    for point, i in asteroid.points
      x_offset = 0
      # if point.x > asteroid.x
      #   x_offset = -line_width * 2
      # else if point.x < asteroid.x
      #   x_offset = line_width * 2

      y_offset = 0
      # if point.y > asteroid.y
      #   y_offset = -line_width * 2
      # else if point.y < asteroid.y
      #   y_offset = line_width * 2
      f = if i == 0 then 'moveTo' else 'lineTo'
      ctx[f](x_offset + ((point.x + asteroid.x) * SCALE), y_offset + ((point.y + asteroid.y) * SCALE))
    ctx.closePath()
    #ctx.fill()
    ctx.stroke()
    ctx.restore()

  draw_ship : (ctx, player) ->
    inner_circle_size = 0
    gradient_size = 0.5 * SCALE
    x = player.x * SCALE + (player.max_x / 3 * SCALE) * Math.cos(player.angle)
    y = player.y * SCALE + (player.max_x / 3 * SCALE) * Math.sin(player.angle)
    ctx.save()

    ctx.beginPath()
    ctx.arc(x, y, gradient_size, 0, TWO_PI, true)
    gradient = ctx.createRadialGradient(x, y, 0, x, y, gradient_size)
    gradient.addColorStop(inner_circle_size / gradient_size, "rgba(255,255,255, 1)")
    gradient.addColorStop(0.01, "rgba(202,112,220,#{player.fire_juice / 300})")
    gradient.addColorStop(1, "rgba(202,112,220,0)")
    ctx.fillStyle = gradient
    ctx.closePath()
    ctx.fill()
    ctx.restore()

    ctx.save()
    ctx.globalCompositeOperation = "lighter"
    #ctx.globalAlpha = 0.6
    ctx.translate(player.x * SCALE, player.y * SCALE)
    ctx.rotate(player.angle)
    ctx.translate(-(player.x) * SCALE, -(player.y) * SCALE)
    #ctx.fillStyle = '#9370db'#'white'#'#32cd32'
    ctx.strokeStyle = '#9370db'#'white'#'#32cd32'
    ctx.lineWidth = MIN_LINE_WIDTH + Math.max(0, player.hp * 4 / 25)
    ctx.beginPath()
    ctx.moveTo((player.x + player.points[0].x) * SCALE, (player.y + player.points[0].y) * SCALE)
    for point in player.points
       ctx.lineTo((point.x + player.x) * SCALE, (point.y + player.y) * SCALE)
    ctx.lineTo((player.x + player.points[0].x) * SCALE, (player.y + player.points[0].y) * SCALE)
    ctx.closePath()
    ctx.stroke()
    ctx.restore()

  draw_jerk : (ctx, jerk) ->
    return if jerk.invuln_ticks % 8 > 3
    x = jerk.x * SCALE + (jerk.max_x / 3 * SCALE) * Math.cos(jerk.angle)
    y = jerk.y * SCALE + (jerk.max_x / 3 * SCALE) * Math.sin(jerk.angle)
    ctx.save()

    ctx.globalCompositeOperation = "lighter"
    #ctx.globalAlpha = 0.6
    ctx.translate(jerk.x * SCALE, jerk.y * SCALE)
    ctx.rotate(jerk.angle)
    ctx.translate(-(jerk.x) * SCALE, -(jerk.y) * SCALE)
    ctx.strokeStyle = jerk.color
    ctx.lineWidth = MIN_LINE_WIDTH + jerk.hp * 4 / jerk.max_hp
    ctx.beginPath()
    ctx.moveTo((jerk.x + jerk.points[0].x) * SCALE, (jerk.y + jerk.points[0].y) * SCALE)
    for point in jerk.points
       ctx.lineTo((point.x + jerk.x) * SCALE, (point.y + jerk.y) * SCALE)
    ctx.lineTo((jerk.x + jerk.points[0].x) * SCALE, (jerk.y + jerk.points[0].y) * SCALE)
    ctx.closePath()
    ctx.stroke()
    ctx.restore()

    if jerk.aim > 0
      ctx.save()
      pct_charged = jerk.aim / JERK_AIM_TIME
      gradient_size = 0.3 * SCALE# * pct_charged
      ctx.beginPath()
      ctx.arc(x, y, gradient_size, 0, TWO_PI, true)
      gradient = ctx.createRadialGradient(x, y, 0, x, y, gradient_size)
      gradient.addColorStop(0, "rgba(255, 0, 0, #{pct_charged * 0.75})")
      gradient.addColorStop(1, "rgba(255, 0, 0, 0)")
      ctx.fillStyle = gradient
      ctx.closePath()
      ctx.fill()
      ctx.restore()

  draw_bullet : (ctx, bullet) ->
    return if bullet.hp <= 0
    age = _.now() - bullet.start_time
    ctx.save()
    ctx.globalCompositeOperation = "lighter"
    #ctx.globalAlpha = 0.6
    ctx.fillStyle = bullet.color

    x = bullet.x * SCALE
    y = bullet.y * SCALE

    ctx.beginPath()
    if bullet.radius > SMALLEST_BULLET_RADIUS
      inner_circle_size = SCALE * bullet.radius * 0.95
      gradient_size = SCALE * bullet.radius * 2
      gradient = ctx.createRadialGradient(x, y, 0, x, y, gradient_size)
      gradient.addColorStop(inner_circle_size / gradient_size, "rgba(255,255,255, 1)")
      gradient.addColorStop(1, bullet.color) #'#69D2E7'
      ctx.fillStyle = gradient
      ctx.arc(x, y, gradient_size, 0, TWO_PI, true)
    else
      ctx.arc(x, y, bullet.radius * SCALE, 0, TWO_PI, true)
      ctx.fillStyle = bullet.color

    ctx.closePath()
    ctx.fill()
    ctx.restore()

  draw_particle : (ctx, particle) ->
    return if particle.hp <= 0
    age = _.now() - particle.start_time
    display_radius = SCALE * particle.radius * 5 # * (1 - age / MAX_PARTICLE_AGE)
    ctx.save()
    #ctx.rotate(dToR(circle.rotation+185))
    #ctx.scale(1,1)
    ctx.beginPath()
    x = particle.x * SCALE
    y = particle.y * SCALE
    ctx.arc(x, y, display_radius, 0, TWO_PI, true)
    ctx.closePath()
    gradient = ctx.createRadialGradient(x, y, 0, x, y, display_radius)
        #(0, SCALE * particle.radius, 0, 0, SCALE * particle.radius, 30)
    gradient.addColorStop(0.05, "rgba(255,255,255, #{0.7 * (1 - age / MAX_PARTICLE_AGE)})")
    gradient.addColorStop(1, "rgba(105, 210, 231, 0)") #'#69D2E7'
    ctx.fillStyle = gradient
    ctx.fill()
    ctx.restore()

  draw_health_pack : (ctx, health_pack) ->
    display_radius = SCALE * health_pack.radius # * (1 - age / MAX_PARTICLE_AGE)
    ctx.save()
    #ctx.rotate(dToR(circle.rotation+185))
    #ctx.scale(1,1)
    ctx.beginPath()
    x = health_pack.x * SCALE
    y = health_pack.y * SCALE
    ctx.arc(x, y, display_radius, 0, TWO_PI, true)
    ctx.closePath()
    ctx.fillStyle = "rgba(255,0,0,0.6)"
    ctx.fill()
    ctx.restore()

# loljs export
@drawing = drawing
