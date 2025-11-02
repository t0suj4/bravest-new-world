local statemachine = require("statemachine")
---@class BnwForce
local BnwForce = {}
BnwForce.__index = BnwForce

local force_fsms = {}

local bnw_forces = {}

function BnwForce.get(name)
    local f = bnw_forces[name]
    if not f then
        bnwutil.raise_error("invalid bnw force: " .. name, bnw_forces)
    end
    if not f.af then
        f.af = game.forces[name]
        if not f.af then
            bnwutil.raise_error("force disappeared: " .. name)
        end
    end
    return f
end

-- Less strict, but missing force means wrong handling of merge
function BnwForce.try_get(name)
    local f = bnw_forces[name]
    if not f then
        return nil
    end
    if not f.af then
        f.af = game.forces[name]
        if not f.af then
            bnwutil.raise_error("force disappeared: " .. name)
        end
    end
    return f
end

function BnwForce.exists(name)
    return bnw_forces[name] and true or false
end

function BnwForce.count()
    return table_size(bnw_forces)
end

function BnwForce.mergeForces(destination, source)
    local bnw_destination = bnw_forces[destination.name]
    local bnw_source = bnw_forces[source.name]
    if not bnw_source then
        return
        elseif not bnw_destination then
        bnw_source.name = destination.name
        bnw_source.af = destination
        else
        if bnw_source:is("initial") or bnw_source:is("inactive") then
            for platform_index, platform_info in pairs(bnw_source.bnw.platforms) do
                bnw_destination.bnw.platforms[platform_index] = platform_info
            end
            bnw_forces[source.name] = nil
        else
            for platform_index, platform_info in pairs(bnw_source.bnw.platforms) do
                if platform_index ~= bnw_source.bnw.landing.platform_index then
                    bnw_destination.bnw.platforms[platform_index] = platform_info
                end
            end

            local source_capacity_bonus = bnw_source.bnw.landing.awarded_capacity_bonus
            local destination_capacity_bonus = bnw_destination.bnw.landing.awarded_capacity_bonus
            if source_capacity_bonus and destination_capacity_bonus then
                bnw_source.bnw.landing.awarded_capacity_bonus = 0
            elseif source_capacity_bonus and not destination_capacity_bonus then
                -- Storage bonus might temporarily double, that's acceptable edge case
                local bonus = destination.worker_robots_storage_bonus
                destination.worker_robots_storage_bonus = bonus + source_capacity_bonus
            end

            bnw_source.name = destination.name
            bnw_source.af = destination
            bnw_source.merged = true
        end
    end
end

local get_planet_config = bnwutil.get_planet_config

local function place_structures(o)
    local force, surface, position = o.force, o.surface, o.position
    local on_placed, tag, stack = o.on_placed, o.tag, o.bp_stack
    local player_bp = o.player_bp
    if tag ~= nil then
        local ents = stack.get_blueprint_entities()
        for i=1,#ents do
            local bpent = ents[i]
            stack.set_blueprint_entity_tag(bpent.entity_number, tag, true)
            if player_bp then
                stack.set_blueprint_entity_tag(bpent.entity_number, TAG_FIRST_ROBOPORT, nil)
                stack.set_blueprint_entity_tag(bpent.entity_number, TAG_STARTING_ROBOPORT, nil)
            end
        end
    end
    local ghosts = stack.build_blueprint{
        surface = surface,
        position = position,
        force = force,
        build_mode = defines.build_mode.superforced,
        skip_fog_of_war = false}
    if on_placed ~= nil then
        for i=1,#ghosts do
            on_placed(ghosts[i])
            script.raise_script_built{ entity = ghosts[i] }
        end
    else
        for i=1,#ghosts do
            script.raise_script_built{ entity = ghosts[i] }
        end
    end
end

local function create_deploy_chest(platform, name)
    local surface = platform.surface
    local chest = surface.create_entity{name = name, position = {-2.5, -2.5}, force = platform.force}
    if not chest then
        local position = surface.find_non_colliding_position(name, {0, 0}, 25, 1, true)
        chest = surface.create_entity{name = name, position = position, force = platform.force}
        if not chest then
            game.print("Failed to create chest at " .. platform.name .. "(" .. platform.surface.name .. ")")
            return nil
        end
    end
    chest.destructible = false
    chest.operable = false
    chest.minable_flag = false
    return chest
end

