@MAX_PARTICLE_AGE = 400
@MIN_LINE_WIDTH = 0.5
@MAX_PLAYER_FIRE_JUICE = 150
@ASTEROIDS_PER_PIXEL = 15 / (800 * 600)
@SMALLEST_BULLET_RADIUS = 0.05
@SCALE = 60 #(innerWidth * innerHeight) * 60  / (1280 * 800)

def_enums = (() =>
  enum_i = 0
  ((vals...) =>
    for v in vals
      @[v] = enum_i
      enum_i += 1))()

def_enums "ASTEROID", "SHIP", "BULLET", "PARTICLE"
