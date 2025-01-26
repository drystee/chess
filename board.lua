local Board = {}

-- Define numeric identifiers for the pieces
local pieceIds = {
    [1] = "assets/wp.png", -- White Pawn
    [2] = "assets/wr.png", -- White Rook
    [3] = "assets/wn.png", -- White Knight
    [4] = "assets/wb.png", -- White Bishop
    [5] = "assets/wq.png", -- White Queen
    [6] = "assets/wk.png", -- White King
    [7] = "assets/bp.png", -- Black Pawn
    [8] = "assets/br.png", -- Black Rook
    [9] = "assets/bn.png", -- Black Knight
    [10] = "assets/bb.png", -- Black Bishop
    [11] = "assets/bq.png", -- Black Queen
    [12] = "assets/bk.png", -- Black King
}

-- Define starting positions using numeric IDs
local startingPositions = {
    { 8, 9, 10, 11, 12, 10, 9, 8 }, -- Black Rooks, Knights, Bishops, etc.
    { 7, 7, 7, 7, 7, 7, 7, 7 },     -- Black Pawns
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 1, 1, 1, 1, 1, 1, 1, 1 },     -- White Pawns
    { 2, 3, 4, 5, 6, 4, 3, 2 },     -- White Rooks, Knights, Bishops, etc.
}

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
-- Check if the king is in check
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
        return false -- King not found (shouldn't happen unless the game is over)
    end

    for row = 1, 8 do
        for col = 1, 8 do
            local attacker = self.pieces[row][col]
            if attacker and attacker.color ~= color then
                if self:isValidMove(attacker, row, col, kingRow, kingCol) then
                    return true -- King is under attack
                end
            end
        end
    end

    return false
end
-- Check for checkmate
function Board:isCheckmate(color)
    if not self:isKingInCheck(color) then
        return false
    end

    for row = 1, 8 do
        for col = 1, 8 do
            local piece = self.pieces[row][col]
            if piece and piece.color == color then
                local validMoves = self:getValidMoves(piece, row, col)
                for _, move in ipairs(validMoves) do
                    -- Simulate the move
                    local capturedPiece = self.pieces[move.row][move.col]
                    self.pieces[move.row][move.col] = piece
                    self.pieces[row][col] = nil

                    local isStillInCheck = self:isKingInCheck(color)

                    -- Undo the move
                    self.pieces[row][col] = piece
                    self.pieces[move.row][move.col] = capturedPiece

                    if not isStillInCheck then
                        return false -- King can escape
                    end
                end
            end
        end
    end

    return true -- No valid moves to escape check
end
function Board:getValidMoves(piece, fromRow, fromCol)
    local validMoves = {}
    for toRow = 1, 8 do
        for toCol = 1, 8 do
            if self:isValidMove(piece, fromRow, fromCol, toRow, toCol) then
                local targetPiece = self:getPieceAt(toRow, toCol)
                table.insert(validMoves, {
                    row = toRow,
                    col = toCol,
                    isCapture = targetPiece ~= nil, -- Check if the square contains a piece
                })
            end
        end
    end
    return validMoves
end

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
                    color = color, -- Assign color
                }
            else
                self.pieces[row][col] = nil
            end
        end
    end
end

function Board:getSquareAt(x, y)
    local col = math.floor((x - self.x) / self.squareSize) + 1
    local row = math.floor((y - self.y) / self.squareSize) + 1
    if row >= 1 and row <= 8 and col >= 1 and col <= 8 then
        return row, col
    end
    return nil, nil
end
function Board:getAllMovesForBlack()
    local allMoves = {}
    for row = 1, 8 do
        for col = 1, 8 do
            local piece = self:getPieceAt(row, col)
            if piece and piece.color == "black" then
                local validMoves = self:getValidMoves(piece, row, col)
                for _, move in ipairs(validMoves) do
                    table.insert(allMoves, {
                        piece = piece,        -- The piece making the move
                        fromRow = row,        -- Starting row
                        fromCol = col,        -- Starting column
                        toRow = move.row,     -- Target row
                        toCol = move.col,     -- Target column
                        isCapture = move.isCapture, -- Whether it's a capture
                    })
                end
            end
        end
    end
    return allMoves
end
function Board:getPieceAt(row, col)
    return self.pieces[row] and self.pieces[row][col] or nil
end

function Board:updateBoard()
    if self.currentTurn == "black" then
        local blackMoves = self:getAllMovesForBlack()
        
        if #blackMoves > 0 then
            -- Pick and execute a random move
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

