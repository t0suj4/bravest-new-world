require("globals")
local freeplay = require("__base__/script/freeplay/freeplay")

local default_quick_bar_slots = {
    ["default"] = {
        [1] = "transport-belt",
        [2] = "underground-belt",
        [3] = "splitter",
        [4] = "inserter",
        [5] = "long-handed-inserter",
        [6] = "medium-electric-pole",
        [7] = "assembling-machine-1",
        [8] = "small-lamp",
        [9] = "stone-furnace",
        [10] = "electric-mining-drill",
        [11] = "roboport",
        [12] = "storage-chest",
        [13] = "requester-chest",
        [14] = "passive-provider-chest",
        [15] = "buffer-chest",
        [16] = "gun-turret",
        [17] = "stone-wall",
        [18] = nil,
        [19] = nil,
        [20] = "radar",
        [21] = "offshore-pump",
        [22] = "pipe-to-ground",
        [23] = "pipe",
        [24] = "boiler",
        [25] = "steam-engine",
        [26] = "burner-inserter",
    }
}

-- luacheck: push ignore
--- @class InventoryItem
--- @field name string
--- @field count number
--- @field quality? string
local _

--- @class EquipmentItem
--- @field x number
--- @field y number
--- @field item string
--- @field quality? string
local _

--- @class CreateForceOptions
--- @field force LuaForce
--- @field player? LuaPlayer
--- @field home {position: Position, surface: LuaSurface}
--- @field control_room {position: Position, surface: LuaSurface}
--- @field launch_type string "initial" | "launch" | "creative"
local _
-- luacheck: pop

--- @type table<planet:string, table<inventory:string, InventoryItem[]>>
local starting_inventory = {
    ["default"] = {
        ["roboport-robots-1"] = {
            { name = "construction-robot", count = 100 },
            { name = "logistic-robot", count = 50 },
        },
        ["roboport-material-1"] = {
            { name = "repair-pack", count = 10 },
        },
        ["chest-1"] = {
            { name = "transport-belt", count = 400 },
            { name = "underground-belt", count = 20 },
            { name = "splitter", count = 10 },
            { name = "inserter", count = 20 },
            { name = "burner-inserter", count = 4 },
            { name = "roboport", count = 4 },
            { name = "storage-chest", count = 2 },
            { name = "passive-provider-chest", count = 4 },
            { name = "requester-chest", count = 4 },
            { name = "pipe", count = 20 },
            { name = "pipe-to-ground", count = 10 },
            { name = "medium-electric-pole", count = 50 },
            { name = "small-lamp", count = 10 },
            { name = "gun-turret", count = 2 },
            { name = "firearm-magazine", count = 20 },
        },
        ["chest-2"] = {
            { name = "stone-furnace", count = 4 },
            { name = "offshore-pump", count = 1 },
            { name = "assembling-machine-1", count = 4 },
            { name = "buffer-chest", count = 4 },
            { name = "active-provider-chest", count = 4 },
            { name = "lab", count = 2 },
            { name = "electric-mining-drill", count = 4 },
            { name = "boiler", count = 1 },
            { name = "steam-engine", count = 2 },
        },
    }
}

local starting_blueprints = {
    -- luacheck: push no max line length
    ["default"] = "0eNqtmN1u3CAQhV+l4tqODAb/PUZ7uYoi1ku3SP4rxkmjyO9e7GzjtuvBjNq7tYQ/joczcNg3cm4mNRjdWVK9kbGTQ2z7+Gr0ZXn+QSrGI/JKqnKOiDyPfTNZFS/DBt1dSWXNpCIy9KO2uu9ioxpp9bP6i0HZysgcQ9d9N5Lq5ObS1042y4hOtopUxMGliQfZqYYsI7uLWt6dHyOiOusmUO8vrg+vT93UnpVxA6IPgO07Fb/IpiGbppuE8kGsGpIHMc/RHYQFQSj1U9IwSuKn8DBK6qeIMArzU7IwCvdT8mhvje8xNwrdpxQfFFnXUzs5q/XmnvLuV7pHKMN05H4dNEE5jgEUnG8hLQy3QJCYFIeB1PDAhc4OOCJsqVkCrzXNwrQwdqAFaV4OYFDuTXcRm31bddFTG6tG1dboOh76Rt2zxE1SCux5v/m4desdN7Id7inZAQXnY6A8jKEokJbNxqY/90Nv7N6WdytxRIz6PqnRPn3VjVVmXE9AV1H964jajqDd2TiuaaBPFzgM9O1Z0GrS/ACTI01GiwNggerlXeezEtnLQKnTBNOE+wgahsg8CBaGKDyIFNUuGVAOjqIIgLL518iLNJ7YBOn4I2UYeVVx/c31pSf0LKR/7d8UbfX0oBIFrpOhcpQ4DKCGB5qdeqzKA91OPV7lDLUB7DNS3CGcAyUJzCf8ACNwORLCZKj2gyg5ilIAlAJ3AYIwJe4GBGBEgt4Q8v+wIQiKu3lB6hnu6gVhkJkc8IdAphRIjUBGe0hOYCynB7YXOTISrJzHiLxos/6PcHJxWkTuDBCP0cmlnttvN0Jb1Trs9sdIRBp5dvCKfLHS2E+ft2z57Fy2TiYyVvKyFHnJU1Zm8/wTFvahvg=="
    -- luacheck: pop
}

