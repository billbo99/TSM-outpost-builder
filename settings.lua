data:extend({
    {
        type = "int-setting",
        name = "ghost-refresh",
        setting_type = "runtime-global",
        default_value = 30,
        minimum_value = 1,
        order = 1
    },
    {
        type = "int-setting",
        name = "max-crane-height",
        setting_type = "runtime-per-user",
        default_value = 700,
        minimum_value = 200,
        order = 2
    },
    {
        type = "int-setting",
        name = "max-view-height",
        setting_type = "runtime-per-user",
        default_value = 700,
        minimum_value = 200,
        order = 3
    },
    {
        type = "bool-setting",
        name = "msg-network-found",
        setting_type = "runtime-per-user",
        default_value = true,
        minimum_value = 0,
        order = 4
    },
    {
        type = "bool-setting",
        name = "msg-tsm-serviced",
        setting_type = "runtime-per-user",
        default_value = true,
        minimum_value = 0,
        order = 5
    },
    {
        type = "bool-setting",
        name = "msg-complete",
        setting_type = "runtime-per-user",
        default_value = true,
        minimum_value = 0,
        order = 6
    },
    {
        type = "bool-setting",
        name = "msg-signal-reset",
        setting_type = "runtime-per-user",
        default_value = true,
        minimum_value = 0,
        order = 7
    },
    {
        type = "bool-setting",
        name = "msg-me-stop",
        setting_type = "runtime-per-user",
        default_value = true,
        minimum_value = 0,
        order = 8
    },
    {
        type = "bool-setting",
        name = "msg-me-stopr",
        setting_type = "runtime-per-user",
        default_value = true,
        minimum_value = 0,
        order = 8
    },
})
