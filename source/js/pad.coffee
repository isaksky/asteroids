#= require underscore_mixins
#= require globals
#= require util
#= require drawing
#= require game_objects
#= require levels
#= require physics
#
import_asteroids_globals(@)

flip_around_hor = (pt) ->
  {x:pt.x, y: -pt.y}

reflect_finish = (pts) ->
  i = pts.length - 1
  while i
    pts.push(flip_around_hor(pts[i]))
    i--
  #pts.concat(_.map(flip_around_hor, _.drop(pts, 1)))
  pts

SCALE = 660

@s = Sketch.create
  container : document.getElementById "container"
  update : ->
  setup : ->

  draw : ->
      @save()
      @globalCompositeOperation = "lighter"
      #@globalAlpha = 0.6
      #@translate(asteroid.x * SCALE, asteroid.y * SCALE)
      #@rotate(asteroid.angle)
      @translate(0.2 * SCALE, 0.4 * SCALE)
      #@fillStyle = asteroid.color
      @strokeStyle = 'red'
      #line_width = MIN_LINE_WIDTH + asteroid.hp * 4 / 100
      @lineWidth = 1
      #@setLineDash([3]) if asteroid.invuln_ticks
      @beginPath()
      #@moveTo((asteroid.x + asteroid.points[0].x) * SCALE, (asteroid.y + asteroid.points[0].y) * SCALE)
      # pts = [
      #    {x: 0.75, y: 0}
      #    {x: 0.15, y: 1}
      #    {x: 0, y: 0.25}
      #    {x: -0.15, y: 0}
      #    {x: 0, y: -0.25}
      #    {x:0.5, y:-1}
      # ]
      pts = reflect_finish([{x: 0.75, y: 0}, {x: 0.2, y: 0.1}, {x: 0, y: 0.3}])
      !@p and console.log "pts : #{JSON.stringify(pts)}"
      @p = 1
      for point, i in pts
        f = if i == 0 then 'moveTo' else 'lineTo'
        @[f]((point.x) * SCALE, (point.y) * SCALE)
      @closePath()
      @stroke()

      for point, i in pts
        @strokeStyle = 'black'
        @strokeText('' + i + ' ' + JSON.stringify(point), point.x * SCALE, point.y * SCALE)
      @closePath()
      @stroke()


      #dbg
      @beginPath()
      @moveTo(-30 * SCALE, 0)
      @lineTo(30 * SCALE, 0)
      @stroke()
      @restore()
      @stop()
      #@fill()
