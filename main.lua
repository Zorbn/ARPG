love.graphics.setDefaultFilter("nearest")

require "player"
require "camera"
require "map"

local map = Map.new()
map:generate()
map:batch()
local player = Player.new()
local camera = Camera.new()

Enemy = {
    SPEED = 30,
    MAX_HEALTH = 50,
    SPRITE = love.graphics.newImage("playerOld.png"),
    SIZE = Map.TILE_SIZE * 0.95
}

function Enemy.new(x, y)
    local enemy = {
        x = x,
        y = y,
        velocityX = 0,
        velocityY = 0,
        health = Enemy.MAX_HEALTH,
    }

    function enemy.takeDamage(self, damage)
        self.health = self.health - damage

        if self.health <= 0 then
            return true
        end

        return false
    end

    function enemy.update(self, map, dt)
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

    return enemy
end

local enemies = {}

map:spawnEnemies(enemies)

function love.resize(w, h)
    camera:resize(w, h)
end

camera:resize(love.graphics.getWidth(), love.graphics.getHeight())

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        player:swingSword()
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
end
