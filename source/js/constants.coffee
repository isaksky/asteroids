@MAX_PARTICLE_AGE = 400
@MIN_LINE_WIDTH = 1
@MAX_PLAYER_FIRE_JUICE = 50
@ASTEROIDS_PER_PIXEL = 15 / (800 * 600)
@SMALLEST_BULLET_RADIUS = 0.05
@SCALE = 60 #(innerWidth * innerHeight) * 60  / (1280 * 800)
@BASE_BULLET_SPEED = 10
@BASE_BULLET_COST = 3

@ENUM_NAME_BY_TYPE = {}
def_enums = (() =>
  enum_i = 0
  ((vals...) =>
    vals.sort()
    for v in vals
      @[v] = enum_i
      @ENUM_NAME_BY_TYPE[enum_i] = v.toLowerCase()
      enum_i += 1))()

def_enums "ASTEROID", "BULLET", "HEALTH_PACK", "JERK", "PARTICLE", "SHIP", "BULLET_RADIUS_POWERUP"

@POINTS_BY_TYPE = {}
POINTS_BY_TYPE[ASTEROID] = 50
POINTS_BY_TYPE[JERK] = 500

# Percent of the time when a game object type will drop something when killed
@DROP_PCT_BY_TYPE = {}
DROP_PCT_BY_TYPE[ASTEROID] = 0.01
DROP_PCT_BY_TYPE[JERK] = 0.25

@DROP_TYPES = [HEALTH_PACK, BULLET_RADIUS_POWERUP]

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

# btw flipping with an offset based on the object causes problems with unnatural collisions
# around the edges, so just keep fixed for all objects.
@EDGE_OFFSET = 1.18 # this is the max radius i've observed using the logic above.

@JERK_AIM_TIME = 60
@JERK_CHARGE_DURATION_PIXEL_COEFF = 1250 / (800 * 600)

# Stolen from http://jsfiddle.net/vWx8V/
@KEY_CODES_BY_NAME = {
  Backspace: 8, Tab: 9, Enter: 13, Shift: 16, Ctrl: 17, Alt: 18, "Pause/Break": 19, "Caps Lock": 20, Esc: 27, Space: 32
  "Page Up": 33, "Page Down": 34, End: 35, Home: 36, Left: 37, Up: 38, Right: 39, Down: 40, Insert: 45, Delete: 46, 0: 48
  1: 49, 2: 50, 3: 51, 4: 52, 5: 53, 6: 54, 7: 55, 8: 56, 9: 57, A: 65, B: 66, C: 67, D: 68, E: 69, F: 70, G: 71, H: 72
  I: 73, J: 74, K: 75, L: 76, M: 77, N: 78, O: 79, P: 80, Q: 81, R: 82, S: 83, T: 84, U: 85, V: 86, W: 87, X: 88, Y: 89
  Z: 90, Windows: 91, "Right Click": 93, "Numpad 0": 96, "Numpad 1": 97, "Numpad 2": 98, "Numpad 3": 99, "Numpad 4": 100
  "Numpad 5": 101, "Numpad 6": 102, "Numpad 7": 103, "Numpad 8": 104, "Numpad 9": 105, "Numpad *": 106, "Numpad +": 107
  "Numpad -": 109, "Numpad .": 110, "Numpad /": 111, F1: 112, F2: 113, F3: 114, F4: 115, F5: 116, F6: 117, F7: 118, F8: 119
  F9: 120, F10: 121, F11: 122, F12: 123, "Num Lock": 144, "Scroll Lock": 145, "My Computer": 182, "My Calculator": 183
  ";": 186, "=": 187, ",": 188, "-": 189, ".": 190, "/": 191, "`": 192, "[": 219, "\\": 220, "]": 221, "'": 222
}

@KEY_NAMES_BY_CODE = _.invert(KEY_CODES_BY_NAME)
