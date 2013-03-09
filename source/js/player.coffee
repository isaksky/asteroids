COLORS = [ '#69D2E7', '#A7DBD8', '#E0E4CC', '#F38630', '#FA6900', '#FF4E50', '#F9D423' ]

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
    @hp = @max_hp = 25
    @fire_juice = 0


  update : ({@x, @y, @angle}) ->


    # ctx.fillStyle = "rgba(202,112,220,#{@fire_juice / 300})"#'white'#'#32cd32'
    # ctx.fill()
