local function msg_network_found(backer_name, cells)
    for _, player in pairs(game.players) do
        if player.mod_settings["msg-network-found"].value == true then
            player.print(backer_name .. " network found :" .. cells .. " cells")
        end
    end
end

local function check_exclusions(item)
    local outcome = false
    if global.exclusions ~= nil then
        for i, exclusion in pairs(global.exclusions) do
            if item == exclusion.name then
                outcome = true
                break
            end
        end
    end
    return outcome
end

function refresh_ghost_count(entity, backer_name)
    local curcell = entity.surface.find_logistic_network_by_position(entity.position, entity.force)
    -- game.print(#curcell.cells)
    if curcell ~= nil then
        if backer_name == nil then backer_name = "not connected" end
        --   game.print(backer_name .. " network found :" .. #curcell.cells .. " cells")
        msg_network_found(backer_name, #curcell.cells)
        local entities = {}
        local items = {}
        local item_count = {}
        local modules = {}
        local place_item = nil
        local item_requests = {}
        for i, cell in pairs(curcell.cells) do
            -- find all ghosts in construction range
            local x1 = cell.owner.position.x - cell.construction_radius + 1
            local y1 = cell.owner.position.y - cell.construction_radius + 1
            local x2 = cell.owner.position.x + cell.construction_radius - 1
            local y2 = cell.owner.position.y + cell.construction_radius - 1
            --    entities = entity.surface.find_entities_filtered{position = cell.owner.position, radius = cell.construction_radius, name = "entity-ghost", type = "entity-ghost"}
            entities = entity.surface.find_entities_filtered { area = { { x1, y1 }, { x2, y2 } }, name = "entity-ghost", type = "entity-ghost" }
            if entities ~= nil then
                --     game.write_file("ghost",serpent.block(entities),{comment=false})
                for j, found_entity in pairs(entities) do
                    --    game.players[1].teleport(found_entity.position)
                    place_item = found_entity.ghost_prototype.items_to_place_this[1].name
                    place_count = found_entity.ghost_prototype.items_to_place_this[1].count
                    --    if place_iten ~= "train-counter" then
                    items[place_item] = items[place_item] or {}
                    if items[place_item][found_entity.unit_number] == nil then
                        modules = found_entity.item_requests
                        if modules ~= nil then
                            for module, k in pairs(modules) do
                                item_count[module] = item_count[module] or 0
                                item_count[module] = item_count[module] + k
                            end
                        end
                    end
                    items[place_item][found_entity.unit_number] = place_count
                    --    end
                end
            end
            -- find all upgrades in construction range
            --    entities = entity.surface.find_entities_filtered{position = cell.owner.position, radius = cell.construction_radius, to_be_upgraded = true}
            entities = entity.surface.find_entities_filtered { area = { { x1, y1 }, { x2, y2 } }, to_be_upgraded = true }
            local upgrade
            if entities ~= nil then
                --    game.write_file("upgrade",serpent.block(entities),{comment=false})
                for j, found_entity in pairs(entities) do
                    upgrade = found_entity.get_upgrade_target()
                    if upgrade ~= nil then
                        items[upgrade.name] = items[upgrade.name] or {}
                        items[upgrade.name][found_entity.unit_number] = 1
                    end
                end
            end
            --    entities = entity.surface.find_entities_filtered{position = cell.owner.position, radius = cell.construction_radius, name = "tile-ghost", type = "tile-ghost"}
            entities = entity.surface.find_entities_filtered { area = { { x1, y1 }, { x2, y2 } }, name = "tile-ghost", type = "tile-ghost" }
            if entities ~= nil then
                --   game.write_file("tile",serpent.block(entities),{comment=false})
                local source_item
                for j, found_entity in pairs(entities) do
                    source_item = found_entity.ghost_prototype.items_to_place_this[1].name
                    items[source_item] = items[source_item] or {}
                    items[source_item][found_entity.unit_number] = found_entity.ghost_prototype.items_to_place_this[1].count
                end
            end

            --    entities = entity.surface.find_entities_filtered{position = cell.owner.position, radius = cell.construction_radius, name = "item-request-proxy"}
            entities = entity.surface.find_entities_filtered { area = { { x1, y1 }, { x2, y2 } }, name = "item-request-proxy" }
            if entities ~= nil then
                --    game.write_file("proxy",serpent.block(entities),{comment=false})
                for j, found_entity in pairs(entities) do
                    if item_requests[found_entity.unit_number] == nil then
                        item_requests[found_entity.unit_number] = 1
                        modules = found_entity.item_requests
                        if modules ~= nil then
                            for module, k in pairs(modules) do
                                item_count[module] = item_count[module] or 0
                                item_count[module] = item_count[module] + k
                            end
                        end
                    end
                end
            end
        end
        if items == {} then return false end
        for item, idx in pairs(items) do
            for k, x in pairs(idx) do
                if item_count[item] == nil then
                    item_count[item] = x
                else
                    item_count[item] = item_count[item] + x
                end
            end
        end
        local cb = entity.get_or_create_control_behavior()
        cb.parameters = nil
        local index = 1
        local signal = {}
        --   game.write_file("items",serpent.block(items),{comment=false})
        for item, count in pairs(item_count) do
            local status, err = pcall(function()
                --    game.print(item)
                if item ~= "train-counter" then
                    if check_exclusions(item) == false then
                        signal = { signal = { type = "item", name = item }, count = count }
                        cb.set_signal(index, signal)
                        index = index + 1
                    end
                end
            end)
            if not status then
                game.print(err)
            end
        end
    else
        game.print("No cell here")
        local cb = entity.get_or_create_control_behavior()
        cb.parameters = nil
    end
    return true
end