local starting_technologies = {
    ["default"] = {
        "construction-robotics",
        "logistic-robotics",
        "logistic-system",
    }
}

--- @type EquipmentItem[]
local bot_spawner_equipment = {
    { x = 0, y = 0, item = "personal-roboport-mk2-equipment" },
    { x = 0, y = 2, item = "personal-roboport-mk2-equipment" },
    { x = 2, y = 0, item = "personal-roboport-mk2-equipment" },
    { x = 2, y = 2, item = "personal-roboport-mk2-equipment" },
    { x = 0, y = 4, item = "battery-mk2-equipment"},
    { x = 1, y = 4, item = "battery-mk2-equipment"},
    { x = 2, y = 4, item = "battery-mk2-equipment"},
    { x = 3, y = 4, item = "battery-mk2-equipment"},
    { x = 4, y = 0, item = "battery-mk2-equipment"},
    { x = 4, y = 2, item = "battery-mk2-equipment"},
    { x = 4, y = 4, item = "battery-mk2-equipment"},
}

local bot_spawner_extra_items = {
    { name = "construction-robot", count = 100 },
}

local planet_gifts = {
    ["default"] = {},
    ["fulgora"] = {
        { name = "lightning-rod", count = 10 },
    }
}

--- @class MiscSettings
--- @field water_replace_tile table<planet:string, string>
--- @field initial_pod_item string
--- @field bot_spawner_prototype string
--- @field bot_spawner_offset table<x:number, y:number>
--- @field bot_spawner_random_offset table<min:table<x:number, y:number>, max:table<x:number, y:number>>
--- @field bot_spawner_phase_capacity_bonus number
--- @field bot_spawner_fuel table<name:string>
--- @field construction_robot string
--- @field technology_clears_main_roboport string A technology which allows the main roboport to be mined or destroyed
---                                               without triggering end game

local misc_settings = {
    water_replace_tile = {
        ["default"] = "dirt-3",
        ["nauvis"] = "dirt-3",
        ["fulgora"] = "fulgoran-sand",
        ["vulcanus"] = "volcanic-ash-light",
        ["gleba"] = "midland-cracked-lichen-dull",
        ["aquilo"] = "snow-flat",
    },
    meltable_replace_tile = {
        ["default"] = "concrete",
    },
    initial_pod_item = "tank",
    bot_spawner_prototype = "tank",
    bot_spawner_offset = { x = 0, y = -4 },
    bot_spawner_random_offset = {
        min = { x = -4, y = -4},
        max = { x = 4, y = 0}}, -- y > 0 will obstruct ghosts
    bot_spawner_phase_capacity_bonus = 9,
    -- hides out of fuel alert
    bot_spawner_fuel = {name = "coal"},
    construction_robot = "construction-robot",
    technology_clears_main_roboport = {
        ["default"] = "tank"
    },
}

local config = {
    default_quick_bar_slots = default_quick_bar_slots,
    starting_inventory = starting_inventory,
    starting_blueprints = starting_blueprints,
    starting_technologies = starting_technologies,
    bot_spawner_equipment = bot_spawner_equipment,
    bot_spawner_extra_items = bot_spawner_extra_items,
    planet_gifts = planet_gifts,
    misc_settings = misc_settings,
}

