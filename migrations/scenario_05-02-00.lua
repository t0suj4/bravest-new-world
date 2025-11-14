local wiretap = require("lib/wiretap_1")
local mig_utils = require("lib/util")

local TICKING_TICKS = 41 -- shadows a global

-- from control.lua
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

-- From control.lua
local function manage_subs(from, to, count)
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
        wiretap:subscribe(to_sub[1], to_sub[2], count, to_sub[3])
        ::skip::
    end
    for i=1,#pending_unsub do
        if pending_unsub[i] then
            wiretap:unsubscribe(unpack(pending_unsub[i]))
        end
    end
end

-- from bnw-force.lua
local function bnw_clean(force, force_info)
    local landing = force_info.landing
    landing.platform_surface_index = nil
    local blueprint_inventory = landing.blueprint_inventory
    if blueprint_inventory and blueprint_inventory.valid then
        blueprint_inventory.destroy()
    end
    landing.blueprint_inventory = nil
    landing.player_blueprint = nil
    landing.landing_location = nil
    landing.destination = nil
    landing.launch_type = nil
    if landing.player_index then
        local player = game.get_player(landing.player_index)
        if player and player.valid then
            player.teleport(force_info.control_room.position, force_info.control_room.surface)
        end
    end
    landing.player_index = nil
    local pod = landing.cargo_pod
    if pod and pod.valid then
        pod.destroy()
    end
    landing.cargo_pod = nil
    local inventory = landing.inventory
    if inventory and inventory.valid then
        inventory.destroy()
    end
    landing.inventory = nil
    landing.extra_tile_ghosts = nil
    local cap_bonus = landing.awarded_capacity_bonus
    if force and cap_bonus then
        force.worker_robots_storage_bonus = force.worker_robots_storage_bonus - cap_bonus
    end
    landing.awarded_capacity_bonus = nil
    local bot_spawner = landing.bot_spawner
    if bot_spawner and bot_spawner.valid then
        local network = bot_spawner.logistic_network
        -- For cases when there is weird setup with the bot spawner
        if network and #network.cells == 1 then
            for _, robot in ipairs(network.robots) do
                robot.destroy()
            end
        end
        bot_spawner.destroy()
    end
    landing.bot_spawner = nil

end

-- from bnw-force.lua
local function delete_platform(platform_info)
    if platform_info.bp_inventory and platform_info.bp_inventory.valid then
        platform_info.bp_inventory.destroy()
    end
    if platform_info.overflow_inventory and platform_info.overflow_inventory.valid then
        platform_info.overflow_inventory.destroy()
    end
    if platform_info.component_chest and platform_info.component_chest.valid then
        platform_info.component_chest.destroy()
    end
    if platform_info.trash_chest and platform_info.trash_chest.valid then
        platform_info.trash_chest.destroy()
    end
    platform_info.platform = nil
    platform_info.bp_inventory = nil
    platform_info.overflow_inventory = nil
    platform_info.component_chest = nil
    platform_info.trash_chest = nil
end

local function update_state(force, force_info)
    local landing = force_info.landing
    local cargo_pod = landing.cargo_pod
    if cargo_pod and not cargo_pod.valid then
        local state = landing.state.current
        landing.state.async = "none"
        landing.state.current = "invalid"
        manage_subs(state, "invalid")
        bnw_clean(force, force_info)
    end
end

local function migrate_platforms(force, force_info)
    if force_info.landing.platform_index then
        local platform = force.platforms[force_info.landing.platform_index]
        if platform then
            force_info.landing.platform_surface_index = platform.surface.index
        end
        force_info.landing.platform_index = nil
    end
    local transfer_platforms = {}
    local delete_platforms = {}
    for _, platform_info in pairs(force_info.platforms) do
        local platform = platform_info.platform
        if platform and platform.valid then
            local surface = platform.surface
            platform_info.surface = surface
            transfer_platforms[surface.index] = platform_info
        else
            delete_platforms[#delete_platforms + 1] = platform_info
        end
    end
    force_info.platforms = transfer_platforms
    for _, platform_info in pairs(delete_platforms) do
        delete_platform(platform_info)
    end
end

local function migrate_forces(storage)
    local delete = {}
    for force_name, force_info in pairs(storage.forces) do
        local force = game.forces[force_name]
        if force then
            migrate_platforms(force, force_info)
            update_state(force, force_info)
        else
            delete[force_name] = force_info
        end
    end
    for force_name, force_info in pairs(delete) do
        manage_subs(force_info.landing._state.current, "invalidate")
        bnw_clean(nil, force_info)
        for _, platform_info in pairs(force_info.platforms) do
            delete_platform(platform_info)
        end
        storage.forces[force_name] = nil
    end
end

local function migrate_players(storage)
    local delete = {}
    for player_index, player_info in pairs(storage.players) do
        local player = game.get_player(player_index)
        if not player then
            delete[player_index] = true
        else
            local gui = player.gui.screen["bravest-new-world-deployment-interface"]
            if gui then
                gui.destroy()
            end
        end
        if player_info.launch_gui_open then
            wiretap:unsubscribe("nth_tick", "handle_refresh_inventory", 13)
            player_info.launch_gui_open = false
        end
        local platform_index = player_info.platform_index
        local force_name = player_info.platform_force_name
        if platform_index and force_name then
            local force = game.forces[force_name]
            if force then
                local platform = force.platforms[platform_index]
                if platform then
                    player_info.platform_surface_index = platform.surface.index
                end
            end
        elseif platform_index or force_name then
            log("Unknown state platform_index: "
                    .. serpent.block{platform_index = platform_index, force_name = force_name})
            game.print("There was an unexpected error when migrating bravest-new-world to a new version."
                    .. "Please, submit the save for review")
            player_info.platform_force_name = nil
        end
        player_info.platform_index = nil
    end
    for index in pairs(delete) do
        storage.players[index] = nil
    end
end

mig_utils.run_migration("5.2.0", function(storage)
    wiretap:attach(storage)
    migrate_forces(storage)
    migrate_players(storage)
end)
