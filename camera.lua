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
    }

    function camera.resize(self, width, height)
        local widthScale = width / Camera.VIEW_WIDTH
        local heightScale = height / Camera.VIEW_HEIGHT
        self.scale = math.min(widthScale, heightScale)
        self.scale = math.max(math.floor(self.scale), 1)
        self.invScale = 1 / self.scale

        self.offsetX = -width / self.scale * 0.5
        self.offsetY = -height / self.scale * 0.5
    end

    function camera.focus(self, x, y)
        self.x = x + self.offsetX
        self.y = y + self.offsetY
    end

    return camera
end