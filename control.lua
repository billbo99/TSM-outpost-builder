require "util"
local mod_gui = require("mod-gui")
require("control_ghost")
require("control_queue")

MOD_NAME = "TSM-outpost-builder"

global.outpost_queue = global.outpost_queue or {}
global.player = global.player or {}
global.me_stops = global.me_stops or {}
global.me_combinators = global.me_combinators or {}

local function getUniqueName(entity)
    if #entity.surface.get_train_stops({ name = entity.backer_name }) > 1 then
        entity.surface.print("Same name as existing train stop")
        local length = string.len(entity.backer_name)
        local suffix = tonumber(string.sub(entity.backer_name, length - 1, length))
        if suffix ~= nil then
            local suflen = string.len(suffix)
            suffix = suffix + 1
            entity.backer_name = string.sub(entity.backer_name, 1, length - suflen) .. tostring(suffix)
        else
            suffix = "01"
            entity.backer_name = entity.backer_name .. tostring(suffix)
        end
        --	entity.backer_name = entity.backer_name .. "X"
        getUniqueName(entity)
    end
end

local function add_queue(station)
    if global.outpost_queue[station.unit_number] == nil then
        global.outpost_queue[station.unit_number] = { entity = station, sent = {}, delivered = {} }

        game.print(station.backer_name .. " added to queue")
        push_order(station.unit_number)
        if isOrderActive(global.outpost_queue[global.queue[global.curr_order]]) == false then
            --    global.curr_order = global.curr_order + 1
        end
        update_schedule(station)
    end
end

function read_green_circuits(station)
    -- station is an entity
    local demand = false
    if station.valid == true then
        local cb = station.get_or_create_control_behavior()
        local green = cb.get_circuit_network(defines.wire_type.green)
        if green == nil then return demand end
        --    if green.signals == nil then return demand end
        if global.outpost_stops[station.unit_number].complete ~= nil then
            if global.outpost_stops[station.unit_number].complete == true then
                return demand
            end
        end

        local inQueue = false
        local qpos = 0
        for i, queue in pairs(global.outpost_queue) do
            if queue.unit_number == station.unit_number then
                inQueue = true
                if green.signals == nil then
                    --    game.print("popping " .. i)
                    pop_order(i)
                    update_me_combo()
                    return
                end
                for j, signal in pairs(green.signals) do
                    if queue.sent[signal.signal.name] ~= nil then
                        if queue.sent[signal.signal.name] < signal.count then
                            demand = true
                            break
                        end
                    end
                end
                update_me_combo()
                break
            end
        end
        if inQueue == false and green.signals ~= nil then
            demand = true
            push_order(station.unit_number, station)
            game.print(station.backer_name .. " added to build queue")
            update_me_combo()
            update_schedule(station)
        end
        return demand
    end
    return demand
end

local function assign_demand(entity)
    local green = {}
    if global.outpost_queue ~= {} then
        --      get_or_set_curr_order()
        if global.queue ~= nil then
            if global.queue[global.curr_order] ~= nil then
                for pos, outpost in pairs(global.outpost_queue) do
                    --   local outpost = global.outpost_queue[global.queue[global.curr_order]]
                    if outpost ~= nil then
                        if outpost.entity.valid == true then
                            green = outpost.entity.get_circuit_network(defines.wire_type.green)
                            local cb = entity.get_or_create_control_behavior()
                            cb.parameters = nil
                            if green ~= nil then
                                if green.signals ~= nil then
                                    for i, signal in pairs(green.signals) do
                                        if signal.signal.type == "item" then
                                            if outpost.sent ~= {} then
                                                if outpost.sent[signal.signal.name] ~= nil then
                                                    signal.count = signal.count - outpost.sent[signal.signal.name]
                                                end
                                                if signal.count > 0 then
                                                    cb.set_signal(i, signal)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

local function check_new_demand()
    --   for _,station in pairs(game.get_train_stops()) do
    --   game.print("in check new demand")
    global.outpost_stops = global.outpost_stops or {}
    if global.outpost_stops ~= {} then
        for _, station in pairs(global.outpost_stops) do
            if station.entity.name == "outpost-train-stop" then
                local demand = read_green_circuits(station.entity)
                --    game.print("Demand " .. tostring(demand))
            end
        end
    end
    if global.me_combinators ~= nil then
        if global.me_combinators ~= {} then
            for key, me_combinator in pairs(global.me_combinators) do
                if global.me_combinators.entity ~= nil then
                    if global.me_combinators.entity.valid == true then
                        assign_demand(me_combinator.entity)
                    else
                        --    global.me_combinators[key] = nil
                    end
                else
                    --    global.me_combinators[key] = nil
                end
            end
        end
    end