function BnwForce.create(o)
    local force = assert(o.force, "Force must exist")
    local home = assert(o.home, "Home must exist")
    local landing_states = assert(o.landing_states, "Landing states must exist")
    local launch_callbacks = assert(o.launch_callbacks, "Launch callbacks must exist")
    local control_room = assert(o.control_room, "Control room must exist")
    local name = force.name

    if bnw_forces[name] then
        return bnw_forces[name], false
    end
    local bnw = {
        home = { position = pos.ensure_xy(home.position), surface = home.surface },
        control_room = { position = pos.ensure_xy(control_room.position), surface = control_room.surface},
        platforms = {},
        landing = {
            state = {},
            time = game.tick
        },
    }
    storage.forces[name] = bnw
    local landing_fsm = statemachine.create{
        initial = landing_states.initial,
        state = bnw.landing.state,
        events = landing_states.events,
        callbacks = launch_callbacks,
    }

    force_fsms[name] = {
        landing = landing_fsm,
    }

    local obj = {
        name = name,
        af = force,
        bnw = bnw,
        fsm = force_fsms[name]
    }
    setmetatable(obj, BnwForce)

    bnw_forces[name] = obj

    if storage.control_room.name == CONTROL_ROOM_SURFACE then
        force.set_surface_hidden(CONTROL_ROOM_SURFACE, true)
    end
    return obj, true
end

function BnwForce.load(o)
    local name = assert(o.name)
    local data = assert(o.data)
    local landing_states = assert(o.landing_states)
    local launch_callbacks = assert(o.launch_callbacks)
    assert(not bnw_forces[name])
    local landing_fsm = statemachine.create{
        initial = landing_states.initial,
        state = data.landing.state,
        events = landing_states.events,
        callbacks = launch_callbacks,
    }

    force_fsms[name] = {
        landing = landing_fsm,
    }
    local obj = {
        name = name,
        bnw = storage.forces[name],
        fsm = force_fsms[name],
    }
    setmetatable(obj, BnwForce)
    bnw_forces[name] = obj
end

function BnwForce:trigger(event)
    self:check_state_for(event)
    local fsm = self.fsm.landing
    fsm[event](fsm, self.name)
end

function BnwForce:launch_type()
    return self.bnw.landing.launch_type
end

function BnwForce:can(event)
    return self.fsm.landing:can(event)
end

function BnwForce:is(event)
    return self.fsm.landing:is(event)
end

-- ascending
function BnwForce:fast_forward_voyage()
    if self:launch_type() == "initial" then
        self.bnw.landing.cargo_pod.procession_tick = ROCKET_SEQUENCE_LAUNCH_TIME
    end
end

function BnwForce:check_state_for(event)
    if not self:can(event) then
        local state = self.fsm.landing._state.current
        bnwutil.raise_error("Force: " .. self.name .. " cannot " .. event .. ", it is " .. state, self.bnw)
    end
    return self.fsm.landing._state.state
end

function BnwForce:stash_player_character(player, controller_type)
    storage.characters = storage.characters or {}
    local character = player.character or storage.characters[player.index]
    if character and character.valid then
        character.destructible = false
        storage.characters[player.index] = character
    end
    local location = self.bnw.landing.destination or player.position
    player.set_controller{
        type = controller_type or defines.controllers.ghost,
        position = location.position,
        surface = location.surface}
    if character and character.valid then
        character.teleport(self.bnw.control_room.position, self.bnw.control_room.surface)
    end
end

function BnwForce:restore_player_character(player)
    if not player.valid or player.character then
        return
    end

    local surface, position, zoom = player.surface, player.position, player.zoom
    local character = storage.characters[player.index]
    if player.controller_type == defines.controllers.cutscene then
        player.exit_cutscene()
    end
    player.teleport(character.position, character.surface)
    player.set_controller{type = defines.controllers.character, character = character}
    player.set_controller{type = defines.controllers.remote, surface = surface, position = position}
    player.zoom = zoom
end