local landing_states = {
    initial = "initial",
    events = {
        { name = "prepare", from = {"initial", "inactive"}, to = "ready" },
        -- Used only after the planet was already discovered by the force
        { name = "clear", from = "ready", to = "clearing" },
        { name = "launch", from = {"ready", "clearing"}, to = "launching" },
        { name = "ascend", from = "launching", to = "ascending" },
        { name = "ascended", from = "ascending", to = "descending" },
        { name = "land", from = "descending", to = "landed" },
        { name = "stage", from = "landed", to = "staging"},
        { name = "build", from = "staging", to = "constructing" },
        { name = "finalize", from = "constructing", to = "finalizing" },
        { name = "deactivate", from = "finalizing", to = "inactive" },
        -- I thought of adding "finished" as a definitely final state
        -- but that seemed unnecessarily restrictive
        { name = "invalidate", from = "*", to = "invalid" },
        { name = "revalidate", from = "invalid", to = "inactive"},
    }
}

local launch_common = {
    "inventory",
    "platform_index",
    "landing_location",
    "destination",
    "launch_type",
    "extra_tile_ghosts"}
local rest_common = {
    "blueprint_inventory",
    "player_index",
    "player_blueprint",
    unpack(launch_common)}
local begin_common = {
    "cargo_pod",
    unpack(rest_common)}
local valid_keys = {
    landing = {
        _all = {"state", "time"},
        initial = {"blueprint_inventory", "player_blueprint", unpack(launch_common)},
        inactive = {"blueprint_inventory", "player_blueprint", unpack(launch_common)},
        ready = begin_common,
        clearing = begin_common,
        launching = begin_common,
        ascending = begin_common,
        descending = begin_common,
        landed = {"awarded_capacity_bonus", "bot_spawner", unpack(rest_common)},
        staging = {"awarded_capacity_bonus", "bot_spawner", unpack(rest_common)},
        constructing = {"awarded_capacity_bonus", "bot_spawner", unpack(rest_common)},
    }
}
-- allows identity comparison
local ticking_spec = {"nth_tick", "handle_ticking", TICKING_TICKS}
local state_subs = {
    launching = { { defines.events.on_cargo_pod_started_ascending, "handle_ascending_pods" } },
    ascending = { { defines.events.on_cargo_pod_finished_ascending, "handle_ascended_pods" } },
    descending = { { defines.events.on_cargo_pod_finished_descending, "handle_descended_pods" } },
    landed = { ticking_spec },
    staging = { ticking_spec },
    constructing = { ticking_spec,
                     { defines.events.script_raised_revive, "materialize_items" },
                     { defines.events.script_raised_revive, "handle_construction" },
                     { defines.events.on_built_entity, "handle_construction" },
                     { defines.events.on_robot_built_entity, "handle_construction" } },
    finalizing = { ticking_spec },
}

local function validate_keys(what, against, from)
    local _all = against._all
    local keys = against[from] or {}
    for key in pairs(what) do
        for i=1,#_all do
            if key == _all[i] then
                goto skip
            end
        end
        for i=1,#keys do
            if key == keys[i] then
                goto skip
            end
        end
        bnwutil.raise_error("key: " .. key .. " should be cleaned up after state: " .. from, against)
        ::skip::
    end
end

local function manage_subs(from, to)
    local from_subs, to_subs = state_subs[from] or {}, state_subs[to] or {}
    local pending_unsub = {unpack(from_subs)}
    for j=1,#to_subs do
        local to_sub = to_subs[j]
        for i=1,#pending_unsub do
            local unsub = pending_unsub[i]
            if (unsub == to_sub) then
                pending_unsub[i] = false
                goto skip
            end
        end
        wiretap:subscribe(to_sub[1], to_sub[2], BnwForce.count(), to_sub[3])
        ::skip::
    end
    for i=1,#pending_unsub do
        if pending_unsub[i] then
            wiretap:unsubscribe(unpack(pending_unsub[i]))
        end
    end
end

