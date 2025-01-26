--modules
local Board = require("board")
local Card = require("card")


--variables
local board
local canvas
local crtShader
local selectedPiece = nil
local selectedCard = nil
local dropzoneSprite
local dropzonePos = { x = 64, y = love.graphics:getHeight() / 2, width = 126, height = 176 } -- Adjust position as needed
local mouseOffset = { x = 0, y = 0 }
local screenWidth = love.graphics.getWidth()
local screenHeight = love.graphics.getHeight()
local startTime = love.timer.getTime()

local cards = {}
local cardSprite

local deck = {
    cards = {},
}

local function move(card, dt)
    local momentum = 0.75
    local max_velocity = 15
    if (card.target_transform.x ~= card.transform.x or card.velocity.x ~= 0) or
        (card.target_transform.y ~= card.transform.y or card.velocity.y ~= 0) then
        card.velocity.x = momentum * card.velocity.x +
            (1 - momentum) * (card.target_transform.x - card.transform.x) * 30 * dt
        card.velocity.y = momentum * card.velocity.y +
            (1 - momentum) * (card.target_transform.y - card.transform.y) * 30 * dt
        card.transform.x = card.transform.x + card.velocity.x
        card.transform.y = card.transform.y + card.velocity.y

        local velocity = math.sqrt(card.velocity.x ^ 2 + card.velocity.y ^ 2)
        if velocity > max_velocity then
            card.velocity.x = max_velocity * card.velocity.x / velocity
            card.velocity.y = max_velocity * card.velocity.y / velocity
        end
    end
end


--init love
function love.draw()
    -- Draw the board and pieces
    board:draw(selectedPiece)

    for _, card in ipairs(cards) do
        card:draw()
    end

    -- Draw the playcard zone
    love.graphics.draw(dropzoneSprite, dropzonePos.x, dropzonePos.y, 0, 1, 1)
end

function love.update(dt)
    -- Update the position of the selected piece
    if selectedPiece then
        local x, y = love.mouse.getPosition()
        selectedPiece.tempX = x - mouseOffset.x
        selectedPiece.tempY = y - mouseOffset.y
    end

    -- Update the position of the selected card
    if selectedCard then
        local x, y = love.mouse.getPosition()
        selectedCard.tempX = x - mouseOffset.x
        selectedCard.tempY = y - mouseOffset.y
    end

    for _, card in ipairs(cards) do
        if card.dragging then
            card.target_transform.x = love.mouse.getX() - card.transform.width / 2
            card.target_transform.y = love.mouse.getY() - card.transform.height / 2
        end
        card:update(dt)
    end
end

love.load = function()
    -- Keep pixels sharp and intact instead of blurring
    love.graphics.setDefaultFilter('nearest', 'nearest')
    board = Board:new() -- 800px size, 8x8 board

    -- Load assets
    local cardSprite = love.graphics.newImage("assets/card.png")
    dropzoneSprite = love.graphics.newImage("assets/dropzone.png")

    -- Create power cards
    local powers = { "boost", "freeze", "shield" }
    -- Create cards
    for i = 1, 3 do
        local x = 100 + (i - 1) * 150 -- Space cards evenly at the bottom
        local y = screenHeight - 150
        local card = Card:new(cardSprite, x, y, 96, 135)
        table.insert(cards, card)
    end
    crtShader = love.graphics.newShader("crt.glsl")
    canvas = love.graphics.newCanvas(screenWidth, screenHeight, { type = '2d', readable = true })
end

love.mousepressed = function(x, y, button)
    if button == 1 then -- Left mouse button
        for _, card in ipairs(cards) do
            if card:isClicked(x, y) then
                selectedCard = card
                card.dragging = true
                mouseOffset.x = x - card.transform.x
                mouseOffset.y = y - card.transform.y
                return
            end
        end

        -- If no card is clicked, check if a chess piece is clicked
        local row, col = board:getSquareAt(x, y)
        if row and col then
            local piece = board:getPieceAt(row, col)
            if piece then
                local isWhitePiece = piece.id >= 1 and piece.id <= 6
                local isBlackPiece = piece.id >= 7 and piece.id <= 12
                if (board.currentTurn == "white" and isWhitePiece) or
                   (board.currentTurn == "black" and isBlackPiece) then
                    selectedPiece = piece
                    mouseOffset.x = x - (board.x + (col - 1) * board.squareSize)
                    mouseOffset.y = y - (board.y + (row - 1) * board.squareSize)
                    selectedPiece.tempX = x - mouseOffset.x
                    selectedPiece.tempY = y - mouseOffset.y
                end
            end
        end
    end
end


love.mousereleased = function(x, y, button)
    if button == 1 then -- Left mouse button
        -- Release the selected card
        if selectedCard then
            selectedCard.dragging = false

            -- Check if the card is within the playcard zone
            if x > dropzonePos.x and x < dropzonePos.x + dropzonePos.width
                and y > dropzonePos.y and y < dropzonePos.y + dropzonePos.height then
                -- Snap the card to the center of the playcard zone
                selectedCard.target_transform.x = dropzonePos.x + (dropzonePos.width - selectedCard.transform.width) / 2
                selectedCard.target_transform.y = dropzonePos.y + (dropzonePos.height - selectedCard.transform.height) / 2
            else
                -- Return the card to its original position
                selectedCard.target_transform.x = selectedCard.original_position.x
                selectedCard.target_transform.y = selectedCard.original_position.y
            end
    
            selectedCard = nil
        end

        -- Release the selected piece
        if selectedPiece then
            local targetRow, targetCol = board:getSquareAt(x, y)
            if targetRow and targetCol then
                local targetPiece = board:getPieceAt(targetRow, targetCol)
                -- Ensure the move is valid by letting the board logic handle the check
                board:movePiece(selectedPiece.row, selectedPiece.col, targetRow, targetCol)
            end
            selectedPiece = nil
        end
    end
end

love.keypressed = function(pressed_key)
    if pressed_key == 'escape' then
        love.event.quit()
    end
end
