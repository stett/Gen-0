local canvas = love.graphics.newCanvas(3000, 1500, 'normal', 16)
local palette = love.graphics.newImage('palette.png')--newCanvas(32, 2)

local brush = {
    position = {x=0, y=0},
    velocity = {x=0, y=0},
    acceleration = {x=0, y=0},
    mass = .5,
    target = {x=0, y=0},
    width = 10,
    polygon = {a={x=0, y=0}, b={x=0, y=0}, c={x=0, y=0}, d={x=0, y=0}},
    polygon_smear = {a={x=0, y=0}, b={x=0, y=0}, c={x=0, y=0}, d={x=0, y=0}},
    color = {},
    color_smear = {0, 0, 0},
    alpha = 255,
    palette = {x=0, y=0}
}

local finished = false


function set_polygon(polygon, x0, y0, x1, y1, x2, y2, x3, y3)
    polygon.a.x = x0
    polygon.b.x = x1
    polygon.c.x = x2
    polygon.d.x = x3
    polygon.a.y = y0
    polygon.b.y = y1
    polygon.c.y = y2
    polygon.d.y = y3
end


function randomize_position()
    px = -canvas:getWidth() + math.random(2 * canvas:getWidth())
    py = -canvas:getHeight() + math.random(2 * canvas:getHeight())
    brush.position.x = px
    brush.position.y = py
    set_polygon(brush.polygon, px, py, px, py, px, py, px, py)
    set_polygon(brush.polygon_smear, px, py, px, py, px, py, px, py)
end


function love.load()
    love.window.setMode(0, 0, {fullscreen=true})

    -- Set the seed
    --math.randomseed(1)
    math.randomseed(2)

    -- Set initial random target
    brush.target.x = math.random(canvas:getWidth())
    brush.target.y = math.random(canvas:getHeight())

    -- Set initial random position
    randomize_position()
end


function love.update(dt)

    -- Make a custom dt
    local DT = .8

    -- Don't paint if we're finished
    if finished == true then
        return
    end

    -- Increment the palette position
    brush.palette.x = brush.palette.x + DT * .1
    if math.floor(brush.palette.x) >= palette:getWidth() then
        brush.palette.x = 0
        brush.palette.y = brush.palette.y + 1

        if brush.palette.y >= palette:getHeight() then
            finished = true
            return
        end
    end

    -- Get the first two corners of the polygon to draw.
    -- They should be the second two corners from the previous iteration
    brush.polygon.a.x = brush.polygon.d.x
    brush.polygon.a.y = brush.polygon.d.y
    brush.polygon.b.x = brush.polygon.c.x
    brush.polygon.b.y = brush.polygon.c.y
    brush.polygon_smear.a.x = brush.polygon_smear.d.x
    brush.polygon_smear.a.y = brush.polygon_smear.d.y
    brush.polygon_smear.b.x = brush.polygon_smear.c.x
    brush.polygon_smear.b.y = brush.polygon_smear.c.y

    -- Accelerate the brush toward the target
    local diff = {
        x = brush.position.x - brush.target.x,
        y = brush.position.y - brush.target.y}
    local acc_mag = 50 * brush.mass / math.sqrt(diff.x * diff.x + diff.y * diff.y)
    brush.acceleration.x = -diff.x * acc_mag
    brush.acceleration.y = -diff.y * acc_mag

    -- Get the magnitude and normal vector of the velocity
    local vel_mag = math.sqrt(brush.velocity.x * brush.velocity.x + brush.velocity.y * brush.velocity.y)
    local vel_n = {
        x = brush.velocity.x / vel_mag,
        y = brush.velocity.y / vel_mag}

    -- Apply drag
    --[[
    local drag = {
        x = -vel_n.x * .01,
        y = -vel_n.y * .01}
    brush.acceleration.x = brush.acceleration.x + drag.x
    brush.acceleration.y = brush.acceleration.y + drag.y
    ]]

    -- Update the velocity
    brush.velocity.x = brush.velocity.x + brush.acceleration.x * DT
    brush.velocity.y = brush.velocity.y + brush.acceleration.y * DT

    -- Update the position
    brush.position.x = brush.position.x + brush.velocity.x * DT
    brush.position.y = brush.position.y + brush.velocity.y * DT

    -- Update the drawing properties
    brush.width = math.min(2000, 100000 / (vel_mag * vel_mag))
    brush.alpha = math.min(255, 5 * vel_mag)

    -- Get the color from the palette
    local data = palette:getData()
    r, g, b, a = data:getPixel(math.floor(brush.palette.x), math.floor(brush.palette.y))
    brush.color = {r, g, b}

    -- Get the color to smear (under the brush)
    if 5 * math.random() < 1 and
       brush.position.x >= 0 and brush.position.x < canvas:getWidth() and
       brush.position.y >= 0 and brush.position.y < canvas:getHeight() then
        r, g, b, a = canvas:getPixel(brush.position.x, brush.position.y)
        brush.color_smear = {
            (brush.color_smear[1] + r) * .5,
            (brush.color_smear[2] + g) * .5,
            (brush.color_smear[3] + b) * .5}
    end

    -- Get the current 2 brush edge points
    local n = {
        x =  vel_n.y,
        y = -vel_n.x}
    brush.polygon.c.x = brush.position.x + n.x * brush.width / 2
    brush.polygon.c.y = brush.position.y + n.y * brush.width / 2
    brush.polygon.d.x = brush.position.x - n.x * brush.width / 2
    brush.polygon.d.y = brush.position.y - n.y * brush.width / 2

    -- Get the smear edge points
    brush.polygon_smear.c.x = brush.position.x + n.x * brush.width / 2.1
    brush.polygon_smear.c.y = brush.position.y + n.y * brush.width / 2.1
    brush.polygon_smear.d.x = brush.position.x
    brush.polygon_smear.d.y = brush.position.y

    -- Update target (maybe)
    if math.random(1 * vel_mag / DT) <= 1 then
        brush.target.x = math.random(canvas:getWidth())
        brush.target.y = math.random(canvas:getHeight())
    end

    -- Slow down randomly... sometimes we get too fast
    if math.random(2000 / (DT * vel_mag)) <= 1 then
        local r = math.random()
        brush.velocity.x = brush.velocity.x * r
        brush.velocity.y = brush.velocity.y * r
    end

    --
    local r = math.random() * 3
    if r < 2 then
        love.graphics.setBlendMode('alpha')
    elseif r < 2.8 then
        love.graphics.setBlendMode('additive')
    elseif r < 3 then
        love.graphics.setBlendMode('multiplicative')
    end
