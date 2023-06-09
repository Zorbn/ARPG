
function love.run()
    if love.load then
        love.load(love.arg.parseGameArguments(arg), arg)
    end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then
        love.timer.step()
    end

    local dt = 0

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then
            dt = love.timer.step()
        end

        -- Call update and draw
        if love.update then
            love.update(dt)
        end -- will pass 0 if love.timer is disabled

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then
                love.draw()
            end

            love.graphics.present()
        end

        -- if love.timer then love.timer.sleep(0.001) end
    end
end

love.graphics.setDefaultFilter("nearest")

require "player"
require "camera"
require "map"
require "pathfinding"

local map = Map.new()
map:generate()
map:batch()
local player = Player.new()
local camera = Camera.new()

Enemy = {
    SPEED = 30,
    MAX_HEALTH = 50,
    SPRITE = love.graphics.newImage("playerOld.png"),
    SIZE = Map.TILE_SIZE * 0.95,
    PATHING_NODE_STOP_DISTANCE = Map.TILE_SIZE * 0.1,
    REPATH_DELAY = 0.2,
}

Enemy.PATHING_PADDING = (Map.TILE_SIZE - Enemy.SIZE) * 0.5

function Enemy.new(x, y)
    local enemy = {
        x = x,
        y = y,
        velocityX = 0,
        velocityY = 0,
        health = Enemy.MAX_HEALTH,
        path = {},
        pathI = 0,
        -- Time until a repath is needed.
        timeToRepath = 0,
    }

    function enemy.repath(self)
        local startX = math.floor(self.x / Map.TILE_SIZE) + 1
        local startY = math.floor(self.y / Map.TILE_SIZE) + 1
        local goalX = math.floor(player.x / Map.TILE_SIZE) + 1
        local goalY = math.floor(player.y / Map.TILE_SIZE) + 1
        self.path = Pathfinding.aStar(map, startX, startY, goalX, goalY)
        self.pathI = #self.path
        self.timeToRepath = Enemy.REPATH_DELAY
    end

    enemy:repath()

    function enemy.takeDamage(self, damage)
        self.health = self.health - damage

        if self.health <= 0 then
            return true
        end

        return false
    end

    function enemy.updatePathing(self, map, dt)
        self.timeToRepath = self.timeToRepath - dt

        -- Check if the path is empty.
        if self.pathI < 1 then
            if self.timeToRepath <= 0 then
                self:repath()
            end

            return
        end

        local targetNode = self.path[self.pathI]
        local targetWorldX = (targetNode.x - 1) * Map.TILE_SIZE + Enemy.PATHING_PADDING
        local targetWorldY = (targetNode.y - 1) * Map.TILE_SIZE + Enemy.PATHING_PADDING

        local dx = targetWorldX - self.x
        local dy = targetWorldY - self.y

        local dmag = math.sqrt(dx * dx + dy * dy)
        dx = dx / dmag * Enemy.SPEED * dt
        dy = dy / dmag * Enemy.SPEED * dt

        self.x = self.x + dx
        self.y = self.y + dy

        local distToNodeX = targetWorldX - self.x
        local distToNodeY = targetWorldY - self.y

        local distToNode = math.sqrt(distToNodeX * distToNodeX + distToNodeY * distToNodeY)

        -- Check if we need to go to the next node.
        if distToNode <= Enemy.PATHING_NODE_STOP_DISTANCE then
            -- Only repath upon reaching a node, otherwise
            -- pathfinders will cut corners sometimes after
            -- a repath.
            if self.timeToRepath <= 0 then
                self:repath()
            else
                self.pathI = self.pathI - 1
            end
        end
    end

    function enemy.updateKnockback(self, map, dt)
        local nextX = self.x + self.velocityX * dt
        local nextY = self.y + self.velocityY * dt

        if Collision.checkCollisionRectAndMap(map, nextX, self.y,
            nextX + Enemy.SIZE, self.y + Enemy.SIZE) then
            nextX = self.x
            self.velocityX = -self.velocityX
        end

        self.x = nextX

        if Collision.checkCollisionRectAndMap(map, self.x, nextY,
            self.x + Enemy.SIZE, nextY + Enemy.SIZE) then
            nextY = self.y
            self.velocityY = -self.velocityY
        end

        self.y = nextY

        self.velocityX = self.velocityX - self.velocityX * Collision.FRICTION * dt
        self.velocityY = self.velocityY - self.velocityY * Collision.FRICTION * dt
    end

    function enemy.update(self, map, dt)
        if (self.velocityX ~= 0 or self.velocityY ~= 0) and (math.abs(self.velocityX) < 1 and math.abs(self.velocityY) < 1) then
            self.velocityX = 0
            self.velocityY = 0
            self:repath()
        end

        if self.velocityX == 0 and self.velocityY == 0 then
            self:updatePathing(map, dt)
        else
            self:updateKnockback(map, dt)
        end
    end

    return enemy
end

local enemies = {}

map:spawnEnemies(enemies)

function love.resize(w, h)
    camera:resize(w, h)
end

camera:resize(love.graphics.getWidth(), love.graphics.getHeight())

map:setTile(7, 1, 0)
local path = Pathfinding.aStar(map, 1, 1, 7, 1)
local pathI = #path

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        player:swingSword()
    end

    if button == 2 then
        if pathI >= 1 then
            player.x = (path[pathI].x - 1) * Map.TILE_SIZE
            player.y = (path[pathI].y - 1) * Map.TILE_SIZE
            pathI = pathI - 1
        end

        for _, enemy in ipairs(enemies) do
            if enemy.pathI >= 1 then
                local enemyNode = enemy.path[enemy.pathI]
                enemy.x = (enemyNode.x - 1) * Map.TILE_SIZE
                enemy.y = (enemyNode.y - 1) * Map.TILE_SIZE
                enemy.pathI = enemy.pathI - 1
            end
        end
    end
end

function love.update(dt)
    local dx = 0
    local dy = 0

    if love.keyboard.isDown("w") then
        dy = dy - 1
    end

    if love.keyboard.isDown("s") then
        dy = dy + 1
    end

    if love.keyboard.isDown("a") then
        dx = dx - 1
    end

    if love.keyboard.isDown("d") then
        dx = dx + 1
    end

    local mouseX = love.mouse.getX()
    local mouseY = love.mouse.getY()

    for _, enemy in ipairs(enemies) do
        enemy:update(map, dt)
    end

    player:move(map, dx, dy, dt)
    player:look(camera, mouseX, mouseY)
    player:update(enemies, dt)
    camera:focus(player.x, player.y)
end

function love.draw()
    love.graphics.clear(0.4, 0.4, 0.4)

    love.graphics.push()
    love.graphics.scale(camera.scale, camera.scale)
    love.graphics.translate(-camera.x, -camera.y)

    map:draw()

    for _, enemy in ipairs(enemies) do
        love.graphics.draw(Enemy.SPRITE, enemy.x, enemy.y)
    end

    player:draw()

    love.graphics.pop()

    love.graphics.print(love.timer.getFPS(), 0, 0)
end
