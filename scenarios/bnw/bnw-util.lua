
local bnw_util = {}

function bnw_util.get_blueprint_bounding_box(blueprint, position, direction, debug_surface)
    if debug_surface then
        rendering.clear()
    end

    local bp_offset = position
    local yellow = {0.5, 1, 0, 1}

    local east = defines.direction.east
    local south = defines.direction.south
    local west = defines.direction.west

    local function draw_point(color, pp)
        rendering.draw_circle{
            color = color,
            radius = 0.1,
            target = pp,
            surface = debug_surface,
            time_to_live = 6000,
        }
    end

    local snapping = blueprint.blueprint_absolute_snapping
    if snapping then
        local grid_pos = blueprint.blueprint_snap_to_grid
        local grid_offset = blueprint.blueprint_position_relative_to_grid
        local size_x, size_y
        local offset_x, offset_y
        offset_x, offset_y = grid_offset.x, grid_offset.y
        if direction == east then
            size_x, size_y = -grid_pos.y, grid_pos.x
        elseif direction == south then
            size_x, size_y = -grid_pos.x, -grid_pos.y
        elseif direction == west then
            size_x, size_y = grid_pos.y, -grid_pos.x
        else
            size_x, size_y = grid_pos.x, grid_pos.y
        end
        local adj_x, adj_y = bp_offset.x - offset_x, bp_offset.y - offset_y
        local snap_x = math.floor(adj_x / size_x) * size_x + offset_x
        local snap_y = math.floor(adj_y / size_y) * size_y + offset_y
        bp_offset = {x = snap_x, y = snap_y}
    end
    if debug_surface then
        rendering.draw_line{
            color = {1, 0.5, 0},
            radius = 0.1,
            from = position,
            to = bp_offset,
            surface = debug_surface,
            time_to_live = 6000,
            width = 1,
        }
    end
    local entities = blueprint.get_blueprint_entities()
    local min_x, min_y, max_x, max_y = math.huge, math.huge, -math.huge, -math.huge
    for i=1,#entities do
        local entity = entities[i]
        local ep = entity.position
        local p_x, p_y
        if direction == east then
            p_x, p_y = -ep.y, ep.x
        elseif direction == south then
            p_x, p_y = -ep.x, -ep.y
        elseif direction == west then
            p_x, p_y = ep.y, -ep.x
        else
            p_x, p_y = ep.x, ep.y
        end

        local dir = (direction + (entity.direction or defines.direction.north)) % 8
        local prototype = prototypes.entity[entity.name]
        local offset = snapping and {x = bp_offset.x + p_x, y = bp_offset.y + p_y} or {x = p_x, y = p_y}
        local cb = prototype.collision_box
        local cblt = cb.left_top
        local cbrb = cb.right_bottom
        local ltx, lty, rbx, rby

        if dir == east then
            ltx, lty = offset.x + cblt.y, offset.y + cbrb.x
            rbx, rby = offset.x + cbrb.y, offset.y + cblt.x
            min_x = ltx < min_x and ltx or min_x
            min_y = rby < min_y and rby or min_y
            max_x = rbx > max_x and rbx or max_x
            max_y = lty > max_y and lty or max_y
        elseif dir == south then
            ltx, lty = offset.x + cbrb.x, offset.y + cbrb.y
            rbx, rby = offset.x + cblt.x, offset.y + cblt.y
            min_x = rbx < min_x and rbx or min_x
            min_y = rby < min_y and rby or min_y
            max_x = ltx > max_x and ltx or max_x
            max_y = lty > max_y and lty or max_y
        elseif dir == west then
            ltx, lty = offset.x + cbrb.y, offset.y + cblt.x
            rbx, rby = offset.x + cblt.y, offset.y + cbrb.x
            min_x = rbx < min_x and rbx or min_x
            min_y = lty < min_y and lty or min_y
            max_x = ltx > max_x and ltx or max_x
            max_y = rby > max_y and rby or max_y
        else
            ltx, lty = offset.x + cblt.x, offset.y + cblt.y
            rbx, rby = offset.x + cbrb.x, offset.y + cbrb.y
            min_x = ltx < min_x and ltx or min_x
            min_y = lty < min_y and lty or min_y
            max_x = rbx > max_x and rbx or max_x
            max_y = rby > max_y and rby or max_y
        end

        if debug_surface then
            draw_point({1, 1, 1}, {min_x, min_y})
            draw_point({0, 1, 1}, {max_x, min_y})
            draw_point({1, 0, 1}, {min_x, max_y})
            draw_point({1, 1, 0}, {max_x, max_y})

            rendering.draw_rectangle{
                color = yellow,
                left_top = {ltx, lty},
                right_bottom = {rbx, rby},
                surface = debug_surface,
                time_to_live = 6000,
            }
        end
    end
    local box
    if snapping then
        box = {
            left_top = {x = math.floor(min_x), y = math.floor(min_y)},
            right_bottom = {x = math.ceil(max_x), y = math.ceil(max_y)},
        }
    else
        local width = math.ceil(max_x - min_x)
        local height = math.ceil(max_y - min_y)

        local odd_w = width % 2 == 1
        local odd_h = height % 2 == 1

        local x_offset = odd_w and 0.5 or 0
        local y_offset = odd_h and 0.5 or 0
        local xo = odd_w and 0 or 0.5
        local yo = odd_h and 0 or 0.5

        local px = math.floor(position.x + xo) + x_offset
        local py = math.floor(position.y + yo) + y_offset

        local half_width = width / 2
        local half_height = height / 2

        local lt = { x = px - half_width, y = py - half_height}
        local rb = { x = px + half_width, y = py + half_height}

        box = { left_top = lt, right_bottom = rb }
    end

    if debug_surface then
        rendering.draw_rectangle{
            color = {0, 0, 1},
            left_top = box.left_top,
            right_bottom = box.right_bottom,
            surface = debug_surface,
            time_to_live = 6000,
        }
    end
    return box