local launch_callbacks = {
    onstatechange = function(_, event, from, to, force_name)
        manage_subs(from, to)
        local bnw_force = BnwForce.get(force_name)
        validate_keys(bnw_force.bnw.landing, valid_keys.landing, from)
        bnw_force.bnw.landing.time = game.tick
        log(serpent.block({event = event, from = from, to = to, force = force_name}))
        --game.print(serpent.block({event = event, from = from, to = to, force = force_name}))
    end,
    onenterready = function(_, _, _, _, force_name)
        local bnw_force = BnwForce.get(force_name)
        bnw_force:prepare_landing()
        if bnw_force:launch_type() == "platform" then
            bnw_force:stash_items()
        end
    end,
    onenterclearing = function(_, _, _, _, force_name)
        local bnw_force = BnwForce.get(force_name)
        bnw_force:clear_landing_zone()
    end,
    onenterascending = function(_, _, _, _, force_name)
        local bnw_force = BnwForce.get(force_name)
        bnw_force:fast_forward_voyage()
    end,
    onenterstaging = function(_, _, _, _, force_name)
        local bnw_force = BnwForce.get(force_name)
        bnw_force:stage()
    end,
    onafterstage = function(_, _, _, _, force_name)
        local bnw_force = BnwForce.get(force_name)
        bnw_force:clear_pod()
    end,
    onenterconstructing = function(_, _, _, _, force_name)
        local bnw_force = BnwForce.get(force_name)
        bnw_force:create_ghosts()
    end,
    onleaveconstructing = function(_, _, _, _, force_name)
        local bnw_force = BnwForce.get(force_name)
        if bnw_force:launch_type() == "platform" then
            bnw_force:clear_launch_items()
        end
    end,
    onbeforefinalize = function(_, _, _, _, force_name)
        local bnw_force = BnwForce.get(force_name)
        local finished, success = bnw_force:await_construction()
        if not success then
            bnw_force:trigger("invalidate")
        end
        return finished
    end,
    onenterfinalizing = function(_, _, _, _, force_name)
        local bnw_force = BnwForce.get(force_name)
        script.raise_event(FORCE_FINISHED_STARTUP_EVENT, {
            name = FORCE_FINISHED_STARTUP_EVENT,
            tick = game.tick,
            force_name = force_name,
            home = bnw_force.bnw.home,
        })
        bnw_force:deactivate()
    end,
    onenterinvalid = function(_, _, from, _, force_name)
        game.print("Error: force " .. force_name ..": encountered invalid state in " .. from)
        game.print("Please, reload previous save")
        script.raise_event(FORCE_INVALIDATED_EVENT, {
            name = FORCE_INVALIDATED_EVENT,
            tick = game.tick,
            force_name = force_name})
    end
}


wiretap:register_listener("handle_ascending_pods", function(event)
    local cargo_pod = event.cargo_pod
    if not (cargo_pod and cargo_pod.valid) then return end
    for force_name, force_data in pairs(storage.forces) do
        if cargo_pod == force_data.landing.cargo_pod then
            local bnw_force = BnwForce.get(force_name)
            bnw_force:trigger("ascend")
        end
    end
end)

wiretap:register_listener("handle_ascended_pods", function(event)
    local cargo_pod = event.cargo_pod
    if not (cargo_pod and cargo_pod.valid) then return end
    for force_name, force_data in pairs(storage.forces) do
        if force_data.landing.cargo_pod == cargo_pod then
            local bnw_force = BnwForce.get(force_name)
            bnw_force:trigger("ascended")
        end
    end
end)

wiretap:register_listener("handle_descended_pods", function(event)
    local cargo_pod = event.cargo_pod
    if not (cargo_pod and cargo_pod.valid) then return end
    for force_name, force_data in pairs(storage.forces) do
        if force_data.landing.cargo_pod == cargo_pod then
            local bnw_force = BnwForce.get(force_name)
            bnw_force:trigger("land")
        end
    end
end)

script.on_event(defines.events.on_cargo_pod_delivered_cargo, function(event)
    local cargo_pod = event.cargo_pod
    if not (cargo_pod and cargo_pod.valid) then return end
    for _, force_data in pairs(storage.forces) do
        if force_data.landing.cargo_pod == cargo_pod then
            force_data.landing.cargo_pod = event.spawned_container
        end
    end
end)

wiretap:register_listener("handle_ticking", function()
    for force_name in pairs(storage.forces) do
        local bnw_force = BnwForce.get(force_name)
        local elapsed = game.tick - bnw_force.bnw.landing.time
        if bnw_force:is("landed") and elapsed > TICKS_LANDED_WAIT then
            bnw_force:trigger("stage")
        elseif bnw_force:is("staging") and elapsed > TICKS_STAGING_WAIT then
            bnw_force:trigger("build")
        elseif bnw_force:is("constructing") and elapsed > TICKS_CONSTRUCTION_WAIT then
            bnw_force:trigger("finalize")
        elseif bnw_force:is("finalizing") and elapsed > TICKS_POST_CONSTRUCTION_WAIT then
            bnw_force:trigger("deactivate")
        end
    end
end)

