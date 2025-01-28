-- board.lua
-- written by @drystee 28/01/2025

local Board = {}

local pieceIds = {
    [1] = "assets/wp.png", -- white pawn
    [2] = "assets/wr.png", -- white rook
    [3] = "assets/wn.png", -- white knight
    [4] = "assets/wb.png", -- white bishop
    [5] = "assets/wq.png", -- white queen
    [6] = "assets/wk.png", -- white king
    [7] = "assets/bp.png", -- black pawn
    [8] = "assets/br.png", -- black rook
    [9] = "assets/bn.png", -- black knight
    [10] = "assets/bb.png", -- black bishop
    [11] = "assets/bq.png", -- black queen
    [12] = "assets/bk.png", -- black king
}

-- sefine starting positions 
local startingPositions = {
    { 8, 9, 10, 11, 12, 10, 9, 8 }, 
    { 7, 7, 7, 7, 7, 7, 7, 7 },   
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 1, 1, 1, 1, 1, 1, 1, 1 },    
    { 2, 3, 4, 5, 6, 4, 3, 2 },     
}

-- init board
function Board:new(size, squares)
    local self = setmetatable({}, { __index = Board })
    self.size =  love.graphics.getHeight()
    self.squares =  8
    self.squareSize = self.size / self.squares
    self.x = (love.graphics.getWidth() - self.size) / 2
    self.y = (love.graphics.getHeight() - self.size) / 2

    self.pieces = {}
    self.moveSound = love.audio.newSource("assets/Move.wav", "static")
    self.currentTurn = "white"
    self:initializePieces()
    self.highlightImg = love.graphics.newImage("assets/highlight.png")
    self.attackHighlightImg = love.graphics.newImage("assets/highlight_attack.png")
    return self
end

-- check if given king is in check
function Board:isKingInCheck(color)
    local kingRow, kingCol
    for row = 1, 8 do
        for col = 1, 8 do
            local piece = self.pieces[row][col]
            if piece and piece.color == color and (piece.id == 6 or piece.id == 12) then
                kingRow, kingCol = row, col
                break
            end
        end
    end

    if not kingRow or not kingCol then
        return false -- king not found
    end

    for row = 1, 8 do
        for col = 1, 8 do
            local attacker = self.pieces[row][col]
            if attacker and attacker.color ~= color then
                if self:isValidMove(attacker, row, col, kingRow, kingCol) then
                    return true -- king is under attack
                end
            end
        end
    end

    return false
end

-- return valid moves for given piece
function Board:getValidMoves(piece, fromRow, fromCol)
    local validMoves = {}
    for toRow = 1, 8 do
        for toCol = 1, 8 do
            if self:isValidMove(piece, fromRow, fromCol, toRow, toCol) then
                local targetPiece = self:getPieceAt(toRow, toCol)
                table.insert(validMoves, {
                    row = toRow,
                    col = toCol,
                    isCapture = targetPiece ~= nil, -- is attacking?
                })
            end
        end
    end
    return validMoves
end

-- init pieces
function Board:initializePieces()
    for row = 1, #startingPositions do
        self.pieces[row] = {}
        for col = 1, #startingPositions[row] do
            local pieceId = startingPositions[row][col]
            if pieceId ~= 0 then
                local img = love.graphics.newImage(pieceIds[pieceId])
                local color = (pieceId <= 6) and "white" or "black"
                self.pieces[row][col] = {
                    id = pieceId,
                    img = img,
                    width = img:getWidth(),
                    height = img:getHeight(),
                    hasMoved = false,
                    row = row,
                    col = col,
                    color = color, 
                }
            else
                self.pieces[row][col] = nil
            end
        end
    end
end

-- return square from mouse pos
function Board:getSquareAt(x, y)
    local col = math.floor((x - self.x) / self.squareSize) + 1
    local row = math.floor((y - self.y) / self.squareSize) + 1
    if row >= 1 and row <= 8 and col >= 1 and col <= 8 then
        return row, col
    end
    return nil, nil
end

-- return all legal moves for black (temp code)
function Board:getAllMovesForBlack()
    local allMoves = {}
    for row = 1, 8 do
        for col = 1, 8 do
            local piece = self:getPieceAt(row, col)
            if piece and piece.color == "black" then
                local validMoves = self:getValidMoves(piece, row, col)
                for _, move in ipairs(validMoves) do
                    table.insert(allMoves, {
                        piece = piece,        
                        fromRow = row,        
                        fromCol = col,        
                        toRow = move.row,     
                        toCol = move.col,    
                        isCapture = move.isCapture, 
                    })
                end
            end
        end
    end
    return allMoves
