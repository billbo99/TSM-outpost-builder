data:extend({

    {
        type = "item",
        name = "outpost-train-stop",
        icon = "__TSM-outpost-builder__/graphics/icons/train-stop-out.png",
        icon_size = 32,
        --   flags = {"goes-to-quickbar"},
        subgroup = "transport",
        order = "a[train-system]-ca[train-stop]",
        place_result = "outpost-train-stop",
        stack_size = 10
    },
    {
        type = "item",
        name = "me-train-stop",
        icon = "__TSM-outpost-builder__/graphics/icons/train-stop-me.png",
        icon_size = 32,
        --   flags = {"goes-to-quickbar"},
        subgroup = "transport",
        order = "a[train-system]-ca[train-stop]",
        place_result = "me-train-stop",
        stack_size = 10
    },
    {
        type = "item",
        name = "me-combinator",
        icon = "__TSM-outpost-builder__/graphics/icons/constant-combinator-purple.png",
        icon_size = 64,
        --   flags = {"goes-to-quickbar"},
        subgroup = "transport",
        order = "a[train-system]-ca[train-stop]",
        place_result = "me-combinator",
        stack_size = 10
    },
    --   {
    --     type = "item",
    --     name = "bp-combinator",
    --     icon = "__base__/graphics/icons/constant-combinator.png",
    --     icon_size = 64,
    --  --   flags = {"goes-to-quickbar"},
    --     subgroup = "transport",
    --     order = "a[train-system]-ca[train-stop]",
    --     place_result = "bp-combinator",
    --     stack_size = 10
    --   },
    {
        type = "item",
        name = "rp-combinator",
        icon = "__TSM-outpost-builder__/graphics/icons/constant-combinator-cyan.png",
        icon_size = 64,
        --   flags = {"goes-to-quickbar"},
        subgroup = "transport",
        order = "a[train-system]-ca[train-stop]",
        place_result = "rp-combinator",
        stack_size = 10
    },
    {
        type = "shortcut",
        name = "TSM-OB-exclusion",
        action = "lua",
        toggleable = true,
        icon =
        {
            filename = "__TSM-outpost-builder__/graphics/icons/crane.png",
            priority = "extra-high-no-scale",
            size = 32,
            scale = 1,
            flags = { "icon" }
        }
    }

})
