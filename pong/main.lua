-- Included Libraries
push = require "push"
Class = require 'class'

-- Included Classes
require "Paddle"
require "Ball"

-- Constants
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

GAME_BOUNDS_TOP = 10
GAME_BOUNDS_BOT = VIRTUAL_HEIGHT - 10

PADDLE_SPEED = 200

-- Love2d runs this function immediately.
function love.load()
    math.randomseed(os.time())
    love.window.setTitle("Pong")
    love.graphics.setDefaultFilter("nearest", "nearest")
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    -- Fonts
    scoreFont = love.graphics.newFont("font.ttf", 32)
    smallFont = love.graphics.newFont("font.ttf", 8)

    -- Sounds
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/bounce.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['win'] = love.audio.newSource('sounds/win.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/bounce.wav', 'static')
    }

    -- Globals
    player1score = 0
    player2score = 0

    -- Paddles
    paddleHeight = 20
    paddleWidth = 5

    player1 = Paddle(10, 30, paddleWidth, paddleHeight)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, paddleWidth, paddleHeight)
    
    -- Ball
    ballSize = 4
    local fieldCenterX = VIRTUAL_WIDTH / 2 - math.floor(ballSize / 2)
    local fieldCenterY = ((GAME_BOUNDS_TOP - GAME_BOUNDS_BOT) / 2 - math.floor(ballSize / 2)) + GAME_BOUNDS_BOT
    ball = Ball(fieldCenterX, fieldCenterY, ballSize, ballSize)
   
    -- State
    gameState = "start"

end

-- Define keypress handling.
function love.keypressed(key)
    if key == "escape" then
        love.event.quit();
    end

    if key == "space" or key == "enter" or key == "return" then
        if gameState == "play" then
            gameState = "pause"
        elseif gameState == "pause" or gameState == "start" then
            gameState = "play"
        elseif gameState == "gameover" then
            player1score = 0
            player2score = 0
            gameState = "play"
        elseif gameState == "serve" then
            ball.dx = math.abs(ball.dx)
            if servingPlayer == 2 then
                ball.dx = ball.dx * -1
            end
            gameState = "play"
        end
    end

    if key == "r" then
        player1score = 0
        player2score = 0
        gameState = "start"
        ball:reset()
    end
end

-- Love2d runs this function each frame.
-- dt is the elapsed time in seconds since the last frame.
function love.update(dt)
    -- Paddles
    player1.dy = 0
    player2.dy = 0

    if love.keyboard.isDown("s") then 
        player1:setVelocity(PADDLE_SPEED)
    elseif love.keyboard.isDown("w") then 
        player1:setVelocity(-PADDLE_SPEED)
    end
    
    if love.keyboard.isDown("down") then 
        player2:setVelocity(PADDLE_SPEED)
    elseif love.keyboard.isDown("up") then 
        player2:setVelocity(-PADDLE_SPEED)
    end

    player1:update(dt)
    player2:update(dt)

    if gameState == "play" then
        -- Ball
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + player1.width

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
            sounds.paddle_hit:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - ball.width

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
            sounds.paddle_hit:play()
        end

        -- Bounce off walls
        if ball.y <= GAME_BOUNDS_TOP then
            ball.y = GAME_BOUNDS_TOP
            ball.dy = -ball.dy
            sounds.wall_hit:play()
        end

        if ball.y + ball.height >= GAME_BOUNDS_BOT then
            ball.y = GAME_BOUNDS_BOT - ball.height
            ball.dy = -ball.dy
            sounds.wall_hit:play()
        end

        -- Scoring
        if ball.x <= 0 then
            player2score = player2score + 1;
            servingPlayer = 1
            ball:reset()
            sounds.score:play()
            gameState = "serve"
        end
        if ball.x + ball.width > VIRTUAL_WIDTH then
            player1score = player1score + 1;
            servingPlayer = 2
            ball:reset()
            sounds.score:play()
            gameState = "serve"
        end

        if player1score >= 10 or player2score >= 10 then
            if servingPlayer == 1 then
                servingPlayer = 2
            else 
                servingPlayer = 1
            end
            gameState = "gameover"
            sounds.win:play()
        end

        ball:update(dt)
    end   

end

-- Love2d runs this after 'love.update()' to redraw the screen.
function love.draw()
    push:apply("start")
    love.graphics.clear(30/255, 34/255, 39/255, 1)    
    love.graphics.setColor(40/255, 45/255, 52/255, 1)
    love.graphics.rectangle("fill", 0, GAME_BOUNDS_TOP, VIRTUAL_WIDTH, GAME_BOUNDS_BOT - GAME_BOUNDS_TOP)
    love.graphics.setColor(1, 1, 1, 1)
    -- Title
    if gameState == "play" then
        banner = "Game on!"
    elseif gameState == "paused" then
        banner = "Paused"
    elseif gameState == "serve" then
        banner = "Player " .. tostring(servingPlayer) .. "'s Serve"
    elseif gameState == "gameover" then
        banner = "Player " .. tostring(servingPlayer) .. " Wins!"
    else
        banner = "Hello Pong!"
    end
    love.graphics.setFont(smallFont)
    love.graphics.printf(banner, 0, 0, VIRTUAL_WIDTH, "center")

    -- P1 & P2 Paddles
    player1:render()
    player2:render()

    -- Ball
    ball:render()

    -- Score
    if gameState == "play" then
        love.graphics.setFont(smallFont)
        love.graphics.print(tostring(player1score), VIRTUAL_WIDTH / 2 - 24, 25)
        love.graphics.print(tostring(player2score), VIRTUAL_WIDTH / 2 + 16, 25)
    else
        love.graphics.setFont(scoreFont)
        love.graphics.print(tostring(player1score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
        love.graphics.print(tostring(player2score), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)
    end

    displayFPS()
    push:apply("end")
end

function love.resize(w, h)
    push:resize(w, h)
end

function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 0)
end
