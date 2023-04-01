data:extend({
    {
        type = "recipe",
        name = "outpost-train-stop",
        enabled = false,
        ingredients =
        {
            { "train-stop",         1 },
            { "electronic-circuit", 2 }
        },
        result = "outpost-train-stop"
    },
    {
        type = "recipe",
        name = "me-train-stop",
        enabled = false,
        ingredients =
        {
            { "train-stop",         1 },
            { "electronic-circuit", 2 }
        },
        result = "me-train-stop"
    },
    {
        type = "recipe",
        name = "me-combinator",
        enabled = false,
        ingredients =
        {
            { "constant-combinator", 1 },
            { "electronic-circuit",  2 }
        },
        result = "me-combinator"
    },
    -- {
    --   type = "recipe",
    --   name = "bp-combinator",
    --   enabled = false,
    --   ingredients =
    --   {
    --     {"constant-combinator", 1},
    --   {"electronic-circuit", 2}
    --   },
    --   result = "bp-combinator"
    -- },
    {
        type = "recipe",
        name = "rp-combinator",
        enabled = false,
        ingredients =
        {
            { "constant-combinator", 1 },
            { "electronic-circuit",  2 }
        },
        result = "rp-combinator"
    },
})
