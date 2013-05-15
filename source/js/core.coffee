# loljs imports
b2Vec2 = Box2D.Common.Math.b2Vec2
b2BodyDef = Box2D.Dynamics.b2BodyDef
b2Body = Box2D.Dynamics.b2Body
b2FixtureDef = Box2D.Dynamics.b2FixtureDef
b2Fixture = Box2D.Dynamics.b2Fixture
b2World = Box2D.Dynamics.b2World
b2MassData = Box2D.Collision.Shapes.b2MassData
b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
b2DebugDraw = Box2D.Dynamics.b2DebugDraw

LEVEL_INTRO_TIME = 2500

@game = Sketch.create
  container : document.getElementById "container"
  # Gotta turn things way down for people not using Chrome
  max_pixels :  if "Google Inc." == window.navigator?.vendor then 1280 * 800 else 800 * 600

  setup : ->
    @game_objects = {}
    @worker = new Worker("js/worker.js")
    @worker.onmessage = (e) =>
      if e.data.func_name == "log"
        console.log "Worker: #{e.data.arg}"
      if e.data.game_objects
        @game_objects = e.data.game_objects
        #@draw(e.data.game_objects)
        @update()

    @worker.postMessage
      func_name: 'init'
      arg :
        width : @width
        height: @height

  update : ->


  draw_hp_bar : ->
    bar_w = 100
    bar_h = 6
    @strokeStyle = "#cd5c5c"
    @strokeRect(10, 10, bar_w, bar_h)

    @fillStyle = "#cd5c5c"
    @fillRect(10, 10, (@player.hp / @player.max_hp) * bar_w,  bar_h)

  draw_fire_juice_bar : ->
    bar_w = 100
    bar_h = 6
    @strokeStyle = "#63D1F4"
    @strokeRect(10, 20, bar_w, bar_h)

    @fillStyle = "#63D1F4"
    @fillRect(10, 20, (@player.fire_juice / MAX_PLAYER_FIRE_JUICE) * bar_w,  bar_h)

  draw_score : () ->
    @textAlign = "right"
    @font = "30px monospace"
    @strokeStyle = "#63D1F4"
    @strokeText("#{@score}", @width - 5, 30)

  draw_level_intro : () ->
    d = _.now() - @level_start_time
    if d <= LEVEL_INTRO_TIME
      @textAlign = "center"
      @font = "50px monospace"
      eased_alpha = Math.sin(d / LEVEL_INTRO_TIME * Math.PI)
      @strokeStyle = "rgba(99, 209, 244, #{eased_alpha})"
      @strokeText("Level #{@level_idx + 1}", @width / 2, @height / 2 - 100)

  draw : (go) ->
    console.log "hmmm" unless go?
    return if @debug || !go?
    @worker.postMessage func_name: 'set_keys', arg: @keys
    for key, game_object of @game_objects
      game_object_type_name = ENUM_NAME_BY_TYPE[game_object.type]
      drawing["draw_#{game_object_type_name}"](this, game_object)

    # @draw_hp_bar()
    # @draw_fire_juice_bar()
    # @draw_score()
    # @draw_level_intro()


    if @finished
      @textAlign = "center"
      @font = "70px sans-serif"
      if @enemies_remaining == 0
        @fillStyle = "#63D1F4"
        @fillText("YOU WIN", @width / 2 , @height / 2)
      else
        @fillStyle = '#f14'
        @fillText("GAME OVER", @width / 2 , @height / 2)
