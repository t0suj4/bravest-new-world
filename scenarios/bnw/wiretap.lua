
--- Event subscription utility allowing multiple subscriptions to the same event
--- not designed for large amount of events
--- assume subscribed events are unique
local wiretap = {
    ready = false,
    event_listeners = {},
    pre_subscribed_events = {},
}

-- Not a method
function wiretap.event_handler(event)
    wiretap:handle_event(event)
end

function wiretap.tick_event_handler(data)
    wiretap:handle_event({name = "nth_tick", tick = data.tick, nth_tick = data.nth_tick})
end


-- Does not check for duplicates
function wiretap:register_listener(name, func)
    if self:listener_exists(name) then
        error("Double listener registration")
    end
    self.event_listeners[#self.event_listeners + 1] = {
        name = assert(name),
        func = assert(type(func) == "function" and func)}
end

function wiretap:init()
    local subscribed_events = storage.subscribed_events or {}
    local presubs = self.pre_subscribed_events
    local listeners = self.event_listeners
    local subs = {}
    log(serpent.block({
        subscribed_events = subscribed_events,
        presubs = presubs,
        listeners = listeners},
            {valtypeignore = {["function"] = true}}))
    -- This is the only time when the table gets compacted
    -- also takes care of removed listeners in mod updates
    for _, sub in ipairs(subscribed_events) do
        local has_listeners = false
        for _, listener in ipairs(listeners) do
            if sub.name == listener.name then
                has_listeners = true
                break
            end
        end
        if sub.active_count > 0 and has_listeners
                and ((sub.type == "nth_tick" and sub.nth_tick ~= nil)
                or (sub.type ~= "nth_tick" and sub.nth_tick == nil))  then
            subs[#subs + 1] = sub
        end
    end
    for _, presub in ipairs(presubs) do
        local present = false
        for _, sub in ipairs(subs) do
            if sub.type == presub.type and sub.name == presub.name and sub.nth_tick == presub.nth_tick then
                present = true
                sub.active_count = sub.active_count + presub.active_count
            end
        end
        if not present and presub.active_count > 0 then
            subs[#subs + 1] = presub
        end
    end
    storage.subscribed_events = subs
    self:load()
end

function wiretap:load()
    local subs = assert(storage.subscribed_events)
    self.ready = true
    local subbed_types = {}
    local subbed_ticks = {}

    for _, sub in ipairs(subs) do
        if sub.active_count > 0 then
            if sub.type == "nth_tick" then
                if subbed_ticks[sub.nth_tick] == nil then
                    subbed_ticks[sub.nth_tick] = true
                    self:attach_tick_listener(sub.nth_tick)
                end
            elseif subbed_types[sub.type] == nil then
                subbed_types[sub.type] = true
                self:attach_listener(sub.type)
            end
        end
    end
end

function wiretap:attach_tick_listener(ticks)
    log("Attaching tick listener: " .. ticks)
    script.on_nth_tick(ticks, self.tick_event_handler)
end

function wiretap:detach_tick_listener(ticks)
    log("Detaching tick listener: " .. ticks)
    script.on_nth_tick(ticks, nil)
end

function wiretap:attach_listener(type)
    log("Attaching handler type: " .. type)
    script.on_event(type, self.event_handler)
end

function wiretap:detach_listener(type)
    log("Detaching handler type: " .. type)
    script.on_event(type, nil)
end

function wiretap:handle_event(event)
    local subs = storage.subscribed_events
    local listeners = self.event_listeners
    for _, sub in ipairs(subs) do
        if sub.active_count > 0 and sub.type == event.name and event.nth_tick == sub.nth_tick then
            for _, listener in ipairs(listeners) do
                if sub.name == listener.name then
                    listener.func(event)
                end
            end
        end
    end
end

function wiretap:listener_exists(name)
    local listeners = self.event_listeners
    for _, listener in ipairs(listeners) do
        if name == listener.name then
            return true
        end
    end
    return false
end

function wiretap:subscribe(type, name, max_subs, nth_tick)
    if type == "nth_tick" and nth_tick == nil then
        error("Subscribing to nth_tick event with no nth_tick value")
    elseif type ~= "nth_tick" and nth_tick ~= nil then
        error("Subscribing to non-nth_tick event with nth_tick value")
    end
    local subs
    if not self.ready then
        subs = self.pre_subscribed_events
    else
        subs = storage.subscribed_events
    end
    local found = false
    local active = false
    if not self:listener_exists(name) then
        error("Could not find listener named: " .. name)
    end

    for _, sub in ipairs(subs) do
        if type == sub.type and nth_tick == sub.nth_tick then
            if sub.active_count > 0 then
                active = true
            end
            if name == sub.name then
                found = true
                sub.active_count = sub.active_count + 1
                if sub.active_count > max_subs then
                    error("wiretap " .. name .. " active: " .. sub.active_count .. " max: " .. max_subs)
                end
            end
        end
    end

    if not found then
        subs[#subs + 1] = { type = type, name = name, active_count = 1, nth_tick = nth_tick }
    end

    if not active and self.ready then
        if nth_tick ~= nil then
            self:attach_tick_listener(nth_tick)
        else
            self:attach_listener(type)
        end
    end
end

function wiretap:unsubscribe(type, name, nth_tick)
    if type == "nth_tick" and nth_tick == nil then
        error("Unsubscribing to nth_tick event with no nth_tick value")
    elseif type ~= "nth_tick" and nth_tick ~= nil then
        error("Unsubscribing to non-nth_tick event with nth_tick value")
    end
    local subs
    if not self.ready then
        subs = self.pre_subscribed_events
    else
        subs = storage.subscribed_events
    end
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
    if unsubscribed_all and self.ready then
        if nth_tick ~= nil then
            self:detach_tick_listener(nth_tick)
        else
            self:detach_listener(type)
        end
    end
end

return wiretap