function BnwForce:set_destination(o)
    self:check_state_for("prepare")
    local surface = o.surface or self.bnw.home.surface
    local position = o.position or self.bnw.home.position
    local use_offset = o.use_offset == true or o.use_offset or false
    local randomize_offset = o.randomize_offset == true or o.randomize_offset or false
    local launch_type = o.launch_type
    if launch_type == nil or surface == nil or position == nil then
        error("Must specify launch_type, surface and position")
    end
    assert(launch_type == "initial"
            or launch_type == "platform"
            or launch_type == "creative",
            "Unsupported launch_type")
    assert(launch_type == "initial" or o.platform, "Non-initial launch must have a platform")

    local offset = {x = 0, y = 0}
    if use_offset == true then
        local bso = storage.config.misc_settings.bot_spawner_offset
        offset.x, offset.y = bso.x, bso.y
    elseif type(use_offset) == "table" then
        local uo = pos.ensure_xy(use_offset)
        offset.x, offset.y = uo.x, uo.y
    end

    if randomize_offset == true then
        local bsro = storage.config.misc_settings.bot_spawner_random_offset
        local min = pos.ensure_xy(bsro.min or bsro[1])
        local max = pos.ensure_xy(bsro.max or bsro[2])
        local random_pos = bnwutil.random_real_pos(min, max)
        offset = pos.add(offset, random_pos)
    elseif type(randomize_offset) == "table" then
        local min, max = randomize_offset.min or randomize_offset[1], randomize_offset.max or randomize_offset[2]
        offset = pos.add(offset, bnwutil.random_real_pos(pos.ensure_xy(min), pos.ensure_xy(max)))
    end
    local blueprint_inventory = game.create_inventory(1)
    -- Using blueprint copy here prevents leaking tags
    local slot = blueprint_inventory[1]
    local player_blueprint = false
    if o.platform and o.platform.valid then
        local platform_info = self:get_platform(o.platform.index)
        if platform_info then
            slot.set_stack(platform_info.bp_inventory[1])
            player_blueprint = true
        end
    end
    if not slot.valid_for_read then
        slot.import_stack(bnwutil.get_planet_config(storage.config.starting_blueprints, surface))
    end

    local landing_location = {surface = surface, position = pos.add(position, offset)}
    local landing = self.bnw.landing
    landing.platform_index = o.platform and o.platform.index
    landing.blueprint_inventory = blueprint_inventory
    landing.player_blueprint = player_blueprint
    landing.landing_location = landing_location
    landing.destination = {surface = surface, position = pos.ensure_xy(position)}
    landing.launch_type = launch_type
    self:trigger("prepare")
end

function BnwForce:create_pod(launcher, player)
    self:check_state_for("launch")
    local landing_location = self.bnw.landing.landing_location
    local cargo_pod = launcher.create_cargo_pod()
    local inventory = cargo_pod.get_inventory(defines.inventory.chest)
    inventory.insert({name = storage.config.misc_settings.initial_pod_item, count = 1})
    cargo_pod.cargo_pod_destination = {
        type = defines.cargo_destination.surface,
        surface = landing_location.surface,
        position = landing_location.position,
        land_at_exact_position = true}

    local landing = self.bnw.landing
    if player then
        player.teleport(self.bnw.control_room.position, self.bnw.control_room.surface)
        cargo_pod.set_passenger(player)
        landing.player_index = player.index
    end

    landing.cargo_pod = cargo_pod
    self:trigger("launch")
end

