Pathfinding = {}

local function heuristic(x1, y1, x2, y2)
    return math.abs(x1 - x2) + math.abs(y1 - y2)
end

local function hashPoint(x, y)
    return x + (y - 1) * Map.WIDTH
end

local function unhashPoint(i)
    i = i - 1
    local x = i % Map.WIDTH + 1
    local y = math.floor(i / Map.WIDTH) + 1
    return x, y
end

local function getNeighbors(map, x, y, neighbors)
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
end

local function aStarSearch(map, startX, startY, goalX, goalY)
    local cameFrom = {}

    local neighbors = {}
    local frontier = {
        priority = 0,
        x = startX,
        y = startY,
    }

    cameFrom[hashPoint(startX, startY)] = { x = startX, y = startY }

    while frontier ~= nil do
        local current = frontier
        frontier = frontier.next

        if current.x == goalX and current.y == goalY then
            break
        end

        getNeighbors(map, current.x, current.y, neighbors)
        for _, next in ipairs(neighbors) do
            repeat
                local alreadyHasNode = false
                local nextHash = hashPoint(next.x, next.y)
                for key, _ in pairs(cameFrom) do
                    if key == nextHash then
                        alreadyHasNode = true
                        break
                    end
                end
                if alreadyHasNode then
                    break
                end

                local priority = heuristic(next.x, next.y, goalX, goalY)

                -- Add to the frontier, maintaining least to greatest order.
                local nextNode = {
                    priority = priority,
                    x = next.x,
                    y = next.y,
                }

                if frontier == nil then
                    -- There is no first node, so the new node will be the first.
                    frontier = nextNode
                elseif frontier.priority > nextNode.priority then
                    -- The new node belongs in front of the first node.
                    nextNode.next = frontier
                    frontier = nextNode
                else
                    -- The new node belongs later in the list.
                    local searchNode = frontier
                    while searchNode.next ~= nil and searchNode.next.priority < nextNode.priority do
                        searchNode = searchNode.next
                    end
                    nextNode.next = searchNode.next
                    searchNode.next = nextNode
                end

                cameFrom[hashPoint(next.x, next.y)] = { x = current.x, y = current.y }
            until true
        end
    end

    return cameFrom
end

local function reconstructPath(startX, startY, goal, cameFrom)
    local path = {}

    local hasPath = false
    local goalHash = hashPoint(goal.x, goal.y)
    for key, _ in pairs(cameFrom) do
        if key == goalHash then
            hasPath = true
            break
        end
    end

    if not hasPath then
        return path
    end

    local current = goal

    while current.x ~= startX or current.y ~= startY do
        table.insert(path, current)
        current = cameFrom[hashPoint(current.x, current.y)]
    end

    return path
end

function Pathfinding.aStar(map, startX, startY, goalX, goalY)
    local cameFrom = aStarSearch(map, startX, startY, goalX, goalY)
    local path = reconstructPath(startX, startY, {x = goalX, y = goalY}, cameFrom)
    return path
end