end

local function read_red_circuits()
    -- global.queue = global.queue or {}
    -- global.curr_order = global.curr_order or 0
    -- get_or_set_curr_order()
    local first_station = ""
    if global.outpost_queue ~= {} then
        local cb, red
        for unit_number, outpost in pairs(global.outpost_queue) do
            if outpost.entity.valid == true then
                if first_station == "" then first_station = unit_number end
                cb = outpost.entity.get_or_create_control_behavior()
                red = cb.get_circuit_network(defines.wire_type.red)
                if red ~= nil then
                    if red.signals ~= nil then
                        for _, signal in pairs(red.signals) do
                            if signal.signal.type == "item" then
                                global.outpost_queue[unit_number].delivered[signal.signal.name] = global.outpost_queue[unit_number].delivered[signal.signal.name] or 0
                                global.outpost_queue[unit_number].delivered[signal.signal.name] = global.outpost_queue[unit_number].delivered[signal.signal.name] + signal.count
                            end
                        end
                        update_view_guis()
                    end
                end
            end
        end
    end
    if global.me_stops ~= {} then
        local cb, red
        if first_station ~= "" then
            for unit_number, me_stop in pairs(global.me_stops) do
                if me_stop.entity.valid == true then
                    cb = me_stop.entity.get_or_create_control_behavior()
                    red = cb.get_circuit_network(defines.wire_type.red)
                    if red ~= nil then
                        if red.signals ~= nil then
                            for _, signal in pairs(red.signals) do
                                if signal.signal.type == "item" then
                                    -- if global.outpost_queue[first_station] == nil then

                                    --     global.outpost_queue[first_station] = {entity=station,sent={},delivered={}}
                                    -- end
                                    if global.outpost_queue[first_station].sent == nil then
                                        global.outpost_queue[first_station].sent = {}
                                    end
                                    global.outpost_queue[first_station].sent[signal.signal.name] = global.outpost_queue[first_station].sent[signal.signal.name] or 0
                                    global.outpost_queue[first_station].sent[signal.signal.name] = global.outpost_queue[first_station].sent[signal.signal.name] + signal.count
                                end
                            end
                            update_view_guis()
                            update_me_combo()
                        end
                    end
                end
            end
        end
    end
end

local function check_ghost_refresh()
    global.outpost_stops = global.outpost_stops or {}
    local demand = false
    if global.outpost_stops ~= {} then
        for i, outpost in pairs(global.outpost_stops) do
            outpost.tick = outpost.tick or 0
            if outpost.tick < game.tick and outpost.tick ~= 0 then
                local green_ents = get_connected_entities(outpost.entity.backer_name, outpost.entity.circuit_connected_entities.green)
                outpost.complete = false
                local unit_number = outpost.entity.unit_number
                local existing = false
                for _, opost in pairs(global.outpost_queue) do
                    if opost.entity.unit_number == i then
                        opost.sent = {}
                        opost.delivered = {}
                        existing = true
                        break
                    end
                end

                if settings.global["ghost-refresh"].value > 0 then
                    outpost.tick = game.tick + (3600 * settings.global["ghost-refresh"].value)
                    update_crane_guis()
                else
                    outpost.tick = 0
                end
                global.outpost_stops[unit_number] = outpost
                break
            end
        end
    end
end

function update_me_combo()
    --
    if table_size(global.me_combinators) == 0 then return end
    if table_size(global.outpost_queue) == 0 then
        for _, combo in pairs(global.me_combinators) do
            local ccb = combo.entity.get_or_create_control_behavior()
            ccb.parameters = nil
        end
        return
    end
    local cb = global.outpost_queue[1].entity.get_or_create_control_behavior()
    local green = cb.get_circuit_network(defines.wire_type.green)
    if green == nil then return end
    if green.signals == nil then return end
    for _, combo in pairs(global.me_combinators) do
        local ccb = combo.entity.get_or_create_control_behavior()
        ccb.parameters = nil

        local red = ccb.get_circuit_network(defines.wire_type.red)
        local red_signals = {}
        if red and red.signals and #red.signals > 0 then
            for index, signal in pairs(red.signals) do
                red_signals[signal.signal.name] = signal.count
            end
        end

        for idx = 1, ccb.signals_count do
            ccb.set_signal(idx, nil)
        end

        local index = 1
        for _, signal in pairs(green.signals) do
            if global.outpost_queue[1].sent[signal.signal.name] ~= nil then
                if global.outpost_queue[1].sent[signal.signal.name] > 0 then
                    signal.count = signal.count - global.outpost_queue[1].sent[signal.signal.name]
                    if signal.count < 0 then signal.count = 0 end
                end
            end
            if red_signals[signal.signal.name] and signal.count > 0 then
                ccb.set_signal(index, signal)
                index = index + 1
            end
        end
    end
