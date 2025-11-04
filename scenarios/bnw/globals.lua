MOD_PREFIX = "bravest-new-world-"

TAG_STARTING_STRUCTURE = "bravest-new-world-starting-structure"
TAG_STARTING_ROBOPORT =  "bravest-new-world-starting-roboport"
TAG_FIRST_ROBOPORT = "bravest-new-world-first-roboport"

TICKING_TICKS = 41
TICKS_LANDED_WAIT = 360
TICKS_STAGING_WAIT = 120
TICKS_CONSTRUCTION_WAIT = 720
TICKS_POST_CONSTRUCTION_WAIT = 120

-- TODO: dehardcode - When it becomes available from prototype - Factorio 2.1
ROCKET_SEQUENCE_LAUNCH_TIME = 800

CONTROL_ROOM_SURFACE = "bravest-new-world-control-room"
GUI_NAME = "deployment-interface"
GUI_OPEN_NAME = "deployment-open-interface"
GUI_LOCATION_TOOLTIP_NAME = "location-tooltip"
LANDER_GUI_INNER_WIDTH = 396

FORCE_FINISHED_STARTUP_EVENT = script.generate_event_name()
FORCE_FINISHED_LANDING_EVENT = script.generate_event_name()
FORCE_INVALIDATED_EVENT = script.generate_event_name()

wiretap = require("wiretap")
math2dlib = require("math2d")
pos, bb = math2dlib.position, math2dlib.bounding_box
bnwutil = require("bnw-util")
BnwForce = require("bnw-force")
gui = require("gui")
