

COLORS = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]
@stars = []
@asteroids = []

@sketch = Sketch.create
  container : document.getElementById "container"

  setup : ->
    # Set off some initial particles.
    num_stars = sketch.width * sketch.height / 1024
    for n in [1..num_stars]
      x = random(sketch.width)
      y = random(sketch.height)
      max_star_vel = 0.01
      x_vel = random(-max_star_vel, max_star_vel)
      y_vel = random(-max_star_vel, max_star_vel)
      stars.push({x, y, x_vel, y_vel})
      @prev_update_millis = @millis

    num_asteroids = 12
    for n in [1..num_asteroids]
      asteroid = gen_asteroid(@width, @height)
      asteroids.push(asteroid)

  update : ->
    duration = @millis - @prev_update_millis
    for star in stars
      update_star(star, duration)
    for asteroid in asteroids
      update_asteroid(asteroid, duration)
    for i in [0...(asteroids.length - 1)]
      a1 = asteroids[i]
      for j in [(i+1)...asteroids.length]
        a2 = asteroids[j]
        a1_com = center_of_mass(a1.points)
        a2_com = center_of_mass(a2.points)
        intersection = circles_intersect(a1_com.x, a1_com.y, a1.max_radius, a2_com.x, a2_com.y, a2.max_radius)
        if intersection
          n_intersections += 1
          #console.log "Intersection(#{intersection}) for #{i} and #{j}!!"
          # a1.y_vel /= -2
          # a1.x_vel /= -2
          # a2.x_vel /= -2
          # a2.y_vel /= -2


    @prev_update_millis = @millis

  draw : () ->
    sketch.globalCompositeOperation  = 'lighter'
    for star in stars
      draw_pixel(sketch, star.x, star.y)
    for asteroid in asteroids
      draw_asteroid(sketch, asteroid)

@woah = false
@n_intersections = 0
  # mousemove : ->
  #   for touch in sketch.touches
  #     max = random(4 ,4)
  #     sketch.spawn(touch.x, touch.y) for n in [1..max]

draw_pixel = (->
  img_data = sketch.createImageData(1,1)
  img_data_data = img_data.data
  img_data_data[0] = 255
  img_data_data[1] = 255
  img_data_data[2] = 255
  img_data_data[3] = 255
  (ctx, x, y) ->
    ctx.putImageData(img_data, x, y))()

update_star = (star, duration) ->
  star.x = star.x + star.x_vel * duration
  star.x = star.x % sketch.width

  star.y = star.y + star.y_vel * duration
  star.y = star.y % sketch.height

update_asteroid = (asteroid, duration) ->
  dx = asteroid.x_vel * duration
  dy = asteroid.y_vel * duration
  #console.log ["a", asteroid, "d", duration, dx, dy] if @i < 100
  translate_points(asteroid.points, dx, dy)
  rotate_points(asteroid.points, center_of_mass(asteroid.points), asteroid.torque * duration)
  world_rect = { min_x: 0, min_y: 0, max_x: sketch.width, max_y: sketch.height }
  br = bounding_rect(asteroid.points)
  comparison = rect_compare(br, world_rect)
  dx = dy = 0
  asteroid_width = (br.max_x - br.min_x)
  asteroid_height = (br.max_y - br.min_y)
  if comparison.x < 0
    dx = sketch.width + asteroid_width
  else if comparison.x > 0
    dx = -sketch.width - asteroid_width

  if comparison.y < 0
    dy = sketch.height + asteroid_height
  else if comparison.y > 0
    dy = -sketch.height - asteroid_height

  if dx || dy
    translate_points(asteroid.points, dx, dy)

@random_polygon_points = (origin, radius, num_sides) ->
  angle_step = Math.PI * 2 / num_sides
  points = []
  angle = angle_step
  max_radius = 0
  for n in [1..num_sides]
    angle_adj = 0.2 * random(-angle_step, angle_step)
    radius_adj = 0.20 * radius * random(-1, 1)
    delta_x = Math.cos(angle + angle_adj) * (radius + radius_adj)
    delta_y = Math.sin(angle + angle_adj) * (radius + radius_adj)
    point =
      x: origin.x + delta_x
      y: origin.y + delta_y
    points.push(point)
    if radius + radius_adj > max_radius
      max_radius = radius + radius_adj
    angle += angle_step
  {points, max_radius}

@gen_asteroid = (max_w, max_h) ->
  origin = { x: random(max_w), y: random(max_h) }
  radius = 30 + random(40)
  num_sides = 6 + random(4)
  {points, max_radius} = random_polygon_points(origin, radius, num_sides)
  asteroid_speed_range = 0.02
  x_vel = random(-asteroid_speed_range, asteroid_speed_range)
  y_vel = random(-asteroid_speed_range, asteroid_speed_range)
  torque = random(-0.0002, 0.0002)
  color = random(COLORS)
  { points, x_vel, y_vel, torque, max_radius, color }

@color = "#0ab"
@draw_polygon = (ctx, points, color) ->
  ctx.strokeStyle = color #@color
  ctx.beginPath()
  ctx.moveTo(points[0].x, points[0].y)
  for i in [1..(points.length - 1)]
    ctx.lineTo(points[i].x, points[i].y)
  ctx.closePath()
  ctx.stroke()

@draw_asteroid = (ctx, asteroid) ->
  draw_polygon(ctx, asteroid.points, asteroid.color)