function BnwForce:stash_items()
    local launch_platform = self:launch_platform()
    if not (launch_platform and launch_platform.platform.valid) then
        error("Expected valid platform")
    end
    local chest = launch_platform.component_chest
    if not (chest and chest.valid) then
        error("Could not find construction item container")
    end

    -- TODO: recount items on every configuration change
    local chest_inv = chest.get_inventory(defines.inventory.chest)
    if not chest_inv then
        error("Expected to find chest inventory")
    end
    local inventory = game.create_inventory(#chest_inv - chest_inv.count_empty_stacks())
    assert(not bnwutil.copy_items_to(inventory, chest_inv), "Expected to transfer all construction items")

    self.bnw.landing.inventory = inventory
end

-- leave constructing
function BnwForce:clear_launch_items()
    -- TODO: Add fallback behavior
    local inventory = self.bnw.landing.inventory
    if not (inventory and inventory.valid) then
        bnwutil.raise_error("Expected to find landing inventory", self.bnw)
    end
    inventory.clear()
    inventory.destroy()
    self.bnw.landing.inventory = nil

    local launch_platform = self:launch_platform()
    if not launch_platform then
        return
    end
    local chest = launch_platform.component_chest
    if not (chest and chest.valid) then
        bnwutil.raise_error("Could not find construction item container", self.bnw)
    end

    local chest_inv = chest.get_inventory(defines.inventory.chest)
    if not chest_inv then
        bnwutil.raise_error("Expected to find chest inventory", self.bnw)
    end
    local bp_inv = launch_platform.bp_inventory
    if not (bp_inv and bp_inv.valid) then
        bnwutil.raise_error("Expected to find blueprint inventory", self.bnw)
    end

    chest_inv.clear()
    bp_inv.clear()
end

-- ready
function BnwForce:prepare_landing()
    local landing = self.bnw.landing
    local destination = landing.destination
    local surface = game.get_surface(destination.surface)
    local position = destination.position
    local blueprint = self.bnw.landing.blueprint_inventory[1]
    local blueprint_extent = bnwutil.get_blueprint_bounding_box(blueprint, position, defines.direction.north)
    landing.blueprint_extent = blueprint_extent
    local ll = landing.landing_location
    local extra_y_offset = position.y - blueprint_extent.left_top.y
    -- Move up
    ll.position.y = ll.position.y - extra_y_offset

    local bs_bb = prototypes.entity[storage.config.misc_settings.bot_spawner_prototype].collision_box
    local bs_box = bnwutil.bounding_box_offset(bs_bb, ll.position)
    local lz_extent = bnwutil.bounding_box_grow_to_square(bnwutil.bounding_box_union(bs_box, blueprint_extent))
    local chunks = bnwutil.bounding_box_to_chunks(lz_extent)
    local half_size = math.ceil((chunks.right_bottom.x - chunks.left_top.x) / 2)
    local center = bnwutil.bounding_box_center(lz_extent)

    surface.request_to_generate_chunks(center, half_size)
    surface.force_generate_chunk_requests()
    -- For some reason, the lightning attractors are not generated as "neutral"
    local starting_attractors = surface.find_entities_filtered{area = lz_extent, type = "lightning-attractor"}
    for i=1,#starting_attractors do
        local attractor = starting_attractors[i]
        if attractor.prototype.autoplace_specification then
            local cb = attractor.prototype.collision_box
            local box = bnwutil.bounding_box_offset(cb, attractor.position)
            local lb = {x = box.left_top.x, y = box.right_bottom.y}

            local x_offset = bs_box.right_bottom.x - lb.x
            local y_offset = blueprint_extent.left_top.y - lb.y
            attractor.teleport(x_offset, y_offset)
            break
        end
    end

    local entities = surface.find_entities_filtered{force = "neutral", area = bs_box}
    for i=1,#entities do
        local entity = entities[i]
        if entity.type == "tree" then
            entity.die()
        else
            entity.destroy()
        end
    end
    -- Randomly spill freeplay items
    if self:launch_type() == "initial" and remote.interfaces["freeplay"] then
        local min = lz_extent.left_top
        local max = {x = lz_extent.right_bottom.x, y = blueprint_extent.left_top.y}
        local items = remote.call("freeplay", "get_created_items")
        for item, count in pairs(items) do
            for _=1,count do
                local pos = bnwutil.random_real_pos(min, max)
                surface.spill_item_stack{stack = {name = item, count = 1}, position = pos}
            end
        end
    end
    self.af.chart(destination.surface, bb.create_from_centre(destination.position, 400, 400))
    self:setup_landing_zone()
end

function BnwForce:generate_starting_resources()
    local dest = self.bnw.landing.destination
    local surface = assert(game.get_surface(dest.surface))

    local water_replace_tile = get_planet_config(storage.config.misc_settings.water_replace_tile, surface)

    local resource_tiles = {}

    -- TODO: Dehardcode resource prototype
    local resource = "crude-oil"
    local resource_prototype = prototypes.entity[resource]
    local width, height = resource_prototype.tile_width, resource_prototype.tile_height
    -- padded
    local x_center_offset = math.fmod(width, 2) == 0 and 0 or 0.5
    local y_center_offset = math.fmod(height, 2) == 0 and 0 or 0.5

    local function collect_water_tiles(box)
        for x = box.left_top.x-1, box.right_bottom.x do
            for y = box.left_top.y-1, box.right_bottom.y do
                local tile = surface.get_tile(x, y)
                if tile.prototype.collision_mask.layers.water_tile then
                    table.insert(resource_tiles, {name = water_replace_tile, position = {x, y}})
                end
            end
        end
    end

    local blueprint_extent = self.bnw.landing.blueprint_extent

    -- TODO: Dehardcode patches amount
    local num_oil_patches = 3
    -- TODO: Dehardcode offsets
    local x_location, y_location = bnwutil.random_point_outside_box(blueprint_extent, 16, 32)

    local resource_positions = {}
    local collision_boxes = {}
    local attempts_remaining = num_oil_patches * 10
    for _ = 1, num_oil_patches do
        ::restart::
        attempts_remaining = attempts_remaining - 1
        if attempts_remaining <= 0 then
            game.print("Failed to create all resource patches! Only "
                    .. #resource_positions
                    .. " out of "
                    .. num_oil_patches
                    .. " created")
            break
        end
        -- TODO: Dehardcode offsets
        local x = x_location + math.random(-4, 4)
        local y = y_location + math.random(-4, 4)
        local cb = bb.create_from_centre({x + x_center_offset, y + y_center_offset}, width, height)
        for _, c in ipairs(collision_boxes) do
            if bb.collides_with(c, cb) then
                goto restart
            end
        end
        collision_boxes[#collision_boxes + 1] = cb
        resource_positions[#resource_positions + 1] = {x, y}
        collect_water_tiles(cb)
    end

    for _, cb in ipairs(collision_boxes) do
        surface.destroy_decoratives{area = cb}
    end

    surface.set_tiles(resource_tiles)
    for _, res_pos in ipairs(resource_positions) do
        surface.create_entity{
            name = "crude-oil",
            -- TODO: Dehardcode amount
            amount = math.random(100000, 250000),
            position = res_pos, raise_built = true}
    end
end

function BnwForce:setup_landing_zone()
    if self:launch_type() == "initial" then
        self:generate_starting_resources()
    end
    local dest = self.bnw.landing.destination
    local surface = assert(game.get_surface(dest.surface))
    local force = self.af

    if self:launch_type() == "initial" then
        for _, tech in pairs(get_planet_config(storage.config.starting_technologies, surface)) do
            force.technologies[tech].researched = true
        end
    end

    local blueprint_extent = self.bnw.landing.blueprint_extent
    -- remove trees/stones/resources
    local entities = surface.find_entities_filtered{area = blueprint_extent, force = "neutral"}
    for _, entity in pairs(entities) do
        entity.destroy()
    end

    -- place dirt beneath structures
    local water_replace_tile = get_planet_config(storage.config.misc_settings.water_replace_tile, surface)
    local meltable_replace_tile = get_planet_config(storage.config.misc_settings.meltable_replace_tile, surface)
    local tiles = {}
    local extra_tile_ghosts = {}
    for x=blueprint_extent.left_top.x-1, blueprint_extent.right_bottom.x do
        for y=blueprint_extent.left_top.y-1, blueprint_extent.right_bottom.y do
            local tile = surface.get_tile(x, y)
            if tile.prototype.collision_mask.layers.water_tile then
                local name = water_replace_tile
                local prototype = prototypes.tile[name]
                if prototype and prototype.items_to_place_this then
                    extra_tile_ghosts[#extra_tile_ghosts + 1] = {
                        tile = water_replace_tile,
                        position = {x = x, y = y},
                        reason = "water"}
                else
                    tiles[#tiles + 1] = {name = name, position = {x, y}}
                end
            end
            if tile.prototype.collision_mask.layers.meltable then
                local name = meltable_replace_tile
                local prototype = prototypes.tile[name]
                if prototype and prototype.items_to_place_this then
                    extra_tile_ghosts[#extra_tile_ghosts + 1] = {
                        tile = meltable_replace_tile,
                        position = {x = x, y = y},
                        reason = "meltable"}
                else
                    tiles[#tiles + 1] = {name = name, position = {x, y}}
                end
            end
        end
    end
    surface.set_tiles(tiles)
    self.bnw.landing.blueprint_extent = nil
    -- TODO: migrate when mods get removed
    self.bnw.landing.extra_tile_ghosts = extra_tile_ghosts
end

-- clearing
function BnwForce:clear_landing_zone()

    -- TODO: Violent clearing of the landing zone
end

-- after staging
function BnwForce:clear_pod()
    local pod = self.bnw.landing.cargo_pod
    if not pod or not pod.valid then
        return
    end

    local inventory = pod.get_inventory(defines.inventory.chest)
    if inventory ~= nil then
        inventory.clear()
    end
    pod.die()
    self.bnw.landing.cargo_pod = nil
end

function BnwForce:place_bot_spawner(surface, position)
    local tank = surface.create_entity{
        name = storage.config.misc_settings.bot_spawner_prototype,
        position = position,
        force = self.af}
    local grid = tank.grid
    tank.destructible = false
    tank.operable = false
    tank.minable_flag = false

    if not grid then
        bnwutil.raise_error("Bot spawner must have a grid")
    end

    for _, eq in pairs(storage.config.bot_spawner_equipment) do
        local equipment = grid.put{name = eq.item, position = {eq.x, eq.y}, quality = eq.quality}
        if equipment ~= nil then
            equipment.energy = equipment.max_energy
        else
            game.print("Failed placing bot spawner equipment " .. serpent.block(eq))
        end
    end
    local fuel = tank.get_inventory(defines.inventory.fuel)
    if fuel then
        fuel.insert(storage.config.misc_settings.bot_spawner_fuel)
    end

    local trunk = tank.get_inventory(defines.inventory.car_trunk)
    if not trunk then
        bnwutil.raise_error("Expected bot spawner to have trunk")
    end
    for _, item in pairs(storage.config.bot_spawner_extra_items) do
        trunk.insert(item)
    end

    for _, item in pairs(get_planet_config(storage.config.planet_gifts, surface) or {}) do
        trunk.insert(item)
    end

    local extra_tile_ghosts = self.bnw.landing.extra_tile_ghosts
    local water_replace_tile = get_planet_config(storage.config.misc_settings.water_replace_tile, surface)
    local meltable_replace_tile = get_planet_config(storage.config.misc_settings.meltable_replace_tile, surface)
    local extra_tile_items = {}
    local tile_placements = {}
    for i=1, #extra_tile_ghosts do
        local ghost = extra_tile_ghosts[i]
        local prototype = prototypes.tile[ghost.tile]
        if prototype and prototype.items_to_place_this then
            for _, tile_item in ipairs(prototype.items_to_place_this) do
                local name = tile_item.name
                extra_tile_items[name] = (extra_tile_items[name] or 0) + tile_item.count
            end
        else
            -- Mod changed tiles, retry with hopefully updated configuration
            if ghost.reason == "water" then
                tile_placements[#tile_placements + 1] = {name = water_replace_tile, position = ghost.position}
            elseif ghost.reason == "meltable" then
                tile_placements[#tile_placements + 1] = {name = meltable_replace_tile, position = ghost.position}
            else
                bnwutil.raise_error("Unknown tile ghost reason", ghost, extra_tile_ghosts, self.bnw)
            end
        end
    end

    for name, count in pairs(extra_tile_items) do
        trunk.insert({name = name, count = count})
    end
    surface.set_tiles(tile_placements)

    local landing_inventory = self.bnw.landing.inventory
    if landing_inventory and landing_inventory.valid then
        bnwutil.copy_items_to(trunk, landing_inventory, {ignore_type = "construction-robot"})
        return tank
    end

    for name, inventory in pairs(get_planet_config(storage.config.starting_inventory, surface)) do
        -- Cannot insert construction robots via requests
        if not name:find("^roboport%-robots%-") then
            for _, item in pairs(inventory) do
                trunk.insert(item)
            end
        end
    end
    local inventory = game.create_inventory(1)
    local stack = inventory[1]

    stack.import_stack(get_planet_config(storage.config.starting_blueprints, surface))
    local entities = stack.get_blueprint_entities()
    for i=1,#entities do
        local entity = entities[i]
        local quality = entity.quality
        local entity_prototype = assert(prototypes.entity[entity.name],
                "Starting blueprint entity should not have been removed by a mod")
        if entity_prototype then
            for _, item in ipairs(entity_prototype.items_to_place_this) do
                trunk.insert({name = item.name, count = item.count, quality = quality})
            end
        end
    end
    local tiles = stack.get_blueprint_tiles() or {}
    for i=1,#tiles do
        local tile_prototype = assert(prototypes.tile[tiles[i].name],
                "Starting blueprint tile should not have been removed by a mod")
        if tile_prototype then
            for _, item in ipairs(tile_prototype.items_to_place_this) do
                trunk.insert({name = item.name, count = item.count})
            end
        end
    end
    inventory.destroy()
    return tank
end

-- staging
function BnwForce:stage()
    local landing = self.bnw.landing
    local surface = game.get_surface(landing.landing_location.surface)
    local bot_spawner = self:place_bot_spawner(surface, landing.landing_location.position)
    landing.bot_spawner = bot_spawner
    local cap_bonus = storage.config.misc_settings.bot_spawner_phase_capacity_bonus
    landing.awarded_capacity_bonus = cap_bonus
    self.af.worker_robots_storage_bonus = self.af.worker_robots_storage_bonus + cap_bonus
end

-- finalizing
function BnwForce:deactivate()
    local launch_type = self:launch_type()
    if launch_type == "initial" then
        for _, player in pairs(self.af.players) do
            self:restore_player_character(player)
        end
    elseif launch_type == "platform" then
        local launch_platform = self:launch_platform()
        if launch_platform then
            local chest = launch_platform.component_chest
            if chest and chest.valid then
                chest.clear_items_inside()
            end
        end
    end
    self.bnw.landing.launch_type = nil
    self.bnw.landing.landing_location = nil
    self.bnw.landing.destination = nil
    if self.merged then
        local destination = bnw_forces[self.name]
        local platform_index = self.bnw.landing.platform_index
        if destination then
            local platform = self.bnw.platforms[platform_index]
            destination.bnw.platforms[platform_index] = platform
        end
        bnw_forces[self.name] = nil
    end
    self.bnw.landing.platform_index = nil
end

function BnwForce:player_cutscene(player)
    local landing_location = self.bnw.landing.landing_location
    local destination = self.bnw.landing.destination
    -- TODO: dehardcode time and use procession prototype - Factorio 2.1
    -- FIXME: align with TICKING_TICKS
    local landing_time = 400
    local cutscene_waypoints = {
        {
            position = pos.add(landing_location.position, {-30, -40}),
            zoom = 1.4,
            transition_time = 0,
            time_to_wait = 20
        }, {
            position = pos.add(landing_location.position, {0, 10}),
            zoom = 1.2,
            transition_time = landing_time * 6 / 5 + TICKS_STAGING_WAIT * 2 / 3,
            time_to_wait = landing_time * 1 / 5 - 50,
        }, {
            position = landing_location.position,
            zoom = 1.8,
            transition_time = TICKS_LANDED_WAIT * 4 / 5 + 50 + TICKS_STAGING_WAIT / 3 - landing_time * 2 / 5,
            time_to_wait = TICKS_LANDED_WAIT / 5
        }, {
            position = destination.position,
            zoom = 1.8,
            transition_time = TICKS_CONSTRUCTION_WAIT * 5 / 7,
            time_to_wait = TICKS_CONSTRUCTION_WAIT * 1 / 7
        }, {
            position = destination.position,
            zoom = 0.8,
            transition_time = TICKS_POST_CONSTRUCTION_WAIT,
            time_to_wait = 1200
        }}
    player.set_controller{
        type = defines.controllers.cutscene,
        waypoints = cutscene_waypoints,
        surface = destination.surface,
    }
end

-- constructing
function BnwForce:create_ghosts()
    -- I thought about generalizing this, but repurposed prototypes in mods
    -- would make it stupidly complex
    local location = self.bnw.landing.destination
    local surface = game.get_surface(location.surface)
    local chests = 0
    local roboports = 0
    local starting_items = get_planet_config(storage.config.starting_inventory, surface)
    local function on_placed_starting(ghost)
        -- TODO: Partially support modular roboports
        if bnwutil.is_roboport(ghost.ghost_prototype.name) then
            roboports = roboports + 1
            if roboports == 1 then
                local tags = ghost.tags
                if self:launch_type() == "initial" then
                    tags[TAG_STARTING_ROBOPORT] = true
                end
                tags[TAG_FIRST_ROBOPORT] = true
                ghost.tags = tags
            end
            local planner = bnwutil.InsertPlanner:new()
            local starting_robots = starting_items["roboport-robots-" .. roboports] or {}
            for _, item in pairs(starting_robots) do
                planner:add_item(defines.inventory.roboport_robot, {item.name, item.quality}, item.count)
            end
            local starting_material = starting_items["roboport-material-" .. roboports] or {}
            for _, item in pairs(starting_material) do
                planner:add_item(defines.inventory.roboport_material, {item.name, item.quality}, item.count)
            end
            ghost.insert_plan = planner.insert_plan
        elseif ghost.ghost_type == "logistic-container" or ghost.ghost_type == "container" then
            chests = chests + 1
            local planner = bnwutil.InsertPlanner:new()
            local chest_items = starting_items["chest-" .. chests] or {}
            for _, item in pairs(chest_items) do
                planner:add_item(defines.inventory.chest, {item.name, item.quality}, item.count)
            end
            -- Add gifts too
            if chests == 1 then
                local gifts = get_planet_config(storage.config.planet_gifts, surface) or {}
                for _, item in pairs(gifts) do
                    planner:add_item(defines.inventory.chest, {item.name, item.quality}, item.count)
                end
            end
            ghost.insert_plan = planner.insert_plan
        end
    end

    local extra_tile_ghosts = self.bnw.landing.extra_tile_ghosts
    for i=1, #extra_tile_ghosts do
        local ghost = extra_tile_ghosts[i]
        surface.create_entity{
            name = "tile-ghost",
            position = ghost.position,
            inner_name = ghost.tile,
            force = self.af,
            raise_built = true}
    end

    local function on_placed_bp(ghost)
        if bnwutil.is_roboport(ghost.ghost_prototype.name) then
            roboports = roboports + 1
            if roboports == 1 then
                local tags = ghost.tags
                tags[TAG_FIRST_ROBOPORT] = true
                ghost.tags = tags

                if #ghost.insert_plan == 0 then
                    local planner = bnwutil.InsertPlanner:new()
                    planner:add_item(
                            defines.inventory.roboport_robot,
                            {storage.config.misc_settings.construction_robot , "normal"},
                            50)
                    ghost.insert_plan = planner.insert_plan
                end
            end
        elseif ghost.ghost_type == "logistic-container" or ghost.ghost_type == "container" then
            chests = chests + 1
            if chests == 1 then
                local planner = bnwutil.InsertPlanner:new()
                local gifts = get_planet_config(storage.config.planet_gifts, surface) or {}
                for _, item in pairs(gifts) do
                    planner:add_item(defines.inventory.chest, {item.name, item.quality}, item.count)
                end
                ghost.insert_plan = planner.insert_plan
            end
        end
    end

    local on_placed, player_bp
    if self.bnw.landing.player_blueprint then
        on_placed = on_placed_bp
        player_bp = true
    else
        on_placed = on_placed_starting
        player_bp = false
    end
    place_structures{
        force = self.af,
        surface = location.surface,
        position = location.position,
        tag = TAG_STARTING_STRUCTURE,
        bp_stack = self.bnw.landing.blueprint_inventory[1],
        on_placed = on_placed,
        player_bp = player_bp}

    self.bnw.landing.blueprint_inventory.destroy()
    self.bnw.landing.blueprint_inventory = nil
    self.bnw.landing.player_blueprint = nil
    self.bnw.landing.extra_tile_ghosts = nil
end

-- before finalize
function BnwForce:await_construction()
    local force, data = self.af, self.bnw
    local bot_spawner = data.landing.bot_spawner
    if not bot_spawner or not bot_spawner.valid then
        log("Invalid bot spawner for force: " .. force.name)
        game.print("Invalid bot spawner for force: " .. force.name)
        return false, false
    end
    local trunk = bot_spawner.get_inventory(defines.inventory.car_trunk)
    local items = 0
    local matched_items = 0
    for _, item in pairs(storage.config.bot_spawner_extra_items) do
        items = items + 1
        -- Might have collected some from the ground. Unlikely, but possible
        if trunk.get_item_count(item) >= item.count then
            matched_items = matched_items + 1
        end
    end
    if items == matched_items then
        local cap_bonus = data.landing.awarded_capacity_bonus
        force.worker_robots_storage_bonus = force.worker_robots_storage_bonus - cap_bonus

        bot_spawner.destroy()
        data.landing.bot_spawner = nil
        data.landing.awarded_capacity_bonus = nil
        -- FIXME: Fiddling with upgrades unlocks upgrades in minimap gui
        return true, true
    end
    return false, true
end

function BnwForce:add_platform(platform)
    assert(not self.bnw.platforms[platform.index], "Platform is already registered")
    local bp_inventory = game.create_inventory(1)
    local overflow_inventory = game.create_inventory(10)
    local component_chest = create_deploy_chest(platform, "blue-chest")
    local trash_chest = create_deploy_chest(platform, "red-chest")
    local platform_info = {
        platform = platform,
        bp_inventory = bp_inventory,
        overflow_inventory = overflow_inventory,
        component_chest = component_chest,
        trash_chest = trash_chest,
    }
    self.bnw.platforms[platform.index] = platform_info
    return platform_info
end

function BnwForce:get_platform(index)
    return self.bnw.platforms[index]
end

function BnwForce:launch_platform()
    local index = self.bnw.landing.platform_index
    return index and self.bnw.platforms[index]
end

return BnwForce