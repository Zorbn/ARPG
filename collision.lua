UP = 1
DOWN = 2
LEFT = 3
RIGHT = 4

Collision = {
    FRICTION = 20,
}

function Collision.checkCollisionRect(r1x1, r1y1, r1x2, r1y2, r2x1, r2y1, r2x2, r2y2)
    return r1x2 > r2x1 and r1x1 < r2x2 and
        r1y2 > r2y1 and r1y1 < r2y2
end

function Collision.rotateAround(x, y, originX, originY, angle)
    local newX = math.cos(angle) * (x - originX) - math.sin(angle) * (y - originY) + originX
    local newY = math.sin(angle) * (x - originX) + math.cos(angle) * (y - originY) + originY

    return newX, newY
end

function Collision.checkCollisionRectAndMap(map, x1, y1, x2, y2)
    return map:getTileFromPos(x1, y1) ~= 0 or
        map:getTileFromPos(x1, y2) ~= 0 or
        map:getTileFromPos(x2, y1) ~= 0 or
        map:getTileFromPos(x2, y2) ~= 0
end