end

local function exclusions_shortcut(event)
    local prototype = event.prototype_name
    if prototype ~= "TSM-OB-exclusion" then return end
    local gui = game.players[event.player_index].gui.screen
    local frame = gui.exclusion_frame
    if frame then
        frame.destroy()
        return
    end
    frame = gui.add {
        type = "frame",
        name = "exclusion_frame",
        direction = "vertical",
        caption = { "exclusion-title" }
        --       style = mod_gui.frame_style
    }
    frame.location = { 200, 200 }
    local flow = frame.add { type = "flow", name = "flow", direction = "vertical" }
    --   flow.add{type = "label", caption = {"exclusion-title"}}
    --   flow.drag_target = frame
    local scroll = flow.add { type = "scroll-pane", name = "exscroll" }
    exclusions_detail(game.players[event.player_index])
end

function exclusions_detail(player)
    local scroll = player.gui.screen.exclusion_frame.flow.exscroll
    local exclusions = scroll.add { type = "table", name = "exclusions", column_count = 3, style = "PubSub_table_style" }
    global.exclusions = global.exclusions or {}
    if global.exclusions ~= {} then
        for i, exclusion in pairs(global.exclusions) do
            local remove = exclusions.add { type = "button", name = "ex_remove" .. i, style = "PubSub_edit_button_style", caption = "-" }
            local item = exclusions.add { type = "choose-elem-button", name = "item" .. i, elem_type = "signal", signal = { type = exclusion.type, name = exclusion.name } }
            item.locked = true
            exclusions.add { type = "label", caption = exclusion.name }
        end
    end
    exclusions.add { type = "label", caption = ' ' }
    exclusions.add { type = "choose-elem-button", name = "new_exclusion", elem_type = "signal" }
end

local function on_gui_elem_changed(event)
    local mod = event.element.get_mod()
    if mod == nil then return end
    if mod ~= "TSM-outpost-builder" then return end
    if event.element.elem_value == nil then return end
    table.insert(global.exclusions, { type = event.element.elem_value.type, name = event.element.elem_value.name })
    game.players[event.player_index].gui.screen.exclusion_frame.flow.exscroll.exclusions.destroy()
    exclusions_detail(game.players[event.player_index])
end

script.on_nth_tick(10, pop_all_green)

script.on_nth_tick(120, check_new_demand)

script.on_nth_tick(301, check_ghost_refresh)

script.on_event(defines.events.on_tick, read_red_circuits)

script.on_event(defines.events.on_lua_shortcut, exclusions_shortcut)

script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed)

get_sprite_button = function(player)
    -- debugp("in get_sprite_button")
    local button_flow = mod_gui.get_button_flow(player)
    local button = button_flow.crane_sprite_button
    if button then
        if player.force.technologies["automated-outpost-builder"].researched ~= true then
            button.destroy()
        end
        return
    end
    if not button then
        button = button_flow.add
            {
                type = "sprite-button",
                name = "crane_sprite_button",
                sprite = "crane",
                style = mod_gui.button_style,
                --      tooltip = {"gui-trainps.button-tooltip"}
            }
        --   button.style.visible = any
        -- if player.mod_settings["ps-tooltip"].value == true then
        -- 	button.tooltip = {"gui-trainps.button-tooltip"}
        -- end
    end
    return button
end

script.on_event(defines.events.on_research_finished, function(event)
    if event.research.name == 'automated-outpost-builder' then
        for _, player in pairs(game.players) do
            get_sprite_button(player)
        end
    end
end)

local function on_player_created(event)
    if game.players[event.player_index].force.technologies["automated-outpost-builder"].researched == true then
        get_sprite_button(game.players[event.player_index])
    end
