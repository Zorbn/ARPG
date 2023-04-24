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
}

function Enemy.new(x, y)
    local enemy = {
        x = x,
        y = y,
        health = Enemy.MAX_HEALTH,
    }

    function enemy.takeDamage(self, damage)
        self.health = self.health - damage

        if self.health <= 0 then
            return true
        end

        return false
    end

    return enemy
end

local enemies = {}

table.insert(enemies, Enemy.new(50, 50))
table.insert(enemies, Enemy.new(25, 25))
table.insert(enemies, Enemy.new(0, 0))

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
