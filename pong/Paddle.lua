Paddle = Class{}

function Paddle:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    self.dx = 0
    self.dy = 0
end

function Paddle:update(dt)
    if self.dy < 0 then
        self.y = math.max(GAME_BOUNDS_TOP, self.y + self.dy * dt)
    elseif self.dy > 0 then
        self.y = math.min(GAME_BOUNDS_BOT - self.height, self.y + self.dy * dt)
    end
end

function Paddle:setVelocity(dy)
    self.dy = dy
end

function Paddle:render()
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end
