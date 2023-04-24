Pathfinding = {}

--[[
    TODO:
    Write custom hashing function for x and y points to store in cameFrom,
    Correctly insert into frontier sorted by priority
]]
function Pathfinding.heuristic(x1, y1, x2, y2)
    return math.abs(x1 - x2) + math.abs(y1 - y2)
end

function Pathfinding.hashPoint(x, y)
    return x + (y - 1) * Map.WIDTH
end

function Pathfinding.unhashPoint(i)
    i = i - 1
    local x = i % Map.WIDTH + 1
    local y = math.floor(i / Map.WIDTH) + 1
    return x, y
end

function Pathfinding.getNeighbors(map, x, y, neighbors)
    for i = 1, 4 do
        neighbors[i] = nil
    end

    if map:getTile(x + 1, y) == 0 then
        table.insert(neighbors, { x = x + 1, y = y })
    end

    if map:getTile(x - 1, y) == 0 then
        table.insert(neighbors, { x = x - 1, y = y })
    end

    if map:getTile(x, y + 1) == 0 then
        table.insert(neighbors, { x = x, y = y + 1 })
    end

    if map:getTile(x, y - 1) == 0 then
        table.insert(neighbors, { x = x, y = y - 1 })
    end

    print(#neighbors)
end

function Pathfinding.aStarSearch(map, startX, startY, goalX, goalY)
    local cameFrom = {}

    local neighbors = {}
    local frontier = {}
    table.insert(frontier, {
        priority = 0,
        x = startX,
        y = startY,
    })

    cameFrom[Pathfinding.hashPoint(startX, startY)] = { x = startX, y = startY }

    while #frontier > 0 do
        print("f: " .. #frontier)
        local current = table.remove(frontier, 1)
        print(current.x, current.y)

        if current.x == goalX and current.y == goalY then
            break
        end

        Pathfinding.getNeighbors(map, current.x, current.y, neighbors)
        for _, next in ipairs(neighbors) do
            repeat
                local alreadyHasNode = false
                local nextHash = Pathfinding.hashPoint(next.x, next.y)
                for key, _ in pairs(cameFrom) do
                    if key == nextHash then
                        alreadyHasNode = true
                        break
                    end
                end
                if alreadyHasNode then
                    break
                end

                local priority = Pathfinding.heuristic(next.x, next.y, goalX, goalY)
                print("p: " .. priority)

                -- Add to the frontier, maintaining least to greatest order.
                if false and #frontier > 0 then -- TODO
                    for i = #frontier, 1, -1 do
                        if frontier[i].priority <= priority then
                            table.insert(frontier, i + 1, {
                                priority = priority,
                                x = next.x,
                                y = next.y
                            })
                            break
                        end
                    end
                else
                    table.insert(frontier, {
                        priority = priority,
                        x = next.x,
                        y = next.y
                    })
                end

                cameFrom[Pathfinding.hashPoint(next.x, next.y)] = { x = current.x, y = current.y }
            until true
        end
    end

    return cameFrom
end

function Pathfinding.reconstructPath(startX, startY, goal, cameFrom)
    local path = {}

    local hasPath = false
    local goalHash = Pathfinding.hashPoint(goal.x, goal.y)
    for key, _ in pairs(cameFrom) do
        if key == goalHash then
            hasPath = true
            break
        end
    end

    if not hasPath then
        print("no path")
        return path
    end

    local current = goal

    while current.x ~= startX or current.y ~= startY do
        table.insert(path, current)

        -- FIXME
        print("current")
        current = cameFrom[Pathfinding.hashPoint(current.x, current.y)] -- TODO: Will this work? Lua hashes by reference
    end

    print(#path)

    return path
end