end

function bnw_util.transfer_items_to(destination, source)
    for i=1,#source do
        local stack = source[i]
        if stack.valid_for_read then
            local count = stack.count
            local inserted = destination.insert(stack)
            if inserted == count then
                stack.clear()
            else
                stack.count = stack.count - inserted
                return i
            end
        end
    end
    return nil
end

function bnw_util.trash_items_to(destination, source)
    if source.is_empty() then return end

    destination.sort_and_merge()
    local free = destination.count_empty_stacks()
    local occupied = #source - source.count_empty_stacks()
    if occupied > free then
        local dest_occupied = #destination - free
        destination.resize(free + dest_occupied + occupied)
    end
    assert(not bnw_util.transfer_items_to(destination, source), "Must transfer all items")
end

function bnw_util.copy_items_to(destination, source, options_)
    local options = options_ or {}
    for i=1,#source do
        local stack = source[i]
        if not stack.valid_for_read then
            goto continue
        end
        local place_result = stack.prototype.place_result
        if place_result and place_result.type == options.ignore_type then
           goto continue
        end
        local count = stack.count
        local inserted = destination.insert(stack)
        if inserted < count then
            return i, inserted - count
        end
        ::continue::
    end
    return nil, 0
end

function bnw_util.maybe_roboport(prototype_name)
    local prototype = prototypes.entity[prototype_name]
    if not prototype then return false end

    if prototype.type ~= "roboport" then
        return
    end

    local params = prototype.logistic_parameters
    -- might be an aai signal transmitter/receiver
    return params.construction_radius >= 10 or params.logistic_radius >= 5
            or params.robot_limit > 0 or params.charging_station_count > 0
            or prototype.get_inventory_size(defines.inventory.roboport_robot) > 0
end

