local gui = {}

local function hide_bp(tree)
    local el = tree[1].children
    for i=1,9 do el[i].visible = false end
    tree[2].caption = prototypes.item["blueprint"].localised_name
end

local function add_bp_icon(parent, size, padding, toplevel)
    local typ, style
    if toplevel then
        typ = "sprite-button"
        style = "transparent_slot"
    else
        typ = "sprite"
        style = "image"
    end
    local icon = parent.add {
        type = typ,
        resize_to_sprite = false,
        style = style,
    }
    icon.style.size = size
    icon.style.padding = padding
    icon.visible = false
end

local function show_bp(tree, blueprint)
    local el = tree[1].children
    tree[2].caption = blueprint.label or prototypes.item["blueprint"].localised_name
    local quality
    local _icons = {false, false, false, false}
    local count = 0
    for _, p in ipairs(blueprint.preview_icons) do
        local t, n, i, q = p.signal.type, p.signal.name, p.index, p.signal.quality
        if n then
            _icons[i] = (t == "virtual" and "virtual-signal" or t or "item") .. "/" .. n
            quality = quality or q
            count = count + 1
        end
    end
    if count == 0 then
        for _, d in ipairs(blueprint.default_icons) do
            local t, n, i, q = d.signal.type, d.signal.name, d.index, d.signal.quality
            if n then
                _icons[i] = (t == "virtual" and "virtual-signal" or t or "item") .. "/" .. n
                quality = quality or q
            end
        end
    end
    local icons = {}
    for i=1,4 do
        -- TODO: Use placeholder question mark
        if _icons[i] and helpers.is_valid_sprite_path(_icons[i]) then
            icons[#icons + 1] = _icons[i]
        end
    end
    el[1].visible = true
    for i=2,9 do el[i].visible = false end

    local nicons = #icons
    if nicons == 1 then
        el[2].sprite = icons[1]
        el[2].visible = true
        if quality then
            el[9].sprite = "quality/" .. quality
            el[9].visible = true
        end
    elseif nicons == 2 then
        el[3].sprite = icons[1]
        el[3].visible = true
        el[4].sprite = icons[2]
        el[4].visible = true
    elseif nicons > 2 then
        for i=1,#icons do
            local nel = el[4 + i]
            nel.sprite = icons[i]
            nel.visible = true
        end
    end
end

local function can_launch(force, player, platform_info)
    if not (platform_info.bp_inventory and platform_info.bp_inventory.valid) then
        bnwutil.print_error("Encountered invalid inventory", platform_info)
    end
    local blueprint = platform_info.bp_inventory[1]
    if not (blueprint.valid_for_read and blueprint.is_blueprint) then
        return nil, false
    end
    local chest = platform_info.component_chest
    if not chest or not chest.valid then
        bnwutil.print_error("Encountered invalid chest", platform_info)
        return nil, false
    end

    -- this allows editor to launch on behalf of other forces
    local bnw_force = BnwForce.get(force.name)
    if not bnw_force then
        bnwutil.raise_error("encountered invalid bnw_force: " .. force.name)
    end

    if not bnw_force:can("prepare") then return end

    local planet = bnwutil.platform_planet(platform_info.surface)
    local has_creative = remote.interfaces["creative-mode"] and remote.call("creative-mode", "is_enabled")
    local skip_checks = has_creative or player.controller_type == defines.controllers.editor
    local items_valid = false
    if blueprint.valid_for_read then
        local inventory = platform_info.component_chest.get_inventory(defines.inventory.chest)
        items_valid = bnwutil.have_all_items(blueprint, inventory)
    end
    if not (planet and (skip_checks or items_valid)) then
        return nil, false
    end
    return planet, has_creative
end

local function ensure_player_info_exists(index)
    local player_info = storage.players[index]
    if not player_info then
        player_info = {
            translation_requests = {},
            launch_inventory_requests = {},
            launch_inventory_slots = {},
        }
        storage.players[index] = player_info
    end
    return player_info
end

local function platform_bp_number(platform_info)
    local slot = platform_info.bp_inventory[1]
    if slot.valid_for_read then
        return slot.item_number, slot
    end
    return nil, nil
end

-- TODO: Recreate when space hub drop capacity change

local function refresh_inventory(player, player_info, root, platform_info)
    local inv = root.children[2].children[4]

    local inventory = platform_info.component_chest.get_inventory(defines.inventory.chest)
    -- TODO: quality
    -- TODO: dehardcode size
    local requests = player_info.launch_inventory_requests
    local slots = player_info.launch_inventory_slots

    local proxy = platform_info.component_chest.item_request_proxy
    local inventory_requests = {}
    if proxy then
        for j=1,#proxy.insert_plan do
            local request = proxy.insert_plan[j]
            -- TODO: quality
            local name, quality = request.id.name, request.id.quality
            local contents = request.items.in_inventory
            for i=1,#contents do
                local r = contents[i]
                local idx = r.stack + 1
                local count = r.count or 1
                local preq = requests[idx]
                if preq ~= nil then
                    if name == preq[1] and count == preq[2] and quality == preq[3] then
                        inventory_requests[idx] = requests[idx]
                        goto continue
                    end
                end
                inventory_requests[idx] = {name, count, quality or "normal"}
                ::continue::
            end
        end
    end
    local inventory_slots = {}
    for i=1,10 do
        local stack = inventory[i]
        if stack.valid_for_read then
            local preq = slots[i]
            if preq ~= nil then
                if stack.name == preq[1] and stack.count == preq[2] and stack.quality == preq[3] then
                    inventory_requests[i] = requests[i]
                    goto continue
                end
            end
            inventory_slots[i] = {stack.name, stack.count, stack.quality and stack.quality.name or "normal"}
        end
        ::continue::
    end
    for i=1,10 do
        local request, prequest = inventory_requests[i], requests[i]
        local slot, pslot = inventory_slots[i], slots[i]
        local button = inv.children[1].children[i]

        if request ~= prequest then
            if request == nil then
                button.sprite = nil
                button.children[3].caption = ""
                -- TODO: quality
            else
                button.sprite = "item/" .. request[1]
                button.children[3].caption = request[2]
                -- TODO: quality
            end
        end

        if slot ~= pslot then
            if slot == nil then
                button.elem_tooltip = nil
                button.children[1].sprite = nil
                button.children[2].caption = ""
                -- TODO: quality
            else
                button.elem_tooltip = {type = "item-with-quality", name = slot[1], quality = slot[3]}
                button.children[1].sprite = "item/" .. slot[1]
                button.children[2].caption = slot[2]
                -- TODO: quality
            end
        end
    end
    player_info.launch_refreshed = true
    player_info.launch_inventory_requests = inventory_requests
    player_info.launch_inventory_slots = inventory_slots

    local bp_number, bp = platform_bp_number(platform_info)
    if player_info.blueprint_item_number ~= bp_number then
        player_info.blueprint_item_number = bp_number
        local tree = root.children[2].children[2].children
        if bp_number then
            show_bp(tree, bp)
        else
            hide_bp(tree)
        end
    end

    local force = game.forces[player_info.platform_force_name]
    if not (force and force.valid) then
        error("Expected valid force")
    end
    local launch_button = root.children[2].children[8].children[2]
    local planet = can_launch(force, player, platform_info)
    if planet then
        local planet_str = "[planet=" .. planet.name .. "]"
        launch_button.enabled = true
        launch_button.caption = {"", planet_str, " ", {"gui.rocket-launch"}}
    else
        launch_button.enabled = false
        launch_button.caption = {"gui.rocket-launch"}
    end
end

local function create_inventory_gui(o)
    local parent, name = assert(o.parent), o.name
    local min_height, max_height = assert(o.min_height), assert(o.max_height)
    local total_slots = o.total_slots or 10
    local assume_width = o.assume_width
    local disabled = o.disabled or false
    if total_slots < 1 then
        error("There must be at least one slot")
    end
    local inv = parent.add{
        type = "scroll-pane",
        name = name,
        style = "shallow_slots_scroll_pane",
    }
    local rows = math.ceil(total_slots/10)
    local scrollbar_space = (max_height < rows) and 2 or 0
    if assume_width and total_slots < 10 and total_slots < assume_width then
        inv.style.width = assume_width * 40 + scrollbar_space
    else
        inv.style.width = 10 * 40 + scrollbar_space
    end
    inv.style.minimal_height = min_height * 40
    inv.style.maximal_height = max_height * 40

    local first_row_margin = {0, 0, 0, 0}
    local other_row_margin = {-4, 0, 0, 0}
    for row=1,rows do
        local inv_row = inv.add{
            type = "flow",
            direction = "horizontal",
        }
        if row == 1 then
            inv_row.style.margin = first_row_margin
        elseif row == rows then
            inv_row.style.margin = other_row_margin
        else
            inv_row.style.margin = other_row_margin
        end

        local slots = 10
        if row == rows then
            local final_slots = math.fmod(total_slots, 10)
            if final_slots ~= 0 then
                slots = final_slots
            end
        end
        for _=1,slots do
            -- TODO: Quality
            local but = inv_row.add{
                type = "sprite-button",
                style = "slot_button",
            }
            but.style.margin = {0, -4, 0, 0}
            but.style.horizontal_align = "right"
            but.style.vertical_align = "bottom"
            but.enabled = not disabled
            local icon = but.add{
                type = "sprite-button",
                resize_to_sprite = false,
                style = "transparent_slot",
            }
            icon.enabled = true
            icon.style.size = {32, 32}
            icon.visible = true
            icon.ignored_by_interaction = true
            local count = but.add{
                type = "label",
                style = "count_label",
            }
            count.style.size = {32, 32}
            count.style.padding = {0, -1, -4, 0}
            count.style.horizontal_align = "right"
            count.style.vertical_align = "bottom"
            local request = but.add{
                type = "label",
                style = "count_label",
            }
            request.style.size = {32, 24}
            request.style.padding = {0, -1, 0, 0}
            request.style.horizontal_align = "right"
            request.style.vertical_align = "bottom"
        end
    end
    return inv
end

local function create_gui(player)
    if not player.valid then return end
    local old = player.gui.screen[MOD_PREFIX .. GUI_NAME]
    if old then old.destroy() end

    local root = player.gui.screen

    local container = root.add{
        type = "frame",
        name = MOD_PREFIX .. GUI_NAME,
        direction = "vertical",
    }
    container.visible = false

    -- 1
    local header = container.add{
        type = "flow",
        direction = "horizontal",
    }

    -- 1.1
    local title = header.add{
        type = "label",
        caption = "Colonize this planet",
        style = "frame_title",
    }
    title.drag_target = container
    title.style.top_margin = -3
    title.style.bottom_margin = 3

    -- 1.2
    local drag = header.add{
        type = "empty-widget",
        style = "draggable_space_header",
    }
    drag.drag_target = container
    drag.style.height = 24
    drag.style.right_margin = 4
    drag.style.horizontally_stretchable = true

    -- 1.3
    header.add{
        type = "sprite-button",
        style = "close_button",
        sprite = "utility/close",
        name = MOD_PREFIX .. "close-colonization-gui"
    }

    -- 2
    local frame = container.add{
        type = "frame",
        direction = "vertical",
        style = "entity_frame",
    }
    -- 2.1
    local preview_frame = frame.add{
        type = "frame",
        style = "frame_around_center",
    }

    -- 2.1.1
    local preview = preview_frame.add{
        type = "entity-preview",
    }
    preview.entity = storage.preview_pod
    preview.style.size = {LANDER_GUI_INNER_WIDTH, 200}

    -- 2.2
    local bp_flow = frame.add{
        type = "flow",
        direction = "horizontal",
    }

    -- 2.2.1
    local itembut = bp_flow.add{
        type = "button",
        name = MOD_PREFIX .. "item-button",
        style = "yellow_inventory_slot",
    }

    itembut.style.margin = {0, 0, 0, 2}

    -- 2.2.1.1
    add_bp_icon(itembut, {32, 32}, {0, 0, 0, 0}, true)
    itembut.children[1].sprite = "item/blueprint"

    -- 2.2.1.2
    add_bp_icon(itembut, {24, 24}, {4, -4, -4, 4})

    -- 2.2.1.3
    -- 2.2.1.4
    add_bp_icon(itembut, {14, 14}, {9, -1, -9, 1})
    add_bp_icon(itembut, {14, 14}, {9, -17, -9, 17})


    -- 2.2.1.5
    -- 2.2.1.6
    -- 2.2.1.7
    -- 2.2.1.8
    add_bp_icon(itembut, {15, 15}, {1, -1, -1, 1})
    add_bp_icon(itembut, {15, 15}, {1, -17, -1, 16})
    add_bp_icon(itembut, {15, 15}, {16, -1, -17, 1})
    add_bp_icon(itembut, {15, 15}, {16, -17, -17, 16})

    -- Only show quality for the big icon, less headache
    -- 2.2.1.9
    add_bp_icon(itembut, {9, 9}, {16, -7, -19, 4})

    -- 2.2.2
    local bp_text = bp_flow.add{
        type = "label",
        caption = prototypes.item["blueprint"].localised_name,
        name = MOD_PREFIX .. "blueprint-name",
        style = "tooltip_title_label",
    }
    bp_text.style.margin = {9, 0, 0, 1}

    -- 2.3
    frame.add{
        type = "line",
    }

    -- TODO: Derive slots from container size
    -- 2.4
    local inv = create_inventory_gui{
        parent = frame,
        min_height = 1,
        max_height = 3,
        total_slots = 10,
        disabled = true,
    }
    inv.style.margin = {0, 0, 0, 2}

    -- 2.5
    local trash_separator = frame.add{
        type = "line"
    }
    trash_separator.visible = false

    -- 2.6
    local trash_placeholder = frame.add{
        type = "sprite"
    }
    trash_placeholder.visible = false

    -- 2.7
    local padding_element = frame.add{
        type = "sprite"
    }
    padding_element.visible = false

    -- 2.8
    local button_flow = frame.add{
        type = "flow",
        direction = "horizontal",
    }

    -- 2.8.1
    local spacing = button_flow.add{
        type = "empty-widget"
    }
    spacing.style.horizontally_stretchable = true

    -- 2.8.2
    button_flow.add{
        type = "button",
        name = MOD_PREFIX .. "launch-colonization-pod",
        style = "forward_button",
        caption = {"gui.rocket-launch"},
    }

    local player_info = ensure_player_info_exists(player.index)
    local request_id = player.request_translation({"gui-remote-view.land-on-planet"})
    player_info.translation_requests[request_id] = "colonization-title"
    return container
end

local function create_open_gui_button(player)
    local root = player.gui.relative
    local frame = root[MOD_PREFIX .. GUI_OPEN_NAME]
    if frame then
        frame.destroy()
    end

    local anchor = {
        gui = defines.relative_gui_type.space_platform_hub_gui,
        position = defines.relative_gui_position.bottom,
    }

    frame = root.add{
        type = "frame",
        direction = "horizontal",
        name = MOD_PREFIX .. GUI_OPEN_NAME,
        anchor = anchor
    }

    frame.add{
        type = "button",
        name = MOD_PREFIX .. "open-colonization-gui",
    }

    local player_info = ensure_player_info_exists(player.index)

    player_info.translation_requests[player.request_translation({"gui-remote-view.land-on-planet"})] = "hub-button"
end

function gui.show_colonization_gui(player, secondary)
    local player_info = ensure_player_info_exists(player.index)
    -- If we're opening the gui, it should be closed
    if player_info.launch_gui_open == true then
        gui.hide_colonization_gui(player)
    end

    local platform = player.surface.platform
    if not platform then return end

    local bnw_force = BnwForce.get(platform.force.name)
    if not bnw_force then return end
    if bnw_force:is("invalid") then
        bnw_force:trigger("revalidate")
    end

    local container = player.gui.screen[MOD_PREFIX .. GUI_NAME]
    if not (container and container.valid) then
        container = create_gui(player)
        player_info.launch_inventory_requests = {}
        player_info.launch_inventory_slots = {}
        player_info.blueprint_item_number = nil
    end
    container.visible = true
    container.force_auto_center()
    player_info.launch_gui_open = true
    if secondary then
        wiretap:subscribe("nth_tick", "handle_refresh_inventory", table_size(storage.players), 13)
        return
    end

    player_info.platform_surface_index = platform.surface.index
    player_info.platform_force_name = platform.force.name

    local platform_info = bnw_force:get_platform(platform.surface.index)
    if not platform_info then
        platform_info = bnw_force:add_platform(platform.surface.index)
    end

    wiretap:subscribe("nth_tick", "handle_refresh_inventory", table_size(storage.players), 13)
    refresh_inventory(player, player_info, container, platform_info)
    player.opened = container
end

function gui.hide_colonization_gui(player, tick, reason)
    local container = player.gui.screen[MOD_PREFIX .. GUI_NAME]
    local player_info = storage.players[player.index]
    if container and container.valid and container.visible then
        container.visible = false
        if player_info then
            player_info.launch_gui_closed_tick = tick
            player_info.launch_gui_closed_reason = reason
        end
    end
    if player_info and player_info.launch_gui_open == true then
        player_info.launch_gui_open = false
        wiretap:unsubscribe("nth_tick", "handle_refresh_inventory", 13)
    end
end

function gui.handle_hiding_gui(event)
    local player = game.get_player(event.player_index)
    gui.hide_colonization_gui(player, game.ticks_played, event.name)
    gui.hide_location_tooltip(event.player_index)
end

-- We need to do this circus, because there is an icon in the translated string
function gui.handle_translation(event)
    if not event.translated then
        return
    end
    local player_info = storage.players[event.player_index]
    if not player_info then
        return
    end
    local request = player_info.translation_requests[event.id]
    if not request then
        return
    end

    player_info.translation_requests[event.id] = nil
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    if request == "hub-button" then
        local root = player.gui.relative[MOD_PREFIX .. GUI_OPEN_NAME]
        if not (root and root.valid) then
            return
        end
        local element = root.children[1]
        local sprite = "entity/" .. storage.config.misc_settings.construction_robot
        if helpers.is_valid_sprite_path(sprite) then
            local icon = "[img=" .. sprite .. "]"
            element.caption = string.gsub(event.result, "%[img=entity/character%]", icon)
        else
            element.caption = event.result
        end
    elseif request == "colonization-title" then
        local root = player.gui.screen[MOD_PREFIX .. GUI_NAME]
        if not (root and root.valid) then
            return
        end
        local element = root.children[1].children[1]
        element.caption = string.gsub(event.result, "%[img=entity/character%]%s*", "")
    else
        return
    end

end

function gui.handle_refresh_inventory()
    for player_index, player_info in pairs(storage.players) do
        if player_info.platform_surface_index then
            local player = game.get_player(player_index)
            if player and player.valid and player.gui.screen[MOD_PREFIX .. GUI_NAME] then
                local bnw_force = BnwForce.get(player_info.platform_force_name)
                local platform_info = bnw_force:get_platform(player_info.platform_surface_index)
                if platform_info then
                    refresh_inventory(player, player_info, player.gui.screen[MOD_PREFIX .. GUI_NAME], platform_info)
                end
            end
            -- We don't get close events all the time
        elseif player_info.launch_gui_open == true then
            local player = game.get_player(player_index)
            gui.hide_colonization_gui(player)
        end
    end
end

function gui.handle_launch_button(player, _, _)
    local player_info = storage.players[player.index]
    if not player_info or not player_info.platform_surface_index then return end
    local platform_surface = game.get_surface(player_info.platform_surface_index)
    if not platform_surface then return end

    local bnw_force = BnwForce.get(player_info.platform_force_name)

    local platform = platform_surface.platform
    if not platform then return end
    -- TODO: Migrate player platform index
    local platform_info = bnw_force:get_platform(player_info.platform_surface_index)
    local planet, creative = can_launch(platform.force, player, platform_info)
    if not planet then return end

    local surface = planet.create_surface()
    bnw_force:set_destination{
        use_offset = true,
        randomize_offset = true,
        surface = surface.name,
        platform = platform_info.platform,
        position = {0, 0},
        launch_type = creative and "creative" or "platform"}
    bnw_force:create_pod(platform_info.platform.hub)
end

local function clear_blueprint(player, button, launch_platform)
    local chest = launch_platform.component_chest
    local bp_inventory = launch_platform.bp_inventory
    hide_bp(button.parent.children)
    local proxy = chest.item_request_proxy
    if proxy then proxy.destroy() end
    local typ = defines.inventory.chest
    bnwutil.trash_items_to(launch_platform.overflow_inventory, chest.get_inventory(typ))
    bnwutil.transfer_items_to(launch_platform.trash_chest.get_inventory(typ), launch_platform.overflow_inventory)
    bnwutil.plan_removal(launch_platform.trash_chest, defines.inventory.chest)
    if bp_inventory and bp_inventory.valid and not bp_inventory.is_empty() and bp_inventory[1].valid_for_read then
        player.play_sound{path="utility/inventory_click", override_sound_type = "gui-effect"}
        bp_inventory[1].clear()
        local player_info = storage.players[player.index]
        refresh_inventory(player, player_info, player.gui.screen[MOD_PREFIX .. GUI_NAME], launch_platform)
    end
end

local function try_set_blueprint(player, button, launch_platform)
    local chest = launch_platform.component_chest
    if not player.cursor_record
            and not player.cursor_ghost
            and player.cursor_stack
            and not player.cursor_stack.valid_for_read then
        local bp_inventory = launch_platform.bp_inventory
        local inventory = player.get_main_inventory()
        if bp_inventory and bp_inventory.valid and not bp_inventory.is_empty()
                and bp_inventory[1].valid_for_read and inventory and not inventory.is_full() then
            player.play_sound{path="utility/inventory_click", override_sound_type = "gui-effect"}
            player.cursor_stack.set_stack(bp_inventory[1])
        end
    end
    -- TODO: Include a nuke when planet already colonized
    local blueprint = bnwutil.get_selected_blueprint(player)
    if not blueprint or (blueprint.object_name == "LuaRecord" and blueprint.is_preview) then
        return
    end
    local planner = bnwutil.InsertPlanner:new()
    -- TODO: Dehardcode stack limit
    local stack_limit = 10
    local have_roboport = false
    local have_power_source = false
    local have_robots = false
    local have_poles = false
    local have_storage = false
    local can_build = true
    for _, item in ipairs(blueprint.cost_to_build) do
        local prototype = prototypes.item[item.name]
        if prototype then
            local place_result = prototype.place_result
            if place_result then
                -- TODO: Support modular roboports
                if bnwutil.is_roboport(place_result.name) then
                    have_roboport = true
                elseif place_result.type == "accumulator"
                        or place_result.type == "solar-panel"
                        or place_result.type == "lightning-attractor" then
                    have_power_source = true
                elseif place_result.type == "construction-robot" then
                    have_robots = true
                elseif place_result.type == "electric-pole" then
                    have_poles = true
                elseif place_result.type == "logistic-container"
                        and (place_result.logistic_mode == "storage"
                        or place_result.logistic_mode == "buffer"
                        or place_result.logistic_mode == "requester") then
                    have_storage = true
                end
            end
            planner:add_item(defines.inventory.chest, {item.name, item.quality}, item.count)
            -- don't iterate over ginormous blueprints
            if planner.stacks > stack_limit then
                can_build = false
                break
            end
        end
    end
    -- TODO: Dehardcode robot item and amount
    if not have_robots then
        planner:add_item(defines.inventory.chest, {storage.config.misc_settings.construction_robot}, 50)
    end

    local have_all = have_roboport and have_power_source and have_poles and have_storage
    if not can_build or planner.stacks > stack_limit or not have_all then
        player.play_sound{path="utility/cannot_build", override_sound_type = "gui-effect"}
        return
    end
    local stack = launch_platform.bp_inventory[1]
    if blueprint.object_name == "LuaRecord" then
        stack.import_stack(blueprint.export_record())
    else
        stack.set_stack(blueprint)
    end
    show_bp(button.parent.children, stack)
    local proxy = chest.item_request_proxy
    if proxy then proxy.destroy() end
    local typ = defines.inventory.chest
    bnwutil.trash_items_to(launch_platform.overflow_inventory, chest.get_inventory(typ))
    bnwutil.transfer_items_to(launch_platform.trash_chest.get_inventory(typ), launch_platform.overflow_inventory)
    bnwutil.plan_removal(launch_platform.trash_chest, defines.inventory.chest)
    player.play_sound{path="utility/inventory_click", override_sound_type = "gui-effect"}
    chest.surface.create_entity{
        name = "item-request-proxy",
        position = chest.position,
        force = chest.force,
        target = chest,
        modules = planner.insert_plan}
    local player_info = storage.players[player.index]
    refresh_inventory(player, player_info, player.gui.screen[MOD_PREFIX .. GUI_NAME], launch_platform)
end

function gui.handle_blueprint_button(player, button, event)
    local player_info = storage.players[player.index]
    if not player_info then
        game.print("handle_blueprint_button: player_info absent")
        return
    end
    if not player_info.platform_surface_index then
        game.print("handle_blueprint_button: player_info.platform_surface_index absent")
        return
    end

    local bnw_force = BnwForce.get(player_info.platform_force_name)
    if not bnw_force:can("prepare") then
        player.play_sound{path="utility/cannot_build", override_sound_type = "gui-effect"}
        return
    end

    local launch_platform = bnw_force:get_platform(player_info.platform_surface_index)
    local mouse = event.button
    if mouse == defines.mouse_button_type.right then
        clear_blueprint(player, button, launch_platform)
        return
    end
    if mouse == defines.mouse_button_type.left then
        try_set_blueprint(player, button, launch_platform)
        return
    end
end

function gui.ensure_button_gui_exists(player)
    local button = player.gui.relative[MOD_PREFIX .. GUI_OPEN_NAME]
    if not (button and button.valid) then
        gui.create_open_gui_button(player)
    end
end

function gui.create_guis_for_player(player)
    create_open_gui_button(player)
    create_gui(player)
end

local function create_location_tooltip_gui(player)
    local root = player.gui.screen

    local tooltip = root[MOD_PREFIX .. GUI_LOCATION_TOOLTIP_NAME]
    if tooltip then
        tooltip.destroy()
    end

    tooltip = root.add{
        type = "frame",
        name = MOD_PREFIX .. GUI_LOCATION_TOOLTIP_NAME,
        direction = "vertical",
        style = "tooltip_frame"
    }
    tooltip.style.bottom_padding = 4
    tooltip.ignored_by_interaction = true

    local hint = tooltip.add{
        type = "label",
        caption = {"gui-text-tags.gps-title"},
    }
    hint.style.top_margin = -1
    hint.style.bottom_margin = 4

    local view = tooltip.add{
        type = "camera",
        surface_index = 1,
        zoom = 0.5,
        position = {0, 0},
    }
    local resolution = player.display_resolution
    local scale = player.display_scale
    local denormalized_width = resolution.width / scale
    local denormalized_height = resolution.height / scale
    view.style.minimal_width = denormalized_height / 2
    view.style.minimal_height = denormalized_height / 2
    view.style.maximal_width = denormalized_width / 4
    view.style.maximal_height = denormalized_height / 2

    return tooltip
end

function gui.show_location_tooltip(player, location)
    local player_info = ensure_player_info_exists(player.index)
    -- If we're opening the tooltip, it should be closed
    if player_info.location_tooltip_open == true then
        gui.hide_location_tooltip(player.index)
    end

    local surface = game.get_surface(location.surface)
    if not surface then return end
    local tooltip = player.gui.screen[MOD_PREFIX .. GUI_LOCATION_TOOLTIP_NAME]
    if not (tooltip and tooltip.valid) then
        tooltip = create_location_tooltip_gui(player)
    end
    tooltip.visible = true
    player_info.location_tooltip_open = true
    local camera = tooltip.children[2]
    camera.position = location.position
    camera.surface_index = surface.index

    wiretap:subscribe("nth_tick", "handle_refresh_tooltip", table_size(storage.players), 13)
end

function gui.hide_location_tooltip(player_index)
    local player_info = storage.players[player_index]
    local player = game.get_player(player_index)
    if player and player.valid then
        local tooltip = player.gui.screen[MOD_PREFIX .. GUI_LOCATION_TOOLTIP_NAME]
        if tooltip and tooltip.valid and tooltip.visible then
            tooltip.visible = false
        end
    end
    if player_info and player_info.location_tooltip_open == true then
        player_info.location_tooltip_open = false
        wiretap:unsubscribe("nth_tick", "handle_refresh_tooltip", 13)
    end
end

function gui.handle_player_selected_event(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end
    if event.last_entity == storage.neutral_launcher then
        gui.hide_location_tooltip(event.player_index)
    elseif player.selected == storage.neutral_launcher then
        assert(player.selected, "Selection should not be empty: " .. player.name)
        local bnw_force = BnwForce.try_get(player.force.name)
        if bnw_force then
            local home = bnw_force.bnw.home
            if home then
                gui.show_location_tooltip(player, home)
            else
                game.print("Home not found for force: " .. player.force.name)
            end
        end
    end
end

function gui.handle_refresh_tooltip()
    for player_index, player_info in pairs(storage.players) do
        local player = game.get_player(player_index)
        local should_close = not (player and player.valid
                and player.gui.screen[MOD_PREFIX .. GUI_LOCATION_TOOLTIP_NAME])
                or player.selected ~= storage.neutral_launcher
        if player_info.location_tooltip_open == true and should_close then
            gui.hide_location_tooltip(player_index)
        end
    end
end

return gui