local function create_control_room()
    local mgs = {
        width = 32,
        height = 32,
    }
    local surface = game.create_surface(CONTROL_ROOM_SURFACE, mgs)
    surface.generate_with_lab_tiles = true
    surface.show_clouds = false
    surface.create_global_electric_network()
    surface.freeze_daytime = true
    surface.no_enemies_mode = true
    surface.request_to_generate_chunks({0, 0}, 1)
    surface.force_generate_chunk_requests()

    storage.control_room = surface
    local silo = surface.create_entity{
        name = "rocket-silo",
        position = {0, 0},
        force = "neutral"}
    silo.destructible = false
    silo.minable_flag = false
    storage.neutral_launcher = silo

    local pod = surface.create_entity{
        name = "cargo-pod-container",
        surface = surface,
        force = "neutral",
        position = {-11.5, -11.5}}
    local inventory = pod.get_inventory(defines.inventory.chest)
    inventory.insert({name = "blueprint"})
    storage.preview_pod = pod


    script.on_nth_tick(300, function()
        local asteroids = surface.find_entities_filtered{force = "enemy"}
        for _, steroid in ipairs(asteroids) do
            steroid.die()
        end
    end)
    return surface
end

wiretap:register_listener("handle_construction", function(event)
    if not event.tags or event.tags[TAG_STARTING_STRUCTURE] == nil then
        return
    end

    local entity = event.entity
    if not (entity and entity.valid) then return end
    if entity.electric_buffer_size ~= nil then
        entity.energy = entity.electric_buffer_size
    end
    if entity.type == "roboport" then
        if event.tags[TAG_STARTING_ROBOPORT] ~= nil then
            storage.forces[entity.force.name].roboport = entity
            entity.minable_flag = false
        end
        if event.tags[TAG_FIRST_ROBOPORT] ~= nil then
            bnwutil.fill_entity_proxy_request(entity)
        end
    end
end)

wiretap:register_listener("materialize_items", function(event)
    if not event.tags or event.tags[TAG_STARTING_STRUCTURE] == nil then
        return
    end

    if not (event.entity and event.entity.valid) then return end
    bnwutil.fill_entity_proxy_request(event.entity)
end)

local function create_debug_platform(force, planet)
    local platform = force.create_space_platform{planet = planet, starter_pack = "space-platform-starter-pack"}

    platform.apply_starter_pack()
    local surface = platform.surface;

    surface.no_enemies_mode = true

    script.on_nth_tick(300, function()
        local asteroids = storage.platform.surface.find_entities_filtered{force = "enemy"}
        for _, steroid in ipairs(asteroids) do
            steroid.die()
        end
    end)

    storage.platform = platform
    return platform
end

script.on_event(defines.events.on_player_changed_surface, gui.handle_hiding_gui)

script.on_event(defines.events.on_player_died, gui.handle_hiding_gui)

script.on_event(defines.events.on_player_left_game, gui.handle_hiding_gui)

script.on_event(defines.events.on_player_controller_changed, gui.handle_hiding_gui)

script.on_event(defines.events.on_gui_closed, function(event)
    local player = game.get_player(event.player_index)
    local el = event.element
    if el and el.valid and el.name == MOD_PREFIX .. GUI_NAME then
        gui.hide_colonization_gui(player, event.tick, event.name)
    elseif not player.opened then
        local colonization_gui = player.gui.screen[MOD_PREFIX .. GUI_NAME]
        if colonization_gui
                and colonization_gui.valid
                and colonization_gui.visible then
            player.opened = colonization_gui
        end
    end
end)

script.on_event(defines.events.on_player_removed, function(event)
    BnwForce.remove_player(event.player_index)
    storage.players[event.player_index] = nil
end)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.entity and event.entity.valid then
        if event.entity == storage.neutral_launcher then
            local player = game.get_player(event.player_index)
            if not (player and player.valid) then return end
            local bnw_force = BnwForce.get(player.force.name)
            local zoom = player.zoom
            player.set_controller{
                type = defines.controllers.remote,
                position = bnw_force.bnw.home.position,
                surface = bnw_force.bnw.home.surface}
            player.zoom = zoom
        elseif event.entity and event.entity.prototype.type == "space-platform-hub" then
            local player = game.get_player(event.player_index)
            gui.ensure_button_gui_exists(player)
        end
    elseif event.gui_type == defines.gui_type.blueprint_library then
        -- Opening blueprint library won't close the GUI
        local player = game.get_player(event.player_index)
        local player_info = storage.players[event.player_index]
        if player_info
                and event.tick == player_info.launch_gui_closed_tick
                and player_info.launch_gui_closed_reason == defines.events.on_gui_closed then
            gui.show_colonization_gui(player, true)
        end
    end
end)

