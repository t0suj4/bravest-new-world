local mig_utils = require("lib/util")


mig_utils.run_migration("5.2.1", function(storage)
    storage.control_room.map_gen_settings.autoplace_controls = nil
end)
