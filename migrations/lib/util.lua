
local M = {}

function M.run_migration(version, migrate_function)
    if not remote.interfaces["bravest-new-world-debug"] then
        log("bravest-new-world not running, skipping migration for version: " .. version)
        return
    end
    local internal = remote.interfaces["bravest-new-world-internal"]
    if not internal or not internal["get-storage"] or not internal["set-storage"] then
        error({"startup-errors.upgrade-from-5-1-3"})
    end
    local storage = remote.call("bravest-new-world-internal", "get-storage")
    local scenario_version = storage.scenario_version or "5.1.3"
    storage.applied_migrations = storage.applied_migrations or {}
    if not storage.applied_migrations[version] and helpers.compare_versions(scenario_version, version) < 0 then
        local current_version = script.active_mods[script.mod_name]
        migrate_function(storage)
        storage.applied_migrations[version] = scenario_version .. "->" .. current_version
        remote.call("bravest-new-world-internal", "set-storage", storage)
    end
end

return M