function Board:movePiece(fromRow, fromCol, toRow, toCol)
    local piece = self.pieces[fromRow][fromCol]
    if self:isValidMove(piece, fromRow, fromCol, toRow, toCol) then
        -- Handle castling
        if (piece.id == 6 or piece.id == 12) and math.abs(toCol - fromCol) == 2 then
            local rookCol = (toCol > fromCol) and 8 or 1
            local rookNewCol = (toCol > fromCol) and toCol - 1 or toCol + 1
            local rook = self:getPieceAt(fromRow, rookCol)
            self.pieces[fromRow][rookNewCol] = rook
            self.pieces[fromRow][rookCol] = nil
            rook.col = rookNewCol
        end

        local targetPiece = self.pieces[toRow][toCol]
        self.pieces[fromRow][fromCol] = nil
        self.pieces[toRow][toCol] = piece
        piece.row = toRow
        piece.col = toCol
        piece.hasMoved = true
        self.moveSound:play()

        -- Check for check or checkmate
        local opponentColor = (self.currentTurn == "white") and "black" or "white"
        if self:isCheckmate(opponentColor) then
            print(self.currentTurn .. " wins by checkmate!")
        elseif self:isKingInCheck(opponentColor) then
            print(opponentColor .. " is in check!")
        end

        -- Switch turn
        self.currentTurn = opponentColor
        self:updateBoard()
    else
        print("Invalid move!")
    end
end
function Board:draw(selectedPiece)
    -- Draw chessboard squares
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

    -- Highlight valid moves
    if selectedPiece then
        local validMoves = self:getValidMoves(selectedPiece, selectedPiece.row, selectedPiece.col)
        for _, move in ipairs(validMoves) do
            local x = self.x + (move.col - 1) * self.squareSize
            local y = self.y + (move.row - 1) * self.squareSize
            if move.isCapture then
                love.graphics.setColor(1, 1, 1, 0.7) -- Semi-transparent red highlight
                love.graphics.draw(
                    self.attackHighlightImg,
                    x,
                    y,
                    0, -- Rotation
                    self.squareSize / self.attackHighlightImg:getWidth(), -- Scale X
                    self.squareSize / self.attackHighlightImg:getHeight() -- Scale Y
                )

            else
                love.graphics.setColor(1, 1, 1, 0.5) -- Semi-transparent highlight
                love.graphics.draw(
                    self.highlightImg,
                    x,
                    y,
                    0, -- Rotation
                    self.squareSize / self.highlightImg:getWidth(), -- Scale X
                    self.squareSize / self.highlightImg:getHeight() -- Scale Y
                )
            end
        end
    end

    -- Draw pieces
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
                    0, -- Rotation
                    self.squareSize / piece.width, -- Scale X
                    self.squareSize / piece.height -- Scale Y
                )
            end
        end
    end

    -- Draw the selected piece above everything else
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

function Board:isValidMove(piece, fromRow, fromCol, toRow, toCol)
    -- Check if it's the correct turn
    if self.currentTurn == "white" and piece.id >= 7 then
        return false -- It's white's turn, but this is a black piece
    elseif self.currentTurn == "black" and piece.id <= 6 then
        return false -- It's black's turn, but this is a white piece
    end

    -- Check the target square
    local targetPiece = self:getPieceAt(toRow, toCol)
    if targetPiece then
        -- If there's a piece on the target square, ensure it's of the opposite color
        if (piece.id <= 6 and targetPiece.id <= 6) or (piece.id >= 7 and targetPiece.id >= 7) then
            return false -- Cannot capture pieces of the same color
        end
    end

    -- Legal move logic based on piece type
    local rowDiff = math.abs(toRow - fromRow)
    local colDiff = math.abs(toCol - fromCol)

    if piece.id == 6 or piece.id == 12 then -- King
        -- Castling
        if not piece.hasMoved and rowDiff == 0 and colDiff == 2 then
            local rookCol = (toCol > fromCol) and 8 or 1 -- Determine which rook is involved
            local rook = self:getPieceAt(fromRow, rookCol)
            if rook and (rook.id == 2 or rook.id == 8) and not rook.hasMoved then
                -- Ensure the path is clear and not under attack
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

    if piece.id == 1 or piece.id == 7 then -- Pawn
        local direction = (piece.id == 1 and -1) or 1 -- White moves up (-1), black moves down (+1)
        if fromCol == toCol then
            if toRow == fromRow + direction then
                return not targetPiece -- Forward move (must be an empty square)
            elseif toRow == fromRow + 2 * direction and not piece.hasMoved then
                -- Double move on first move
                return not targetPiece and not self:getPieceAt(fromRow + direction, fromCol)
            end
        elseif colDiff == 1 and toRow == fromRow + direction then
            return targetPiece ~= nil -- Capture diagonally (must capture a piece)
        end
    elseif piece.id == 2 or piece.id == 8 then -- Rook
        if rowDiff == 0 or colDiff == 0 then
            return self:isPathClear(fromRow, fromCol, toRow, toCol)
        end
    elseif piece.id == 3 or piece.id == 9 then -- Knight
        return (rowDiff == 2 and colDiff == 1) or (rowDiff == 1 and colDiff == 2)
    elseif piece.id == 4 or piece.id == 10 then -- Bishop
        if rowDiff == colDiff then
            return self:isPathClear(fromRow, fromCol, toRow, toCol)
        end
    elseif piece.id == 5 or piece.id == 11 then -- Queen
        if rowDiff == colDiff or rowDiff == 0 or colDiff == 0 then
            return self:isPathClear(fromRow, fromCol, toRow, toCol)
        end
    elseif piece.id == 6 or piece.id == 12 then -- King
        return rowDiff <= 1 and colDiff <= 1
    end

    return false
end

-- Check if the path is clear for sliding pieces
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