script.on_event(defines.events.on_string_translated, gui.handle_translation)

wiretap:register_listener("handle_refresh_inventory", gui.handle_refresh_inventory)
wiretap:register_listener("handle_refresh_tooltip", gui.handle_refresh_tooltip)

script.on_event(defines.events.on_gui_click, function(event)
    local button = event.element
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end

    if button.name == MOD_PREFIX .. "launch-colonization-pod" then
        gui.handle_launch_button(player, button, event)
    elseif button.name == MOD_PREFIX .. "item-button" then
        gui.handle_blueprint_button(player, button, event)
    elseif button.name == MOD_PREFIX .. "open-colonization-gui" then
        gui.show_colonization_gui(player)
    elseif button.name == MOD_PREFIX .. "close-colonization-gui" then
        gui.hide_colonization_gui(player)
    end
end)

script.on_event(defines.events.on_player_locale_changed, function(event)
    local player = game.get_player(event.player_index)
    if player and player.valid then
        local landing_gui = player.gui.screen[MOD_PREFIX .. GUI_NAME]
        local gui_button = player.gui.screen[MOD_PREFIX .. GUI_OPEN_NAME]
        if landing_gui and landing_gui.valid then
            landing_gui.destroy()
        end
        if gui_button and gui_button.valid then
            gui_button.destroy()
        end
        gui.create_guis_for_player(player)
    end
end)

local function initialize_objects()
    if not storage.control_room then
        create_control_room()
    end
end

--- @param o CreateForceOptions
local function create_force_with_player(o)
    local force = assert(o.force)
    local player = o.player
    local home = assert(o.home)
    local control_room = assert(o.control_room)
    local launch_type = assert(o.launch_type)
    gui.create_guis_for_player(player)
    local bnw_force = BnwForce.create{
        force = force,
        landing_states = landing_states,
        launch_callbacks = launch_callbacks,
        home = home,
        control_room = control_room}

    if player then
        log("Created bnw force: " .. force.name
                .. " with player: " .. player.name
                .. " data: " .. serpent.block(bnw_force.bnw))
    else
        log("Created bnw force: " .. force.name
                .. " with data: " .. serpent.block(bnw_force.bnw))
    end
    local debug_platform = "aquilo" and nil
    if bnw_force:is("initial") and not debug_platform then
        bnw_force:set_destination{
            use_offset = true,
            randomize_offset = true,
            launch_type = launch_type}
        if player then
            bnw_force:stash_player_character(player)
            bnw_force:player_cutscene(player)
        end
        bnw_force:create_pod(storage.neutral_launcher)
    elseif debug_platform then
        if player then
            bnw_force:stash_player_character(player, defines.controllers.remote)
        end
        create_debug_platform(force, debug_platform)
    end
end


local function on_player_created(event)
    local player = game.get_player(event.player_index)
    local surface = player.surface
    if not storage.init_ran then
        storage.init_ran = true
        surface.daytime = 0.7
        initialize_objects()
    end

    if not storage.setup_force_on_player_create then
        return
    end

    create_force_with_player{
        force = player.force,
        player = player,
        home = { position = player.force.get_spawn_position(surface), surface = surface.name },
        control_room = {position = {4, 4}, surface = storage.control_room.name},
        launch_type = "initial"}


    -- TODO: Handle cutscene during the startup sequence

    local qb_slots = bnwutil.get_planet_config(storage.config.default_quick_bar_slots, player.surface)

    -- Set-up a sane default for the quickbar
    for i, qb_slot in pairs(qb_slots) do
        if not player.get_quick_bar_slot(i) then
            if qb_slot then
                player.set_quick_bar_slot(i, qb_slot)
            end
        end
    end
end

if storage.init_ran or not script.active_mods["any-planet-start"] then
    script.on_event(defines.events.on_player_created, on_player_created)
else
    script.on_event("aps-post-init", function()
        for player_index in pairs (game.players) do
            on_player_created({player_index = player_index})
        end
        script.on_event("aps-post-init", nil)
        script.on_event(defines.events.on_player_created, on_player_created)
    end)
end

script.on_init(function()
    storage.forces = {}
    storage.subscribed_events = {}
    storage.players = {}
    storage.config = config
    storage.setup_force_on_player_create = true
    storage.pod_inventory_size = 10
    if remote.interfaces["freeplay"] then
        freeplay.on_init()
        remote.call("freeplay", "set_disable_crashsite", true)
        remote.call("freeplay", "set_skip_intro", true)
    end
    wiretap:init()
end)