end

-- return table from index
function Board:getPieceAt(row, col)
    return self.pieces[row] and self.pieces[row][col] or nil
end

-- check status of board inbetween moves
function Board:updateBoard()
    if self.currentTurn == "black" then
        -- generate rand seed using time
        local timeSeed = os.time() + love.timer.getTime()
        love.math.setRandomSeed(timeSeed)

        local blackMoves = self:getAllMovesForBlack()
        if #blackMoves > 0 then
            local randomMove = blackMoves[math.random(1, #blackMoves)]
            self:movePiece(
                randomMove.fromRow,
                randomMove.fromCol,
                randomMove.toRow,
                randomMove.toCol
            )
        end
    end
end

-- move a piece 
function Board:movePiece(fromRow, fromCol, toRow, toCol)
    local piece = self.pieces[fromRow][fromCol]
    if self:isValidMove(piece, fromRow, fromCol, toRow, toCol) then
        local targetPiece = self.pieces[toRow][toCol]
        self.pieces[fromRow][fromCol] = nil
        self.pieces[toRow][toCol] = piece
        piece.row = toRow
        piece.col = toCol
        piece.hasMoved = true
        self.moveSound:play()

        -- check for pawn promotions
        if (piece.id == 1 and toRow == 1) or (piece.id == 7 and toRow == 8) then
            local newQueenId = (piece.id == 1) and 5 or 11 
            local img = love.graphics.newImage(pieceIds[newQueenId])
            self.pieces[toRow][toCol] = {
                id = newQueenId,
                img = img,
                width = img:getWidth(),
                height = img:getHeight(),
                hasMoved = true,
                row = toRow,
                col = toCol,
                color = piece.color,
            }
            print(piece.color .. " pawn promoted to a queen")
        end

        -- Switch turn
        self.currentTurn = (self.currentTurn == "white") and "black" or "white"
        self:updateBoard()
    else
        print("invalid move")
    end
end

-- draw everything to window
function Board:draw(selectedPiece)
    for row = 0, self.squares - 1 do
        for col = 0, self.squares - 1 do
            if (row + col) % 2 == 0 then
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(0.7, 0.7, 0.7)
            end
            love.graphics.rectangle(
                "fill",
                self.x + col * self.squareSize,
                self.y + row * self.squareSize,
                self.squareSize,
                self.squareSize
            )
        end
    end

        -- highlight king if in check
        local color = (self.currentTurn == "white") and "black" or "white"
        if self:isKingInCheck(color) then
            for row = 1, 8 do
                for col = 1, 8 do
                    local piece = self.pieces[row][col]
                    if piece and piece.id == (color == "white" and 6 or 12) then
                        self:highlightKing(row, col)
                    end
                end
            end
        end

    -- highlight legal moves
    if selectedPiece then
        local validMoves = self:getValidMoves(selectedPiece, selectedPiece.row, selectedPiece.col)
        for _, move in ipairs(validMoves) do
            local x = self.x + (move.col - 1) * self.squareSize
            local y = self.y + (move.row - 1) * self.squareSize
            if move.isCapture then
                love.graphics.setColor(1, 1, 1, 0.7) 
                love.graphics.draw(
                    self.attackHighlightImg,
                    x,
                    y,
                    0, 
                    self.squareSize / self.attackHighlightImg:getWidth(),
                    self.squareSize / self.attackHighlightImg:getHeight() 
                )

            else
                love.graphics.setColor(1, 1, 1, 0.5) 
                love.graphics.draw(
                    self.highlightImg,
                    x,
                    y,
                    0, 
                    self.squareSize / self.highlightImg:getWidth(), 
                    self.squareSize / self.highlightImg:getHeight() 
                )
            end
        end
    end

    -- draw pieces
    for row = 1, 8 do
        for col = 1, 8 do
            local piece = self.pieces[row][col]
            if piece and piece ~= selectedPiece then
                local x = self.x + (col - 1) * self.squareSize
                local y = self.y + (row - 1) * self.squareSize
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(
                    piece.img,
                    x,
                    y,
                    0, 
                    self.squareSize / piece.width,
                    self.squareSize / piece.height 
                )
            end
        end
    end

    -- draw the selected piece
    if selectedPiece then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(
            selectedPiece.img,
            selectedPiece.tempX,
            selectedPiece.tempY,
            0,
            self.squareSize / selectedPiece.width,
            self.squareSize / selectedPiece.height
        )
    end
end

-- highlight the king
function Board:highlightKing(kingRow, kingCol)
    local x = self.x + (kingCol - 1) * self.squareSize
    local y = self.y + (kingRow - 1) * self.squareSize

    love.graphics.setColor(1, 0, 0, 0.5) 
    love.graphics.draw(
        self.attackHighlightImg,
        x,
        y,
        0, 
        self.squareSize / self.attackHighlightImg:getWidth(), 
        self.squareSize / self.attackHighlightImg:getHeight() 
    )
end

function Board:isValidMove(piece, fromRow, fromCol, toRow, toCol)
    -- check if it's the correct turn
    if self.currentTurn == "white" and piece.id >= 7 then
        return false 
    elseif self.currentTurn == "black" and piece.id <= 6 then
        return false
    end

    local targetPiece = self:getPieceAt(toRow, toCol)
    if targetPiece then
        if (piece.id <= 6 and targetPiece.id <= 6) or (piece.id >= 7 and targetPiece.id >= 7) then
            return false
        end
    end

    local rowDiff = math.abs(toRow - fromRow)
    local colDiff = math.abs(toCol - fromCol)

    if piece.id == 6 or piece.id == 12 then -- king
        -- castling
        if not piece.hasMoved and rowDiff == 0 and colDiff == 2 then
            local rookCol = (toCol > fromCol) and 8 or 1 -- determine which rook is involved
            local rook = self:getPieceAt(fromRow, rookCol)
            if rook and (rook.id == 2 or rook.id == 8) and not rook.hasMoved then
                -- ensure the path is clear and not under attack
                local pathClear = self:isPathClear(fromRow, fromCol, fromRow, rookCol)
                local squaresSafe = true
                for col = math.min(fromCol, toCol), math.max(fromCol, toCol) do
                    if self:isKingInCheck(piece.color) then
                        squaresSafe = false
                        break
                    end
                end
                return pathClear and squaresSafe
            end
        end
        return rowDiff <= 1 and colDiff <= 1
    end

    if piece.id == 1 or piece.id == 7 then -- pawn
        local direction = (piece.id == 1 and -1) or 1 -- white moves up (-1), black moves down (+1)
        if fromCol == toCol then
            if toRow == fromRow + direction then
                return not targetPiece -- forward move (must be an empty square)
            elseif toRow == fromRow + 2 * direction and not piece.hasMoved then
                -- double move on first move
                return not targetPiece and not self:getPieceAt(fromRow + direction, fromCol)
            end
        elseif colDiff == 1 and toRow == fromRow + direction then
            return targetPiece ~= nil -- capture diagonally (must capture a piece)
        end
    elseif piece.id == 2 or piece.id == 8 then -- rook
        if rowDiff == 0 or colDiff == 0 then
            return self:isPathClear(fromRow, fromCol, toRow, toCol)
        end
    elseif piece.id == 3 or piece.id == 9 then -- knight
        return (rowDiff == 2 and colDiff == 1) or (rowDiff == 1 and colDiff == 2)
    elseif piece.id == 4 or piece.id == 10 then -- bishop
        if rowDiff == colDiff then
            return self:isPathClear(fromRow, fromCol, toRow, toCol)
        end
    elseif piece.id == 5 or piece.id == 11 then -- queen
        if rowDiff == colDiff or rowDiff == 0 or colDiff == 0 then
            return self:isPathClear(fromRow, fromCol, toRow, toCol)
        end
    elseif piece.id == 6 or piece.id == 12 then -- king
        return rowDiff <= 1 and colDiff <= 1
    end

    return false
end

-- check if the path is clear for sliding pieces
function Board:isPathClear(fromRow, fromCol, toRow, toCol)
    local rowStep = (toRow > fromRow and 1) or (toRow < fromRow and -1) or 0
    local colStep = (toCol > fromCol and 1) or (toCol < fromCol and -1) or 0
    local row, col = fromRow + rowStep, fromCol + colStep

    while row ~= toRow or col ~= toCol do
        if self.pieces[row][col] then
            return false
        end
        row = row + rowStep
        col = col + colStep
    end
    return true
end

return Board
