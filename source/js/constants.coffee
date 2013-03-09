@MAX_PARTICLE_AGE = 400
@MIN_LINE_WIDTH = 1
@MAX_PLAYER_FIRE_JUICE = 150
@ASTEROIDS_PER_PIXEL = 15 / (800 * 600)
@SMALLEST_BULLET_RADIUS = 0.05
@SCALE = 60 #(innerWidth * innerHeight) * 60  / (1280 * 800)

@ENUM_NAME_BY_TYPE = {}
def_enums = (() =>
  enum_i = 0
  ((vals...) =>
    for v in vals
      @[v] = enum_i
      @ENUM_NAME_BY_TYPE[enum_i] = v.toLowerCase()
      enum_i += 1))()

# IMPORTANT!! : Keep these in alphabetical order. The collision detection functions depend on it.
def_enums "ASTEROID", "BULLET", "PARTICLE", "SHIP"