script.on_load(function()
    wiretap:load()
    for force_name, data in pairs(storage.forces) do
        BnwForce.load{
            name = force_name,
            data = data,
            landing_states = landing_states,
            launch_callbacks = launch_callbacks}
    end
end)

script.on_configuration_changed(function(data)
    local bnw = data.mod_changes["bravest-new-world"]
    local new = bnw and bnw.new_version or nil
    if new ~= nil then
        local old = storage.scenario_version
        if old ~= new then
            game.reload_script()
            storage.scenario_version = new
        end
    end
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end
    -- check if user is in trouble due to insufficient storage
    local alerts = player.get_alerts{type = defines.alert_type.no_storage}
    local out_of_storage = false
    for _, surface in pairs(alerts) do
        for _, alert_type in pairs(surface) do
            for _, alert in pairs(alert_type) do
                local entity = alert.target
                if entity and entity.type == "construction-robot" then
                    out_of_storage = true
                    local inventory = entity.get_inventory(defines.inventory.robot_cargo)
                    if inventory then
                        entity.surface.spill_inventory{
                            position = entity.position,
                            inventory = inventory,
                            allow_belts = false,
                            max_radius = 10}
                    end
                    entity.clear_items_inside()
                end
            end
        end
    end
    if out_of_storage then
        player.print({"out-of-storage"})
    end
end)

script.on_event(defines.events.on_selected_entity_changed, gui.handle_player_selected_event)

-- TODO: Handle force merging

script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end
    -- check if roboport was destroyed
    local data = storage.forces[entity.force.name]
    if data and entity == data.roboport then
        if remote.interfaces["creative-mode"] and remote.call("creative-mode", "is_enabled") then
            return
        end
        game.set_game_state{
            game_finished = true,
            player_won = false,
            can_continue = false}
    end
end, {{ filter = "type", type = "roboport" }})

script.on_event(defines.events.on_research_finished, function(event)
    local tech = event.research
    local force = tech.force
    local force_info = storage.forces[force.name]
    if force_info then
        local surface = game.get_surface(force_info.home.surface)
        local tech_setting = storage.config.misc_settings.technology_clears_main_roboport
        if tech.name == bnwutil.get_planet_config(tech_setting, surface) then
            if force_info.roboport and force_info.roboport.valid then
                force_info.roboport.minable_flag = true
                force_info.roboport = nil
            end
        end
    end
end)

script.on_event(defines.events.on_forces_merging, function(event)
    local force = event.force
    local force_info = storage.forces[force.name]
    if force_info then
        force_info.home.force = force
    end
end)

local function draw_blueprint(direction)
    local player = game.player;
    local blueprint = bnwutil.get_selected_blueprint(player)
    if not blueprint or (blueprint.object_name == "LuaRecord" and blueprint.is_preview) then
        return
    end
    bnwutil.get_blueprint_bounding_box(blueprint, player.position, direction or defines.direction.north, player.surface)
end

remote.add_interface(MOD_PREFIX .. "debug", {
    list = function() return storage.subscribed_events end,
    players = function() return storage.players end,
    landing = function()
        return game.player and storage.forces[game.player.force.name].landing or error("Console only")
    end,
    draw_blueprint = draw_blueprint,
})

