-- Factorio-specific globals
globals = {
    "script",
    "defines",
    "game",
    "remote",
    "storage",
    "rendering",
    "prototypes",
    "table_size",
}


local defined_globals = {
    -- constants
    "MOD_PREFIX",
    "TAG_STARTING_STRUCTURE",
    "TAG_STARTING_ROBOPORT",
    "TAG_FIRST_ROBOPORT",
    "TICKING_TICKS",
    "TICKS_LANDED_WAIT",
    "TICKS_STAGING_WAIT",
    "TICKS_CONSTRUCTION_WAIT",
    "TICKS_POST_CONSTRUCTION_WAIT",
    "ROCKET_SEQUENCE_LAUNCH_TIME",
    "CONTROL_ROOM_SURFACE",
    "GUI_NAME",
    "GUI_OPEN_NAME",
    "LANDER_GUI_INNER_WIDTH",
    "FORCE_FINISHED_STARTUP_EVENT",
    "FORCE_INVALIDATED_EVENT",

    -- required modules (globals assigned)
    "wiretap",
    "math2dlib",
    "pos",
    "bb",
    "bnwutil",
    "BnwForce",
    "gui",
}

-- Mod-defined globals/constants in control.lua
read_globals = {
    "log",
    "unpack",
    "serpent",
    "helpers",
    unpack(defined_globals)
}

files["scenarios/bnw/globals.lua"] = {
    -- Defining some globals here
    new_globals = {
        unpack(defined_globals)
    },
    new_read_globals = {
        "script"
    },
}

-- Defaults
std = "lua52"

-- Optional: reduce noise from unused locals like `_`
unused_args = false