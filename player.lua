require "collision"
require "camera"

Player = {}

function Player.new()
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
            isSwinging = false,
            damage = 25,
            hits = {},
            -- The sword is not longer swing when it is within
            -- this distance to the target swing angle.
            stopDistance = 0.4,
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

    function player.swingSword(self)
        if self.sword.isSwinging then
            return
        end

        self.sword.isSwinging = true
        self.sword.targetSwingAngle = -self.sword.targetSwingAngle
    end

    function player.move(self, dx, dy, dt)
        local dmag = math.sqrt(dx * dx + dy * dy)

        if dmag ~= 0 then
            dx = dx / dmag
            dy = dy / dmag

            self.x = self.x + dx * dt * self.speed
            self.y = self.y + dy * dt * self.speed
        end
    end

    function player.look(self, mouseX, mouseY)
        local playerAngleToMouse = math.atan2(mouseY * Camera.INV_VIEW_SCALE - self.y, mouseX * Camera.INV_VIEW_SCALE - self.x)
        self.sword.angle = playerAngleToMouse

        -- Get the player's angle in 90 degree increments
        -- Shifted by 45 degrees so that the increments are
        -- centered on the player's cardinal directions.
        local angle = math.floor((playerAngleToMouse + math.pi * 0.25) / (math.pi * 0.5))

        if angle == 0 then
            self.direction = RIGHT
        elseif angle == 1 then
            self.direction = DOWN
        elseif angle == -1 then
            self.direction = UP
        elseif angle == 2 or angle == -2 then
            self.direction = LEFT
        end
    end

    function player.update(self, enemies, dt)
        self.sword.swingAngle = self.sword.swingAngle + (self.sword.targetSwingAngle -
            self.sword.swingAngle) * self.sword.SWING_SPEED * dt

        if self.sword.isSwinging and math.abs(self.sword.swingAngle - self.sword.targetSwingAngle) < self.sword.stopDistance then
            self.sword.isSwinging = false
            self.sword.scaleY = -self.sword.scaleY

            for enemy, _ in pairs(self.sword.hits) do
                self.sword.hits[enemy] = nil
            end
        end

        local swordAngle = self.sword.angle + self.sword.swingAngle

        local swordHitboxX = self.x + 1.5 * TILE_SIZE
        local swordHitboxY = self.y + 0.5 * TILE_SIZE
        swordHitboxX, swordHitboxY = Collision.rotateAround(swordHitboxX, swordHitboxY, self.x + TILE_SIZE * 0.5,
        self.y + TILE_SIZE * 0.5, swordAngle)
        local swordX1 = swordHitboxX - 0.5 * TILE_SIZE
        local swordX2 = swordHitboxX + 0.5 * TILE_SIZE
        local swordY1 = swordHitboxY - 0.5 * TILE_SIZE
        local swordY2 = swordHitboxY + 0.5 * TILE_SIZE

        for i, enemy in ipairs(enemies) do
            if self.sword.isSwinging and Collision.checkCollisionRect(enemy.x, enemy.y, enemy.x + TILE_SIZE,
                    enemy.y + TILE_SIZE, swordX1, swordY1, swordX2, swordY2) then
                -- Don't hit an enemy that has already been hit this swing.
                if self.sword.hits[enemy] == nil and enemy:takeDamage(self.sword.damage) then
                    -- The enemy is dead.
                    table.remove(enemies, i)
                end

                self.sword.hits[enemy] = true
            end
        end
    end

    function player.draw(self)
        love.graphics.draw(self.bottomSprite, self.bottomFrames[self.direction], self.x, self.y)

        local swordAngle = self.sword.angle + self.sword.swingAngle
        love.graphics.draw(self.arms.sprite, self.x + self.sword.x, self.y + self.sword.y,
            swordAngle, 1, self.sword.scaleY, -self.arms.width * 0.2, self.arms.height * 0.5)
        love.graphics.draw(self.sword.sprite, self.x + self.sword.x, self.y + self.sword.y,
            swordAngle, 1, self.sword.scaleY, -self.sword.width * 0.6, self.sword.height * 0.5)

        love.graphics.draw(self.topSprite, self.topFrames[self.direction], self.x, self.y)
    end

    return player
end