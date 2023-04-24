Map = {
    WIDTH = 64,
    HEIGHT = 64,
    TILE_SIZE = 8,
}

local tileSprite = love.graphics.newImage("tile.png")

function Map.new()
    local map = {
        spriteBatch = love.graphics.newSpriteBatch(tileSprite),
        tiles = {},
    }

    function map.setTile(self, x, y, tile)
        if x < 1 or x > Map.WIDTH or y < 1 or y > Map.HEIGHT then
            return
        end

        self.tiles[x + y * Map.WIDTH] = tile
    end

    function map.getTile(self, x, y)
        if x < 1 or x > Map.WIDTH or y < 1 or y > Map.HEIGHT then
            return 0
        end

        return self.tiles[x + y * Map.WIDTH]
    end

    function map.getTileFromPos(self, x, y)
        x = math.floor(x / Map.TILE_SIZE) + 1
        y = math.floor(y / Map.TILE_SIZE) + 1

        return self:getTile(x, y)
    end

    function map.generate(self)
        for y = 1, Map.HEIGHT do
            for x = 1, Map.WIDTH do
                if math.random() < 0.2 then
                    self.tiles[x + y * Map.WIDTH] = 1
                else
                    self.tiles[x + y * Map.WIDTH] = 0
                end
            end
        end
    end

    function map.batch(self)
        for y = 1, Map.HEIGHT do
            for x = 1, Map.WIDTH do
                if self.tiles[x + y * Map.WIDTH] == 1 then
                    self.spriteBatch:add((x - 1) * Map.TILE_SIZE, (y - 1) * Map.TILE_SIZE)
                end
            end
        end
    end

    function map.draw(self)
        love.graphics.draw(self.spriteBatch, 0, 0)
    end

    function map.spawnEnemies(self, enemies)
        for y = 1, Map.HEIGHT do
            for x = 1, Map.WIDTH do
                if self.tiles[x + y * Map.WIDTH] == 0 and
                    math.random() < 0.02 then
                    local enemyX = (x - 1) * Map.TILE_SIZE
                    local enemyY = (y - 1) * Map.TILE_SIZE
                    table.insert(enemies, Enemy.new(enemyX, enemyY))
                end
            end
        end
    end

    return map
end
