--- Event subscription utility allowing multiple subscriptions to the same event
--- not designed for large amount of events
--- assume subscribed events are unique
---
--- Modified for migrations
local wiretap = {
    storage = nil
}

function wiretap:attach(storage)
    self.storage = storage
end

function wiretap:subscribe(type, name, max_subs, nth_tick)
    if type == "nth_tick" and nth_tick == nil then
        error("Subscribing to nth_tick event with no nth_tick value", 2)
    elseif type ~= "nth_tick" and nth_tick ~= nil then
        error("Subscribing to non-nth_tick event with nth_tick value", 2)
    end
    local subs = self.storage.subscribed_events
    local found = false

    for _, sub in ipairs(subs) do
        if type == sub.type and nth_tick == sub.nth_tick then
            if name == sub.name then
                found = true
                sub.active_count = sub.active_count + 1
                if sub.active_count > max_subs then
                    error("wiretap " .. name .. " active: " .. sub.active_count .. " max: " .. max_subs, 2)
                end
            end
        end
    end

    if not found then
        subs[#subs + 1] = { type = type, name = name, active_count = 1, nth_tick = nth_tick }
    end
end

function wiretap:unsubscribe(type, name, nth_tick)
    if type == "nth_tick" and nth_tick == nil then
        error("Unsubscribing to nth_tick event with no nth_tick value", 2)
    elseif type ~= "nth_tick" and nth_tick ~= nil then
        error("Unsubscribing to non-nth_tick event with nth_tick value", 2)
    end
    local subs = self.storage.subscribed_events
    local unsubscribed_all = false

    for _, sub in ipairs(subs) do
        if type == sub.type and nth_tick == sub.nth_tick then
            if name == sub.name then
                assert(sub.active_count > 0)
                assert(not unsubscribed_all)
                sub.active_count = sub.active_count - 1
                unsubscribed_all = sub.active_count == 0
            end
        end
    end
end

return wiretap