function bnw_util.is_roboport(prototype_name)
    local prototype = prototypes.entity[prototype_name]
    if not prototype then return false end

    if prototype.type ~= "roboport" then
        return
    end

    local params = prototype.logistic_parameters
    -- refuse those modular roboport parts
    return params.construction_radius >= 10 and params.logistic_radius >= 5
            and params.robot_limit > 0 and params.charging_station_count > 0
            and prototype.get_inventory_size(defines.inventory.roboport_robot) > 0
end

function bnw_util.get_selected_blueprint(player)
    if not player.is_cursor_blueprint() then
        return nil
    end
    local blueprint = player.cursor_record or player.cursor_stack
    if not blueprint or not blueprint.valid
            or (blueprint.type ~= "blueprint-book" and blueprint.type ~= "blueprint") then
        return nil
    end

    if blueprint.type == "blueprint-book" then
        if blueprint.object_name == "LuaRecord" then
            blueprint = blueprint.get_selected_record(player)
        else
            while blueprint.type == "blueprint-book" do
                local index = blueprint.active_index
                if not index then
                    blueprint = nil
                    break
                end
                local item = blueprint.item
                if not item then
                    blueprint = nil
                    break
                end
                local inventory = item.get_inventory(defines.inventory.fuel)
                if not inventory then
                    blueprint = nil
                    break
                end
                local stack = inventory[index]
                if not stack then
                    blueprint = nil
                    break
                end
                blueprint = stack
            end
        end
    end
    if not blueprint or not blueprint.valid or not blueprint.is_blueprint_setup() then
        return nil
    end

    return blueprint
end

function bnw_util.print_error(msg, obj1, obj2, obj3)
    game.print(msg)
    log(msg)
    if obj1 then
        log(serpent.block(obj1, {valtypeignore = {["function"] = true}}))
    end
    if obj2 then
        log(serpent.block(obj2, {valtypeignore = {["function"] = true}}))
    end
    if obj3 then
        log(serpent.block(obj3, {valtypeignore = {["function"] = true}}))
    end
end

function bnw_util.raise_error(msg, obj1, obj2, obj3)
    log(msg)
    if obj1 then
        log(serpent.block(obj1, {valtypeignore = {["function"] = true}}))
    end
    if obj2 then
        log(serpent.block(obj2, {valtypeignore = {["function"] = true}}))
    end
    if obj3 then
        log(serpent.block(obj3, {valtypeignore = {["function"] = true}}))
    end
    error(msg, 2)
end

local InsertPlanner = {}
InsertPlanner._metatable = { __index = InsertPlanner }

function InsertPlanner:new()
    local obj = {
        insert_plan = {},
        inventories = {},
        stacks = 0
    }
    setmetatable(obj, self._metatable)
    return obj
end

function InsertPlanner:add_item(inventory, id, amount)
    if self.inventories[inventory] == nil then
        self.inventories[inventory] = 0
    end
    local insert_plan, slot_index = self.insert_plan, self.inventories[inventory]

    local name, quality = id[1] or id.name, id[2] or id.quality or "normal"
    local stack_size = prototypes.item[name].stack_size

    local remaining = amount
    local inventory_placement = {}
    local stacks = 0
    while remaining > 0 do
        local stack_amount = math.min(amount, stack_size)
        inventory_placement[#inventory_placement + 1] = {
            inventory = inventory,
            stack = slot_index,
            count = stack_amount}
        slot_index = slot_index + 1
        remaining = remaining - stack_amount
        stacks = stacks + 1
    end
    self.stacks = self.stacks + stacks
    insert_plan[#insert_plan + 1] = {
        id = {name = name, quality = quality},
        items = { in_inventory = inventory_placement }}
    self.inventories[inventory] = slot_index
end

bnw_util.InsertPlanner = InsertPlanner

function bnw_util.random_pos(min, max)
    return {x = math.random(min.x, max.x), y = math.random(min.y, max.y)}