end

local function on_player_joined_game(event)
    if game.players[event.player_index].force.technologies["automated-outpost-builder"].researched == true then
        get_sprite_button(game.players[event.player_index])
    end
end

local function onLoad()
    global.outpost_queue = global.outpost_queue or {}
    global.player = global.player or {}
    global.me_stops = global.me_stops or {}
    global.me_combinators = global.me_combinators or {}
end

local function update_crane_gui(player)
    local gui, frame, outposts, cranes

    gui = mod_gui.get_frame_flow(player)
    if gui.crane_button_frame then
        frame = gui.crane_button_frame
    else
        return
    end
    if frame.scroll then
        local scroll = frame.scroll
        if scroll.cranes then
            scroll.cranes.clear()
            cranes = scroll.cranes
        else
            cranes = scroll.add { type = "table", name = "cranes", column_count = 4, style = "PubSub_table_style" }
        end
        if global.outpost_queue ~= {} then
            for key, queue in pairs(global.outpost_queue) do
                local ping = cranes.add { type = "button", name = "ob_ping" .. ":" .. key, style = "PubSub_edit_button_style", caption = "p" }
                ping.tooltip = { "tooltip.ping" }
                local refresh = cranes.add { type = "button", name = "ob_refresh" .. ":" .. key, style = "PubSub_edit_button_style", caption = "r" }
                refresh.tooltip = { "tooltip.refresh" }
                local view = cranes.add { type = "button", name = "ob_view" .. ":" .. key, style = "PubSub_edit_button_style", caption = "v" }
                view.tooltip = { "tooltip.view" }
                cranes.add { type = "label", caption = queue.entity.backer_name, style = "caption_label" }
            end
        else
            scroll.add { type = "label", caption = { "nil" } }
        end
        if global.outpost_stops ~= {} then
            if not (scroll.stop_title) then
                scroll.add { type = "label", name = "stop_title", caption = { "stops-title" } }
            end
            if scroll.outposts then
                scroll.outposts.clear()
                outposts = scroll.outposts
            else
                outposts = scroll.add { type = "table", name = "outposts", column_count = 4, style = "PubSub_table_style" }
            end
            for key, stop in pairs(global.outpost_stops) do
                local ping = outposts.add { type = "button", name = "out_ping" .. ":" .. key, style = "PubSub_edit_button_style", caption = "p" }
                ping.tooltip = { "tooltip.ping" }
                local refresh = outposts.add { type = "button", name = "out_refresh" .. ":" .. key, style = "PubSub_edit_button_style", caption = "r" }
                refresh.tooltip = { "tooltip.refresh" }
                outposts.add { type = "label", caption = stop.entity.backer_name, style = "caption_label" }
                outposts.add { type = "label", caption = tostring(math.floor((stop.tick - game.tick) / 3600)) .. "mins", style = "caption_label" }
            end
        end
    end
end

function update_crane_guis()
    for _, player in pairs(game.players) do
        update_crane_gui(player)
    end
end

local function gui_open_cranetable(player)
    local gui = mod_gui.get_frame_flow(player)
    local frame = gui.crane_button_frame
    if not frame then return end
    frame.clear()
    frame.add { type = "label", caption = { "crane-title" } }
    local scroll = frame.add { type = "scroll-pane", name = "scroll" }
    scroll.style.maximal_height = player.mod_settings["max-crane-height"].value
    update_crane_gui(player)
end

