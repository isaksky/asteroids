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
def_enums "ASTEROID", "BULLET", "JERK", "PARTICLE", "SHIP"

@POINTS_BY_TYPE = {}
POINTS_BY_TYPE[ASTEROID] = 50
POINTS_BY_TYPE[JERK] = 500

# How much space is there beyond the edge of the screen?
# We dont want objects to just wrap before they have completely dissapeared
# Find the biggest radius for all objects, and use that :
# unless body.m_max_radius?
#   body.m_max_radius = @game_objects[body.GetUserData()].radius
# unless body.m_max_radius? # probably polygon then
#   vertices = body.GetFixtureList()?.GetShape()?.GetVertices()
#   body.m_max_radius = _.max _.map(vertices, (v) -> Math.sqrt(v.x * v.x + v.y * v.y))

# @global_max_radius ||= 0
# @global_max_radius = Math.max(@global_max_radius, body.m_max_radius)
# window.gm = @global_max_radius
#offset = body.m_max_radius

# flipping with an offset based on the object causes problems with unnatural collisions
# around the edges, so just keep fixed for all objects.
@EDGE_OFFSET = 1.18 # this is the max radius i've observed using the logic above.

@JERK_AIM_TIME = 60
@JERK_CHARGE_DURATION_PIXEL_COEFF = 1250 / (800 * 600)
