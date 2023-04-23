local testArray = {}
for i = 1, 5 do
    testArray[i] = i
end

testArray[4] = nil

for i, n in ipairs(testArray) do
    print(i, n)
end

love.graphics.setDefaultFilter("nearest")

local VIEW_SCALE = 4
local INV_VIEW_SCALE = 1 / VIEW_SCALE

local TILE_SIZE = 8

local UP = 1
local DOWN = 2
local LEFT = 3
local RIGHT = 4

local function checkCollisionRect(r1x1, r1y1, r1x2, r1y2, r2x1, r2y1, r2x2, r2y2)
    return r1x2 > r2x1 and r1x1 < r2x2 and
        r1y2 > r2y1 and r1y1 < r2y2
end

local function rotateAround(x, y, originX, originY, angle)
    local newX = math.cos(angle) * (x - originX) - math.sin(angle) * (y - originY) + originX
    local newY = math.sin(angle) * (x - originX) + math.cos(angle) * (y - originY) + originY

    return newX, newY
end

local player = {
    topSprite = love.graphics.newImage("playerTop.png"),
    bottomSprite = love.graphics.newImage("playerBottom.png"),
    topFrames = {},
    bottomFrames = {},
    direction = DOWN,
    x = 0,
    y = 0,
    speed = 50,
    sword = {
        sprite = love.graphics.newImage("sword.png"),
        x = 4,
        y = 4,
        angle = 0,
        MAX_SWING_ANGLE = -math.pi * 0.7,
        SWING_SPEED = 15,
        targetSwingAngle = 0,
        swingAngle = 0,
        scaleY = 1,
    },
    arms = {
        sprite = love.graphics.newImage("playerArms.png"),
    },
}

local playerFrameCount = player.topSprite:getWidth() / TILE_SIZE
for i = 1, playerFrameCount do
    local texX = (i - 1) * TILE_SIZE
    local frame = love.graphics.newQuad(texX, 0, TILE_SIZE, TILE_SIZE, player.topSprite)
    player.topFrames[i] = frame
    player.bottomFrames[i] = frame
end

player.sword.width = player.sword.sprite:getWidth()
player.sword.height = player.sword.sprite:getHeight()
player.sword.targetSwingAngle = player.sword.MAX_SWING_ANGLE
player.sword.swingAngle = player.sword.MAX_SWING_ANGLE

player.arms.width = player.arms.sprite:getWidth()
player.arms.height = player.arms.sprite:getHeight()

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

        if self.health < 0 then
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
        player.sword.targetSwingAngle = -player.sword.targetSwingAngle
        player.sword.scaleY = -player.sword.scaleY
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

    local dmag = math.sqrt(dx * dx + dy * dy)

    if dmag ~= 0 then
        dx = dx / dmag
        dy = dy / dmag

        player.x = player.x + dx * dt * player.speed
        player.y = player.y + dy * dt * player.speed
    end

    local mouseX = love.mouse.getX()
    local mouseY = love.mouse.getY()

    local playerAngleToMouse = math.atan2(mouseY * INV_VIEW_SCALE - player.y, mouseX * INV_VIEW_SCALE - player.x)
    player.sword.angle = playerAngleToMouse
    player.sword.swingAngle = player.sword.swingAngle + (player.sword.targetSwingAngle -
        player.sword.swingAngle) * player.sword.SWING_SPEED * dt

    -- Get the player's angle in 90 degree increments
    -- Shifted by 45 degrees so that the increments are
    -- centered on the player's cardinal directions.
    local angle = math.floor((playerAngleToMouse + math.pi * 0.25) / (math.pi * 0.5))

    if angle == 0 then
        player.direction = RIGHT
    elseif angle == 1 then
        player.direction = DOWN
    elseif angle == -1 then
        player.direction = UP
    elseif angle == 2 or angle == -2 then
        player.direction = LEFT
    end
end

function love.draw()
    love.graphics.clear(0.4, 0.4, 0.4)

    love.graphics.push()
    love.graphics.scale(VIEW_SCALE, VIEW_SCALE)

    local swordAngle = player.sword.angle + player.sword.swingAngle

    local swordHitboxX = player.x + 1.5 * TILE_SIZE
    local swordHitboxY = player.y + 0.5 * TILE_SIZE
    swordHitboxX, swordHitboxY = rotateAround(swordHitboxX, swordHitboxY, player.x + TILE_SIZE * 0.5, player.y + TILE_SIZE * 0.5, swordAngle)
    local swordX1 = swordHitboxX - 0.5 * TILE_SIZE
    local swordX2 = swordHitboxX + 0.5 * TILE_SIZE
    local swordY1 = swordHitboxY - 0.5 * TILE_SIZE
    local swordY2 = swordHitboxY + 0.5 * TILE_SIZE

    for i, enemy in ipairs(enemies) do
        love.graphics.draw(Enemy.SPRITE, enemy.x, enemy.y)

        if checkCollisionRect(enemy.x, enemy.y, enemy.x + TILE_SIZE,
            enemy.y + TILE_SIZE, swordX1, swordY1, swordX2, swordY2) then

            if enemy:takeDamage(25) then
                table.remove(enemies, i)
            end
        end
    end

    love.graphics.draw(player.bottomSprite, player.bottomFrames[player.direction], player.x, player.y)

    love.graphics.draw(player.arms.sprite, player.x + player.sword.x, player.y + player.sword.y,
        swordAngle, 1, player.sword.scaleY, -player.arms.width * 0.2, player.arms.height * 0.5)
    love.graphics.draw(player.sword.sprite, player.x + player.sword.x, player.y + player.sword.y,
        swordAngle, 1, player.sword.scaleY, -player.sword.width * 0.6, player.sword.height * 0.5)

    love.graphics.draw(player.topSprite, player.topFrames[player.direction], player.x, player.y)

    love.graphics.setColor(1.0, 0.0, 0.0, 1.0)
    love.graphics.points(swordX1, swordY1, swordX2, swordY2)
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

    love.graphics.pop()
end