local function update_view_gui(player)
    local gui, frame, view_table
    gui = mod_gui.get_frame_flow(player)
    if gui.view_frame then
        frame = gui.view_frame
    else
        return
    end
    local unit_number = tonumber(global.player[player.index].view)
    if frame.scroll == nil then
        local scroll = frame.add { type = "scroll-pane", name = "scroll" }
        scroll.style.maximal_height = player.mod_settings["max-view-height"].value
        scroll.add { type = "label", caption = global.outpost_queue[unit_number].entity.backer_name }
    end
    if frame.scroll.view_table then
        frame.scroll.view_table.destroy()
    end
    view_table = frame.scroll.add { type = "table", name = "view_table", column_count = 3 }
    local station = global.outpost_queue[unit_number].entity
    local amount = 0
    view_table.add { type = "label", caption = { "backorder-title" }, style = "caption_label" }
    view_table.add { type = "label", caption = "|", style = "caption_label" }
    view_table.add { type = "label", caption = { "awaiting-delivery-title" }, style = "caption_label" }
    if station.valid == true then
        local cb = station.get_or_create_control_behavior()
        local green = cb.get_circuit_network(defines.wire_type.green)
        if green == nil then return end
        if green.signals == nil then return end
        for _, signal in pairs(green.signals) do
            if signal.signal.type == "item" then
                amount = signal.count
                if global.outpost_queue[unit_number].sent ~= {} then
                    if global.outpost_queue[unit_number].sent[signal.signal.name] ~= nil then
                        amount = amount - global.outpost_queue[unit_number].sent[signal.signal.name]
                    end
                end
                if amount < 0 then amount = 0 end
                view_table.add { type = "label", caption = "[item=" .. signal.signal.name .. "]" .. amount }
                view_table.add { type = "label", caption = "|", style = "caption_label" }
                amount = signal.count
                if global.outpost_queue[unit_number].delivered ~= {} then
                    if global.outpost_queue[unit_number].delivered[signal.signal.name] ~= nil then
                        amount = amount - global.outpost_queue[unit_number].delivered[signal.signal.name]
                    end
                end
                if amount < 0 then amount = 0 end
                view_table.add { type = "label", caption = "[item=" .. signal.signal.name .. "]" .. amount }
            end
        end
    end
end

function update_view_guis()
    for _, player in pairs(game.players) do
        update_view_gui(player)
    end
end

function gui_open_view_frame(player)
    local gui = mod_gui.get_frame_flow(player)
    local frame = gui.view_frame
    if not frame then return end
    frame.clear()
    if table_size(global.outpost_queue) == 0 then
        frame.destroy()
        return
    end
    local heading = { "view-title" }
    local unit_number = tonumber(global.player[player.index].view)
    frame.add { type = "label", caption = heading }
    local scroll = frame.add { type = "scroll-pane", name = "scroll" }
    scroll.style.maximal_height = player.mod_settings["max-view-height"].value
    if global.outpost_queue[unit_number] ~= nil then
        scroll.add { type = "label", caption = global.outpost_queue[unit_number].entity.backer_name }
        update_view_gui(player)
    end
end

function update_view_guis()
    for _, player in pairs(game.players) do
        gui_open_view_frame(player)
    end
end

function get_connected_entities(backer_name, green_ents, excl)
    excl = excl or {}
    local skip = false
    for _, ent in pairs(green_ents) do
        if excl ~= {} then
            for _, exc in pairs(excl) do
                if ent == exc then
                    skip = true
                    break
                else
                    skip = false
                end
            end
        end
        if skip == false then
            table.insert(excl, ent)
            if ent.name == "rp-combinator" then
                refresh_ghost_count(ent, backer_name)
            end
            get_connected_entities(backer_name, ent.circuit_connected_entities.green, excl)
        end
    end
end

local function msg_complete(station)
    for _, player in pairs(game.players) do
        if player.mod_settings["msg-complete"].value == true then
            player.print("Outpost build job for " .. station .. " complete")
        end
    end
end

function push_green(entity)
    global.green = global.green or {}
    table.insert(global.green, entity)
end

function pop_all_green()
    global.green = global.green or {}
    if table_size(global.green) == 0 then return end
    for i, station in pairs(global.green) do
        if entity.valid == true then
            read_green_circuits(station)
            table.remove(global.green, i)
            i = i - 1
        end
    end
end

local function map_ping(player, x, y, surface)
    player.force.print("[gps=" .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(surface.name) .. "]")
end