end

function bnw_util.random_real_pos(min, max)
    return {x = min.x + math.random() * (max.x - min.x), y = min.y + math.random() * (max.y - min.y)}
end

function bnw_util.fill_entity_proxy_request(entity, item_type)
    local item_proxy = entity.item_request_proxy
    if item_proxy == nil then
        return
    end

    local insert_plan = item_proxy.insert_plan
    local requests_fulfilled = {}
    for j=1,#insert_plan do
        local request = insert_plan[j]
        local id, items = request.id, request.items
        local prototype = prototypes.item[id.name]
        if not prototype then
            error("Failed to fulfill request, there is no item: " .. id.name)
        end
        local place_result = prototype.place_result
        if not item_type or (place_result and place_result.type == item_type) then
            requests_fulfilled[#requests_fulfilled + 1] = id.name
            for i=1,#items.in_inventory do
                local inventoryPosition = items.in_inventory[i]
                local inventory = entity.get_inventory(inventoryPosition.inventory)
                -- stack is 0-indexed
                local stack = inventory[inventoryPosition.stack + 1]
                if stack ~= nil then
                    stack.set_stack({
                        name = id.name,
                        quality = id.quality,
                        count = inventoryPosition.count})
                else
                    game.print(entity.name
                            .. " does not have inventory "
                            .. inventoryPosition.inventory
                            .. " stack at "
                            .. inventoryPosition.stack - 1)
                end
            end
        end
    end
    local surface, position = item_proxy.surface, item_proxy.position
    item_proxy.destroy()
    local cnt_plan, cnt_requests = #insert_plan, #requests_fulfilled
    if cnt_plan ~= cnt_requests then
        local new_plan = {}
        for j=1,cnt_plan do
            for i=1,cnt_requests do
                if insert_plan[j].id.name == requests_fulfilled[i] then
                    goto next_request
                end
            end
            new_plan[#new_plan + 1] = insert_plan[j]
            ::next_request::
        end
        surface.create_entity{
            name = "item-request-proxy",
            position = position,
            force = entity.force,
            modules = new_plan,
            target = entity}
    end
end

function bnw_util.have_all_items(blueprint, inventory)
    local cost = blueprint.cost_to_build
    for _, item in ipairs(cost) do
        if inventory.get_item_count({name = item.name, quality = item.quality}) < item.count then
            return false
        end
    end
    return true
end

function bnw_util.platform_planet(platform)
    local location = platform.space_location
    if not location or location.type ~= "planet" then
        return nil
    end

    local localProto = location.name
    local candidates = {}
    for _, planet in pairs(game.planets) do
        if planet.prototype.name == localProto then
            candidates[#candidates + 1] = planet
        end
    end

    for j=1,#candidates do
        local candidate = candidates[j]
        local platforms = candidate.get_space_platforms(platform.force)
        for i=1,#platforms do
            if platform == platforms[i] then
                return candidate
            end
        end
    end
    return nil
end

function bnw_util.plan_removal(container, inventory_type)
    if not (container and container.valid) then return end

    local inventory = container.get_inventory(inventory_type)
    if not inventory or inventory.is_empty() then return end

    local proxy = container.item_request_proxy
    if proxy then
        proxy.destroy()
    end
    local items = {}
    for i=1,#inventory do
        local slot = inventory[i]
        if slot.valid_for_read then
            local key = slot.name .. (slot.quality.name or "normal")
            if not items[key] then
                items[key] = {slot.name, slot.quality.name, {}}
            end
            -- 0-based stack index
            local itemPlan = {
                inventory = inventory_type,
                stack = i - 1,
                count = slot.count}
            local plans = items[key][3]
            plans[#plans + 1] = itemPlan
        end
    end
    if not next(items) then
        return
    end

    local plan = {}
    for _, item in pairs(items) do
        plan[#plan + 1] = {
            id = {name = item[1],
                  quality = item[2]},
            items = {in_inventory = item[3]}}
    end
    log(serpent.block({
        name = "item-request-proxy",
        position = container.position,
        force = container.force,
        target = container,
        removal_plan = plan,
        items = items}))
    container.surface.create_entity{
        name = "item-request-proxy",
        position = container.position,
        force = container.force,
        target = container,
        modules = {},
        removal_plan = plan}
end

local function surface_planet_name(surface)
    local planet = surface.planet
    return planet and planet.prototype.name or "default"
end

function bnw_util.get_planet_config(cfg, surface)
    local planet = surface_planet_name(surface)
    return cfg[planet] or cfg["default"]
end

function bnw_util.total_ticks(current, wait, period)
    local remainder = current % period
    local ttn
    if remainder < 1 then
        ttn = 0
    else
        ttn = period - remainder
    end
    return wait + ttn
end

function bnw_util.bounding_box_union(box1, box2)
    local lt1 = box1.left_top
    local rb1 = box1.right_bottom
    local lt2 = box2.left_top
    local rb2 = box2.right_bottom
    local union_lt = {x = math.min(lt1.x, lt2.x), y = math.min(lt1.y, lt2.y)}
    local union_rb = {x = math.max(rb1.x, rb2.x), y = math.max(rb1.y, rb2.y)}
    return {left_top = union_lt, right_bottom = union_rb}
end

function bnw_util.bounding_box_center(box)
    local lt = box.left_top
    local rb = box.right_bottom
    return {x = (lt.x + rb.x) / 2, y = (lt.y + rb.y) / 2}
end

function bnw_util.bounding_box_grow_to_square(box)
    local lt = box.left_top
    local rb = box.right_bottom
    local width = rb.x - lt.x
    local height = rb.y - lt.y
    local size = width > height and width or height
    local center_x = (lt.x + rb.x) / 2
    local center_y = (lt.y + rb.y) / 2
    local half = size / 2
    return {left_top = {x = center_x - half, y = center_y - half},
            right_bottom = {x = center_x + half, y = center_y + half}}
end

function bnw_util.bounding_box_to_chunks(box)
    local lt = box.left_top
    local rb = box.right_bottom
    local chunk_lt = {x = math.floor(lt.x / 32), y = math.floor(lt.y / 32)}
    local chunk_rb = {x = math.floor(rb.x / 32), y = math.floor(rb.y / 32)}
    return {left_top = chunk_lt, right_bottom = chunk_rb}
end

function bnw_util.bounding_box_offset(box, position)
    local lt = box.left_top
    local rb = box.right_bottom
    local offset_lt = {x = lt.x + position.x, y = lt.y + position.y}
    local offset_rb = {x = rb.x + position.x, y = rb.y + position.y}
    return {left_top = offset_lt, right_bottom = offset_rb}
end

function bnw_util.random_point_outside_box(extent, margin_min, margin_max)
    local side = math.random(1, 4) -- 1=left, 2=right, 3=top, 4=bottom
    local margin = math.random(margin_min, margin_max)
    if side == 1 then
        local x = extent.left_top.x - margin
        local y = math.random(math.floor(extent.left_top.y) - margin_max, math.ceil(extent.right_bottom.y) + margin_max)
        return x, y
    elseif side == 2 then
        local x = extent.right_bottom.x + margin
        local y = math.random(math.floor(extent.left_top.y) - margin_max, math.ceil(extent.right_bottom.y) + margin_max)
        return x, y
    elseif side == 3 then
        local y = extent.left_top.y - margin
        local x = math.random(math.floor(extent.left_top.x) - margin_max, math.ceil(extent.right_bottom.x) + margin_max)
        return x, y
    else
        local y = extent.right_bottom.y + margin
        local x = math.random(math.floor(extent.left_top.x) - margin_max, math.ceil(extent.right_bottom.x) + margin_max)
        return x, y
    end
end

return bnw_util