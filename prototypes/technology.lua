data:extend({
    {
        type = "technology",
        name = "automated-outpost-builder",
        icon = "__TSM-outpost-builder__/graphics/technology/tech-crane.png",
        icon_size = 128,
        prerequisites = { "circuit-network", "automated-rail-transportation" },
        effects =
        {
            {
                type = "unlock-recipe",
                recipe = "outpost-train-stop"
            },
            {
                type = "unlock-recipe",
                recipe = "me-train-stop"
            },
            {
                type = "unlock-recipe",
                recipe = "me-combinator"
            },
            -- {
            --   type = "unlock-recipe",
            --   recipe = "bp-combinator"
            -- },
            {
                type = "unlock-recipe",
                recipe = "rp-combinator"
            },
        },
        unit =
        {
            count = 50,
            ingredients =
            {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
            },
            time = 20
        }
    }
})