local function on_gui_click(event)
    local element = event.element
    local player = game.players[event.player_index]
    local gui = mod_gui.get_frame_flow(player)

    if element.name == "crane_sprite_button" then
        local frame = gui.crane_button_frame
        if frame then
            frame.destroy()
            frame = gui.view_frame
            if frame then frame.destroy() end
            return
        end
        gui.add {
            type = "frame",
            name = "crane_button_frame",
            direction = "vertical",
            style = mod_gui.frame_style
        }
        gui_open_cranetable(player)
    elseif string.find(element.name, "ob_view") then
        local view_frame = gui.view_frame
        if view_frame then
            view_frame.destroy()
            return
        end
        gui.add {
            type = "frame",
            name = "view_frame",
            direction = "vertical",
            style = mod_gui.frame_style
        }

        global.player = global.player or {}
        global.player[event.player_index] = global.player[event.player_index] or {}
        global.player[event.player_index].view = string.sub(element.name, 9)
        gui_open_view_frame(player)
    elseif string.find(element.name, "ob_refresh") then
        local unit_number = tonumber(string.sub(element.name, 12))
        -- find connected ghost readers
        if global.outpost_queue[unit_number] == nil then return end
        local green_ents = global.outpost_queue[unit_number].entity.circuit_connected_entities.green
        global.outpost_stops[global.outpost_queue[unit_number].entity.unit_number].complete = false
        get_connected_entities(global.outpost_queue[unit_number].entity.backer_name, green_ents)
        push_green(global.outpost_queue[unit_number].entity)
        global.outpost_queue[unit_number].sent = {}
        global.outpost_queue[unit_number].delivered = {}
        if settings.global["ghost-refresh"].value > 0 then
            global.outpost_queue[unit_number].tick = game.tick + (3600 * settings.global["ghost-refresh"].value)
        else
            global.outpost_queue[unit_number].tick = 0
        end
        update_crane_guis()
        update_view_guis()
    elseif string.find(element.name, "ob_ping") then
        local unit_number = tonumber(string.sub(element.name, 9))
        -- find connected ghost readers
        if global.outpost_queue[unit_number] == nil then return end
        local entity = global.outpost_queue[unit_number].entity
        map_ping(player, entity.position.x, entity.position.y, entity.surface)
    elseif string.find(element.name, "out_refresh") then
        local unit_number = tonumber(string.sub(element.name, 13))
        -- find connected ghost readers
        local green_ents = global.outpost_stops[unit_number].entity.circuit_connected_entities.green
        global.outpost_stops[unit_number].complete = false
        get_connected_entities(global.outpost_stops[unit_number].entity.backer_name, green_ents)
        push_green(global.outpost_stops[unit_number].entity)
        if settings.global["ghost-refresh"].value > 0 then
            global.outpost_stops[unit_number].tick = game.tick + (3600 * settings.global["ghost-refresh"].value)
        else
            global.outpost_stops[unit_number].tick = 0
        end
        for i, queue in pairs(global.outpost_queue) do
            if queue.entity == global.outpost_stops[unit_number].entity then
                global.outpost_queue[i].sent = {}
                global.outpost_queue[i].delivered = {}
                break
            end
        end
        update_crane_guis()
        update_view_guis()
    elseif string.find(element.name, "out_ping") then
        local unit_number = tonumber(string.sub(element.name, 10))
        local entity = global.outpost_stops[unit_number].entity
        map_ping(player, entity.position.x, entity.position.y, entity.surface)
    elseif string.find(element.name, "ex_remove") then
        local item = tonumber(string.sub(element.name, 10))
        table.remove(global.exclusions, item)
        for i, player in pairs(game.players) do
            if player.gui.screen.exclusion_frame.flow.exscroll.exclusions then
                player.gui.screen.exclusion_frame.flow.exscroll.exclusions.destroy()
                exclusions_detail(player)
            end
        end
    end
end

local filters = { { filter = "name", name = "me-train-stop" }, { filter = "name", name = "me-combinator" },
    { filter = "name", name = "bp-combinator" }, { filter = "name", name = "rp-combinator" },
    { filter = "name", name = "outpost-train-stop" } }

local function isOB(entity)
    if (entity.name == "me-train-stop") or
        (entity.name == "me-combinator") or
        (entity.name == "bp-combinator") or
        (entity.name == "rp-combinator") or
        (entity.name == "outpost-train-stop") then
        return true
    end
    return false
end

script.on_event(defines.events.on_built_entity, function(event)
    --	if isOB(event.created_entity) then
    addOBToTable(event.created_entity, event.player_index)
    --	end
end, filters)

script.on_event(defines.events.on_robot_built_entity, function(event)
    --	if isOB(event.created_entity) then
    addOBToTable(event.created_entity, 0, event.robot)
    --	end
end, filters)

script.on_event(defines.events.script_raised_built, function(event)
    --	if isOB(event.entity) then
    addOBToTable(event.entity, 0, event.robot)
    --	end
end, filters)

script.on_event(defines.events.script_raised_revive, function(event)
    --	if isOB(event.entity) then
    addOBToTable(event.entity, 0, event.robot)
    --	end
end, filters)

