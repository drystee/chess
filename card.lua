local Card = {}
Card.__index = Card

function Card:new(sprite, x, y, width, height)
    local card = setmetatable({}, { __index = Card })
    card.sprite = sprite
    card.transform = { x = x, y = y, width = width, height = height }
    card.target_transform = { x = x, y = y }
    card.original_position = { x = x, y = y } -- Save the initial position
    card.velocity = { x = 0, y = 0 }
    card.dragging = false
    return card
end
local function align(deck)
    local deck_height = 10 / #deck.cards
    for position, card in ipairs(deck.cards) do
        if not card.dragging then
            card.target_transform.x = deck.transform.x - deck_height * (position - 1)
            card.target_transform.y = deck.transform.y + deck_height * (position - 1)
        end
    end
end

function Card:update(dt)
    local momentum = 0.75
    local max_velocity = 25

    -- Smooth movement to target position
    self.velocity.x = momentum * self.velocity.x +
        (1 - momentum) * (self.target_transform.x - self.transform.x) * 30 * dt
    self.velocity.y = momentum * self.velocity.y +
        (1 - momentum) * (self.target_transform.y - self.transform.y) * 30 * dt
    self.transform.x = self.transform.x + self.velocity.x
    self.transform.y = self.transform.y + self.velocity.y

    local velocity = math.sqrt(self.velocity.x ^ 2 + self.velocity.y ^ 2)
    if velocity > max_velocity then
        self.velocity.x = max_velocity * self.velocity.x / velocity
        self.velocity.y = max_velocity * self.velocity.y / velocity
    end
end

-- Draw the card
function Card:draw()
    -- Draw the card sprite
    love.graphics.draw(
        self.sprite,
        self.transform.x,
        self.transform.y,
        0,                                              -- No rotation
        self.transform.width / self.sprite:getWidth(),  -- Scale X
        self.transform.height / self.sprite:getHeight() -- Scale Y
    )

end

function Card:isClicked(x, y)
    return x >= self.transform.x and x <= (self.transform.x + self.transform.width) and
           y >= self.transform.y and y <= (self.transform.y + self.transform.height)
end

-- Trigger the card's power effect
function Card:activatePower()
    print("Activated power: " .. self.power)
    -- Add specific effects based on the card's power
    if self.power == "boost" then
        -- Example: Boost a piece's speed
    elseif self.power == "freeze" then
        -- Example: Freeze an opponent piece
    elseif self.power == "shield" then
        -- Example: Add a shield to a piece
    end
end

return Card
