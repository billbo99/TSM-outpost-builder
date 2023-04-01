-- function push_order(unit_number)
--     game.print("In push order")
--     global.queue = global.queue or {}
--     global.next_order = global.next_order or 0
--     global.next_order = global.next_order + 1
--     global.queue[global.next_order] = unit_number
--     game.print(global.next_order .. " is next order")
--     game.print(global.queue[global.next_order])
--     while global.curr_order < global.next_order and isOrderActive(global.outpost_queue[global.queue[global.curr_order]]) == false do
--         global.curr_order = global.curr_order + 1
--     end
--  --   game.write_file("queue",serpent.block(global.queue),{comment=false})
-- end
function push_order(unit_number, entity)
    if entity == nil then
        game.print("nil value push" .. unit_number)
        return
    end
    local outpost_queue = {}
    local tick = 0
    if settings.global["ghost-refresh"].value > 0 then
        tick = game.tick + (3600 * settings.global["ghost-refresh"].value)
    else
        tick = 0
    end
    global.outpost_queue = global.outpost_queue or {}
    outpost_queue = { unit_number = unit_number, entity = entity, delivered = {}, sent = {}, tick = tick }
    table.insert(global.outpost_queue, outpost_queue)
    update_crane_guis()
end

local function destroy_obsolete_views(pos)
    for _, player in pairs(game.players) do
        local gui = mod_gui.get_frame_flow(player)
        if gui.view_frame then
            local frame = gui.view_frame
            if global.player[player.index].view == pos then
                frame.destroy()
                global.player[player.index].view = 0
            end
        end
    end
end

function pop_order(pos)
    global.outpost_stops[global.outpost_queue[pos].unit_number].complete = true
    table.remove(global.outpost_queue, pos)
    update_crane_guis()
    update_view_guis()
end

function complete_order()
    pop_order(1)
end

function isOrderActive(entity)
    -- Is there an active order on this outpost train stop
    local active = false
    if entity == nil then return active end
    if entity.valid == false then return active end
    local unit_number = entity.unit_number
    global.queue = global.queue or {}
    if global.outpost_queue[unit_number] == nil then return active end
    if global.queue[unit_number] ~= nil then
        active = true
        return active
    end
end

function get_or_set_curr_order()
    global.curr_order = global.curr_order or 0
    global.queue = global.queue or {}
    if global.curr_order == 0 then
        if table_size(global.queue) > 0 then
            global.curr_order = 1
            --   update_schedule()
            return
        end
        return
    end
    if global.queue[global.curr_order] ~= nil then return end
    complete_order()
end

function msg_tsm_serviced(backer_name)
    for _, player in pairs(game.players) do
        if player.mod_settings["msg-tsm-serviced"].value == true then
            player.print("TSM outpost being serviced - " .. backer_name)
        end
    end
end

function update_schedule(station)
    for i, stop in pairs(global.me_stops) do
        if stop.entity.valid == true then
            local train = stop.entity.get_stopped_train()
            if train ~= nil then
                local schedule = train.schedule
                -- if non me-station already exists then the destination is already set and exit
                for _, record in pairs(schedule.records) do
                    local non_mestop = true
                    log("TSM schedule for " .. record.station)
                    for _, mestop in pairs(global.me_stops) do
                        log("TSM ME stop " .. mestop.entity.backer_name)
                        if mestop.entity.backer_name == record.station then
                            non_mestop = false
                        end
                        log("TSM schedule result - exit : " .. tostring(non_mestop))
                    end
                    if non_mestop == true then return end
                    --                    game.print(record.station.backer_name .. " : " .. record.station.name)
                    --                    if record.station.name ~= "me-train-stop" then return end
                end

                local record = { station = station.backer_name, wait_conditions = {} }
                msg_tsm_serviced(station.backer_name)
                record.wait_conditions[1] = { type = "inactivity", compare_type = "or", ticks = 300 }
                local next = #schedule.records + 1
                if schedule.current >= next then
                    schedule.current = next - 1
                end
                if schedule.current < 1 then schedule.current = 1 end
                schedule.records[next] = record
                train.manual_mode = true
                train.schedule = schedule
                train.manual_mode = false
            else
                --    game.print("no stopped train")
            end
        end
    end
end