script.on_event(defines.events.on_entity_cloned, function(event)
    if isOB(event.entity) then
        addOBToTable(event.destination, 0, event.robot)
    end
end, filters)

local function on_preplayer_mined_item(event)
    if isOB(event.entity) then
        removeOBFromTable(event.entity)
    end
end

script.on_event(defines.events.on_robot_pre_mined, function(event)
    if isOB(event.entity) then
        removeOBFromTable(event.entity)
    end
end, filters)

script.on_event(defines.events.on_entity_died, function(event)
    if isOB(event.entity) then
        removeOBFromTable(event.entity)
    end
end, filters)

script.on_event(defines.events.script_raised_destroy, function(event)
    if isOB(event.entity) then
        removeOBFromTable(event.entity)
    end
end, filters)

function check_current_build()
    if global.outpost_queue[1] == nil then return "nothing" end
    local green = global.outpost_queue[1].entity.get_circuit_network(defines.wire_type.green)
    local result = "complete"
    if green == nil then
        result = "no signal"
        return result
    end
    if green.signals == nil then
        result = "no signal"
        return result
    end
    for _, signal in pairs(green.signals) do
        if global.outpost_queue[1].sent[signal.signal.name] ~= nil then
            if global.outpost_queue[1].sent[signal.signal.name] < signal.count then
                result = "outstanding"
                break
            end
        elseif signal.count > 0 then
            result = "outstanding"
            break
        end
        if global.outpost_queue[1].delivered[signal.signal.name] ~= nil then
            if global.outpost_queue[1].delivered[signal.signal.name] < signal.count then
                result = "outstanding"
                break
            end
        elseif signal.count > 0 then
            result = "outstanding"
            break
        end
    end
    return result
end

local function msg_signal_reset(station)
    for _, player in pairs(game.players) do
        if player.mod_settings["msg-signal-reset"].value == true then
            player.print("Outpost build signal reset for " .. station)
        end
    end
end

local function on_train_changed_state(event)
    local train = event.train
    local station = train.station
    local cur_station = ""
    local unit_number = 0
    if train.state == defines.train_state.wait_station and
        station ~= nil then
        if station.name == "me-train-stop" then
            -- Set schedule
            local schedule = train.schedule
            if schedule ~= nil then
                if train.schedule and global.outpost_queue ~= {} then
                    local ok = false
                    for i, record in pairs(schedule.records) do
                        for j, me_stop in pairs(global.me_stops) do
                            if me_stop.entity.valid == true then
                                if me_stop.entity.backer_name == record.station then
                                    ok = true
                                    break
                                end
                            else
                                global.me_stops[j] = nil
                            end
                        end
                        if ok == false then
                            table.remove(schedule.records, i)
                        end
                        ok = false
                    end

                    if global.outpost_queue[1] ~= nil then
                        local cur_station = global.outpost_queue[1].entity.backer_name
                        local record = { station = cur_station, wait_conditions = {} }
                        --game.print("TSM outpost being serviced - " .. cur_station)
                        msg_tsm_serviced(cur_station)
                        record.wait_conditions[1] = { type = "inactivity", compare_type = "or", ticks = 300 }
                        local next = #schedule.records + 1
                        if schedule.current >= next then
                            schedule.current = next - 1
                        end
                        if schedule.current < 1 then schedule.current = 1 end
                        schedule.records[next] = record
                    end
                    train.manual_mode = true
                    train.schedule = schedule
                    train.manual_mode = false
                end
            end
        end
    elseif event.old_state == defines.train_state.wait_station then
        local last = 0
        if train.schedule ~= nil then
            if train.schedule.current == 1 then
                last = #train.schedule.records
            else
                last = train.schedule.current - 1
            end
            if global.outpost_queue[1] ~= nil then
                if global.outpost_queue[1].entity.valid == true then
                    local cur_station = global.outpost_queue[1].entity.backer_name
                    if train.schedule.records[last].station == cur_station then
                        local check = check_current_build()
                        if check == "complete" then
                            msg_complete(cur_station)
                            complete_order()
                        elseif check == "no signal" then
                            for i, outpost in pairs(global.outpost_queue) do
                                msg_signal_reset(cur_station)
                                if outpost.entity.backer_name == cur_station then
                                    pop_order(i)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function msg_me_stop(station)
    for _, player in pairs(game.players) do
        if player.mod_settings["msg-signal-reset"].value == true then
            player.print("ME station " .. station .. " added")
        end
    end