local config_interface = {
    --- @return table<planet:string, table<slot:number, string>>
    get_default_quick_bar_slots = function()
        return storage.config.default_quick_bar_slots
    end,
    --- @param slots table<planet:string, table<slot:number, string>>
    set_default_quick_bar_slots = function(slots)
        storage.config.default_quick_bar_slots = slots or error("Only accepts table")
    end,
    --- @return table<planet:string, table<inventory:string, InventoryItem[]>>
    get_starting_inventory = function()
        return storage.config.starting_inventory
    end,
    --- @param inv table<planet:string, table<inventory:string, InventoryItem[]>>
    set_starting_inventory = function(inv)
        storage.config.starting_inventory = inv or error("Only accepts table")
    end,
    --- @return table<planet:string, string>
    get_starting_blueprints = function()
        return storage.config.starting_blueprints
    end,
    --- @param blueprints table<planet:string, string>
    set_starting_blueprints = function(blueprints)
        storage.config.starting_blueprints = blueprints or error("Only accepts table")
    end,
    --- @return table<planet:string, string>
    get_starting_technologies = function()
        return storage.config.starting_technologies
    end,
    --- @param technologies table<planet:string, string>
    set_starting_technologies = function(technologies)
        storage.config.starting_technologies = technologies or error("Only accepts table")
    end,
    --- @return EquipmentItem[]
    get_bot_spawner_equipment = function()
        return storage.config.bot_spawner_equipment
    end,
    --- @param equipment EquipmentItem[]
    set_bot_spawner_equipment = function(equipment)
        storage.config.bot_spawner_equipment = equipment or error("Only accepts table")
    end,
    --- @return InventoryItem[]
    get_bot_spawner_extra_items = function()
        return storage.config.bot_spawner_extra_items
    end,
    --- @param items InventoryItem[]
    set_bot_spawner_extra_items = function(items)
        storage.config.bot_spawner_extra_items = items or error("Only accepts table")
    end,
    --- @return table<planet:string, table<inventory:string, InventoryItem[]>>
    get_planet_gifts = function()
        return storage.config.planet_gifts
    end,
    --- @param gifts table<planet:string, table<inventory:string, InventoryItem[]>>
    set_planet_gifts = function(gifts)
        storage.config.planet_gifts = gifts or error("Only accepts table")
    end,
    --- @return MiscSettings
    get_misc_settings = function()
        return storage.config.misc_settings
    end,
    --- @param settings MiscSettings
    set_misc_settings = function(settings)
        storage.config.misc_settings = settings or error("Only accepts table")
    end
}

remote.add_interface("bravest-new-world-scenario-config", config_interface)

local runtime_interface = {
    --- @return string
    get_interface_version = function()
        return "0.1"
    end,
    --- @return LuaSurface
    get_control_room = function()
        return storage.control_room
    end,
    --- @param surface LuaSurface
    set_control_room = function(surface)
        if surface.object_name ~= "LuaSurface"
                or not surface
                or not surface.valid then
            error("Only accepts valid surface")
        end
        storage.control_room = surface
    end,
    get_neutral_launcher = function()
        return storage.neutral_launcher
    end,
    --- @param launcher LuaEntity
    set_neutral_launcher = function(launcher)
        if not launcher
                or launcher.object_name ~= "LuaEntity"
                or not launcher.valid
                or (launcher.type ~= "rocket-silo"
                and launcher.type ~= "space-platform-hub") then
            error("Only accepts rocket-silo or space-platform-hub")
        end
        storage.neutral_launcher = launcher
    end,
    --- @return LuaEntity
    get_preview_pod = function()
        return storage.preview_pod
    end,
    --- @param pod LuaEntity
    set_preview_pod = function(pod)
        if not pod
                or pod.object_name ~= "LuaEntity"
                or not pod.valid then
            error("Only accepts LuaEntity")
        end
        storage.preview_pod = pod
    end,
    --- @return defines.event
    get_force_finished_startup_event = function()
        return FORCE_FINISHED_STARTUP_EVENT
    end,
    --- @return defines.event
    get_force_invalidated_event = function()
        return FORCE_INVALIDATED_EVENT
    end,
    --- @param o CreateForceOptions
    --- @return boolean
    create_bnw_force = function(o)
        if not o.force or o.force.object_name ~= "LuaForce" or not o.force.valid then
            error("Only accepts LuaForce")
        elseif o.player and (o.player.object_name ~= "LuaPlayer" or not o.player.valid) then
            error("Only accepts LuaPlayer")
        elseif not o.home or not o.home.surface
                or o.home.surface ~= "LuaSurface" or not o.home.position then
            error("Home must exist")
        elseif not o.control_room or not o.control_room.surface
                or o.control_room.surface ~= "LuaSurface" or not o.control_room.position then
            error("Control room must exist")
            elseif not (o.launch_type == "initial" or o.launch_type == "launch" or o.launch_type == "creative") then
            error("Launch type must be \"initial\", \"launch\", or \"creative\"")
        end
        create_force_with_player{
            force = o.force,
            player = o.player,
            home = o.home,
            control_room = o.control_room,
            launch_type = o.launch_type
        }
        return true
    end,
    --- Force roboport might get cleared during the gameplay
    --- @return LuaEntity?
    get_force_roboport = function(force_name)
        if BnwForce.exists(force_name) then
            return BnwForce.get(force_name).roboport
        end
        return nil
    end,
    --- @return boolean
    get_setup_force_on_player_create = function()
        return storage.setup_force_on_player_create
    end,
    --- @param bool boolean
    set_setup_force_on_player_create = function(bool)
        storage.setup_force_on_player_create = bool
    end
}

remote.add_interface("bravest-new-world-scenario-runtime", runtime_interface)