end


function love.draw()

    -- Set the border size
    local border = 10

    -- Paint to the canvas if we're not finished
    if not finished then
        love.graphics.setCanvas(canvas)

        -- Draw the main brush section
        love.graphics.setColor(brush.color[1], brush.color[2], brush.color[3], brush.alpha)
        love.graphics.polygon(
            'fill',
            brush.polygon.a.x, brush.polygon.a.y,
            brush.polygon.b.x, brush.polygon.b.y,
            brush.polygon.c.x, brush.polygon.c.y,
            brush.polygon.d.x, brush.polygon.d.y)

        -- Draw the smear brush section
        love.graphics.setColor(brush.color_smear[1], brush.color_smear[2], brush.color_smear[3], brush.alpha)
        love.graphics.polygon(
            'fill',
            brush.polygon_smear.a.x, brush.polygon_smear.a.y,
            brush.polygon_smear.b.x, brush.polygon_smear.b.y,
            brush.polygon_smear.c.x, brush.polygon_smear.c.y,
            brush.polygon_smear.d.x, brush.polygon_smear.d.y)

        love.graphics.setCanvas()
        love.graphics.setColor(255, 255, 255, 255)

        --
    end

    love.graphics.setBlendMode('alpha')

    -- Get the scale at which to draw the canvas
    local scale = math.min(
        (love.graphics.getWidth() - 2 * border) / (canvas:getWidth()),
        (love.graphics.getHeight() - 2 * border) / (canvas:getHeight()))

    -- Render the canvas to the screen
    love.graphics.draw(canvas, border, border, 0, scale, scale)
    love.graphics.rectangle('line', border, border, canvas:getWidth() * scale, canvas:getHeight() * scale)

    -- Render the palette
    local palette_pos = {x=2*border, y=2*border}
    love.graphics.draw(palette, palette_pos.x, palette_pos.y)
    love.graphics.line(
        palette_pos.x + brush.palette.x, palette_pos.y + brush.palette.y,
        palette_pos.x + brush.palette.x, palette_pos.y + brush.palette.y + 10)
    love.graphics.rectangle(
        'line',
        palette_pos.x - 1, palette_pos.y - 1,
        palette:getWidth() + 2,
        palette:getHeight() + 2)
    love.graphics.setColor(brush.color[1], brush.color[2], brush.color[3], 255)--brush.alpha)
    love.graphics.circle(
        'fill',
        palette_pos.x + brush.palette.x,
        palette_pos.y + brush.palette.y + 15, 5)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.circle(
        'line',
        palette_pos.x + brush.palette.x,
        palette_pos.y + brush.palette.y + 15, 5)

    -- Draw the frames per second
    local str = "FPS: " .. tostring(love.timer.getFPS( ))
    if finished then
        str = str .. '  [FINISHED]'
    end
    love.graphics.print(str, 3 * border + palette:getWidth(), 2 * border)
end


function love.keypressed(key, isrepeat)
    if key == 'escape' then
        love.event.quit()
    elseif key == ' ' then
        local i = 0
        local fname = 'out-' .. tostring(i) .. '.bmp'
        while love.filesystem.exists(fname) do
            i = i + 1
            fname = 'out-' .. tostring(i) .. '.bmp'
        end
        canvas:getImageData():encode(fname)
    end
end