end

function addOBToTable(entity, player_index, robot)
    if entity.name == "me-train-stop" then
        local status, err = pcall(function()
            getUniqueName(entity)
            global.me_stops = global.me_stops or {}
            global.me_stops[entity.unit_number] = global.me_stops[entity.unit_number] or {}
            global.me_stops[entity.unit_number].entity = entity
            msg_me_stop(entity.backer_name)
        end)
        if not status then
            game.print(err)
        end
    elseif entity.name == "me-combinator" then
        global.me_combinators = global.me_combinators or {}
        global.me_combinators[entity.unit_number] = global.me_combinators[entity.unit_number] or {}
        global.me_combinators[entity.unit_number].entity = entity
        update_me_combo()
        --    game.print("combinators :" .. #global.me_combinators)
    elseif entity.name == "rp-combinator" then
        global.rp_combinators = global.ep_combinators or {}
        global.rp_combinators[entity.unit_number] = global.rp_combinators[entity.unit_number] or {}
        global.rp_combinators[entity.unit_number].entity = entity
        refresh_ghost_count(entity)
    elseif entity.name == "outpost-train-stop" then
        global.outpost_stops = global.outpost_stops or {}
        getUniqueName(entity)
        global.outpost_stops[entity.unit_number] = global.outpost_stops[entity.unit_number] or {}
        global.outpost_stops[entity.unit_number].entity = entity
        global.outpost_stops[entity.unit_number].tick = game.tick + (3600 * settings.global["ghost-refresh"].value)
    end
end

local function msg_me_stopr(station)
    for _, player in pairs(game.players) do
        if player.mod_settings["msg-signal-reset"].value == true then
            player.print("ME station " .. station .. " removed")
        end
    end
end

function removeOBFromTable(entity)
    if entity.name == "me-train-stop" then
        global.me_stops[entity.unit_number] = nil
        game.print(entity.backer_name .. " removed")
    elseif entity.name == "me-combinator" then
        global.me_combinators[entity.unit_number] = nil
    elseif entity.name == "rp-combinator" then
        global.rp_combinators[entity.unit_number] = nil
    elseif entity.name == "outpost-train-stop" then
        if table_size(global.outpost_queue) > 0 then
            for i, queue in pairs(global.outpost_queue) do
                if queue.entity == entity then
                    pop_order(i)
                    break
                end
            end
        end
        global.outpost_stops[entity.unit_number] = nil
        update_crane_guis()
    end
end

-- script.on_configuration_changed(on_configuration_changed)
script.on_init(onLoad)
script.on_event(defines.events.on_pre_player_mined_item, on_preplayer_mined_item)
script.on_event(defines.events.on_train_changed_state, on_train_changed_state)
-- script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_gui_click, on_gui_click)
-- script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed)
-- script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)
script.on_load(on_load)
-- script.on_event(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)
-- script.on_event(defines.events.on_train_schedule_changed, on_train_schedule_changed)
-- script.on_event(defines.events.on_pre_entity_settings_pasted, on_pre_entity_settings_pasted)
-- --script.on_event(defines.events.on_tick, on_tick)

commands.add_command("Get_outpostlogs", { "get pslogs help" }, function(event)
    game.write_file("queue", serpent.block(global.queue), { comment = false })
    game.write_file("outposts", serpent.block(global.outpost_queue), { comment = false })
    game.write_file("outpost_stops", serpent.block(global.outpost_stops), { comment = false })
    game.write_file("me_stops", serpent.block(global.me_stops), { comment = false })
    game.write_file("rp_comb", serpent.block(global.rp_combinators), { comment = false })
    game.write_file("me_comb", serpent.block(global.me_combinators), { comment = false })
end)

commands.add_command("reset_currorder", { "get pslogs help" }, function(event)
    global.curr_order = 1
    game.print(global.curr_order)
end)

commands.add_command("curr_to_next", { "get pslogs help" }, function(event)
    global.curr_order = global.next_order
    game.print(global.curr_order)
end)

commands.add_command("showqptr", { "get pslogs help" }, function(event)
    game.print("curr " .. global.curr_order)
    game.print("next " .. global.next_order)
    game.print(table_size(global.outpost_queue))
end)

commands.add_command("tsm_ob_reset", { "get pslogs help" }, function(event)
    global.outpost_queue = nil
    global.outpost_queue = {}
end)
