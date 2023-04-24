require "map"

Camera = {
    VIEW_WIDTH = 200,
    VIEW_HEIGHT = 150,
}

Camera.new = function()
    local camera = {
        scale = 1,
        invScale = 1,
        offsetX = 0,
        offsetY = 0,
        x = 0,
        y = 0,
        width = Camera.VIEW_WIDTH,
        height = Camera.VIEW_HEIGHT,
    }

    function camera.resize(self, windowWidth, windowHeight)
        local widthScale = windowWidth / Camera.VIEW_WIDTH
        local heightScale = windowHeight / Camera.VIEW_HEIGHT
        self.scale = math.min(widthScale, heightScale)
        self.scale = math.max(math.floor(self.scale), 1)
        self.invScale = 1 / self.scale

        self.width = windowWidth / self.scale
        self.height = windowHeight / self.scale

        self.offsetX = -self.width * 0.5
        self.offsetY = -self.height * 0.5
    end

    function camera.focus(self, x, y)
        self.x = x + self.offsetX
        self.y = y + self.offsetY
        self.x = math.min(math.max(self.x, 0), Map.WIDTH * Map.TILE_SIZE - self.width)
        self.y = math.min(math.max(self.y, 0), Map.HEIGHT * Map.TILE_SIZE - self.height)
    end

    return camera
end