g = {}

g.PI         = Math.PI
g.TWO_PI     = Math.PI * 2
g.HALF_PI    = Math.PI / 2
g.QUARTER_PI = Math.PI / 4

g.MAX_PARTICLE_AGE = 400
g.MIN_LINE_WIDTH = 1
g.MAX_PLAYER_FIRE_JUICE = 50
g.ASTEROIDS_PER_PIXEL = 15 / (800 * 600)
g.SMALLEST_BULLET_RADIUS = 0.05
g.SCALE = 60 #(innerWidth * innerHeight) * 60  / (1280 * 800)
g.BASE_BULLET_SPEED = 10
g.BASE_ORB_SPEED = 7
g.BASE_BULLET_COST = 3
g.BASE_ORB_COST = 9
g.BUB_INITIAL_ENGINE_POWER = 0.009
g.JERK_INITIAL_ENGINE_POWER = 0.01

g.ENUM_NAME_BY_TYPE = {}
def_enums = do =>
  enum_i = 0
  (vals...) =>
    vals.sort()
    for v in vals
      g[v] = enum_i
      g.ENUM_NAME_BY_TYPE[enum_i] = v.toLowerCase()
      enum_i += 1

def_enums "ASTEROID", "BULLET", "HEALTH_PACK", "JERK", "PARTICLE", "SHIP", "BULLET_RADIUS_POWERUP", "BUB", "SOB", "ORB", "SHARD"

g.POINTS_BY_TYPE = {}
g.POINTS_BY_TYPE[g.ASTEROID] = 50
g.POINTS_BY_TYPE[g.JERK] = 500
g.POINTS_BY_TYPE[g.BUB] = 400
g.POINTS_BY_TYPE[g.SOB] = 1500

# Percent of the time when a game object type will drop something when killed
g.DROP_PCT_BY_TYPE = {}
g.DROP_PCT_BY_TYPE[g.ASTEROID] = 0.01
g.DROP_PCT_BY_TYPE[g.JERK] = 0.15
g.DROP_PCT_BY_TYPE[g.BUB] = 0.10
g.DROP_PCT_BY_TYPE[g.SOB] = 0.25

g.DROP_TYPES = [g.HEALTH_PACK, g.BULLET_RADIUS_POWERUP]

# How much space is there beyond the edge of the screen?
# We dont want objects to just wrap before they have completely dissapeared
# Find the biggest radius for all objects, and use that :
# unless body.m_max_radius?
#   body.m_max_radius = g.game_objects[body.GetUserData()].radius
# unless body.m_max_radius? # probably polygon then
#   vertices = body.GetFixtureList()?.GetShape()?.GetVertices()
#   body.m_max_radius = _.max _.map(vertices, (v) -> Math.sqrt(v.x * v.x + v.y * v.y))

# g.global_max_radius ||= 0
# g.global_max_radius = Math.max(g.global_max_radius, body.m_max_radius)
# window.gm = g.global_max_radius
#offset = body.m_max_radius

# btw flipping with an offset based on the object causes problems with unnatural collisions
# around the edges, so just keep fixed for all objects.
g.EDGE_OFFSET = 1.18 # this is the max radius i've observed using the logic above.

g.JERK_AIM_TIME = 60
g.JERK_CHARGE_DURATION_PIXEL_COEFF = 1250 / (800 * 600)

@import_asteroids_globals = (ctx) ->
  for k, v of g
    ctx[k] = v
