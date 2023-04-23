require "player"
require "camera"

love.graphics.setDefaultFilter("nearest")

local player = Player.new()

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
end

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

    player:move(dx, dy, dt)
    player:look(mouseX, mouseY)
    player:update(enemies, dt)
end

function love.draw()
    love.graphics.clear(0.4, 0.4, 0.4)

    love.graphics.push()
    love.graphics.scale(Camera.VIEW_SCALE, Camera.VIEW_SCALE)

    for _, enemy in ipairs(enemies) do
        love.graphics.draw(Enemy.SPRITE, enemy.x, enemy.y)
    end

    player:draw()

    love.graphics.pop()
end
