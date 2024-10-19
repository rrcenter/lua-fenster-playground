local fenster = require('fenster')

local width = 144
local height = 144
local window_scale = 4
local fps = 30

-- Constants
local TWO_PI = 6.28318530718
local N = 64
local MAX_STEP = 10
local MAX_DISTANCE = 2.0
local EPSILON = 1e-6

-- Distance function for a circle
local function circleSDF(x, y, cx, cy, r)
    local ux = x - cx
    local uy = y - cy
    return math.sqrt(ux * ux + uy * uy) - r
end

-- Plane SDF: Distance from point (x, y) to an infinite plane defined by point (px, py) and normal (nx, ny)
local function planeSDF(x, y, px, py, nx, ny)
    return (x - px) * nx + (y - py) * ny
end

-- Segment SDF: Distance from point (x, y) to a line segment from (ax, ay) to (bx, by)
local function segmentSDF(x, y, ax, ay, bx, by)
    local vx, vy = x - ax, y - ay
    local ux, uy = bx - ax, by - ay
    local t = math.max(math.min((vx * ux + vy * uy) / (ux * ux + uy * uy), 1.0), 0.0)
    local dx, dy = vx - ux * t, vy - uy * t
    return math.sqrt(dx * dx + dy * dy)
end

-- Capsule SDF: Distance from point (x, y) to a capsule (a segment with radius)
local function capsuleSDF(x, y, ax, ay, bx, by, r)
    return segmentSDF(x, y, ax, ay, bx, by) - r
end

-- Box SDF: Distance from point (x, y) to a rotated box centered at (cx, cy) with size (sx, sy) and rotation theta
local function boxSDF(x, y, cx, cy, theta, sx, sy)
    local costheta = math.cos(theta)
    local sintheta = math.sin(theta)
    local dx = math.abs((x - cx) * costheta + (y - cy) * sintheta) - sx
    local dy = math.abs((y - cy) * costheta - (x - cx) * sintheta) - sy
    local ax = math.max(dx, 0.0)
    local ay = math.max(dy, 0.0)
    return math.min(math.max(dx, dy), 0.0) + math.sqrt(ax * ax + ay * ay)
end

-- Triangle SDF: Distance from point (x, y) to a triangle defined by three vertices (ax, ay), (bx, by), (cx, cy)
local function triangleSDF(x, y, ax, ay, bx, by, cx, cy)
    local d = math.min(
        math.min(segmentSDF(x, y, ax, ay, bx, by), 
                 segmentSDF(x, y, bx, by, cx, cy)),
        segmentSDF(x, y, cx, cy, ax, ay)
    )
    
    -- Point is inside the triangle if all cross-products are positive
    local inside = (bx - ax) * (y - ay) > (by - ay) * (x - ax) and
                   (cx - bx) * (y - by) > (cy - by) * (x - bx) and
                   (ax - cx) * (y - cy) > (ay - cy) * (x - cx)
    
    return inside and -d or d
end

local sdfType = 1
local sdf = function (x,y )
    local sd
    if sdfType == 1 then
        sd = circleSDF(x, y, 0.5, 0.5, 0.05)
    elseif sdfType == 2 then
        sd = planeSDF(x, y, 0.5, 0.5, 0.0, 1.0)
    elseif sdfType == 3 then
        sd = boxSDF(x, y, 0.5, 0.5, TWO_PI/16.0, 0.3, 0.1)
    elseif sdfType == 4 then
        sd = triangleSDF(x, y, 0.5, 0.2, 0.8, 0.8, 0.3, 0.6)
    elseif sdfType == 5 then
        sd = capsuleSDF(x, y, 0.4, 0.4, 0.6, 0.6, 0.1)
    else
        sd = circleSDF(x, y, 0.5, 0.5, 0.1)
    end
    return sd
end

-- Ray marching function
local function trace(ox, oy, dx, dy)
    local t = 0.0
    for i = 1, MAX_STEP do
        local x = ox + dx * t
        local y = oy + dy * t
        local sd = sdf(x, y)
        if sd < EPSILON then
            return 2.0 -- hit
        end
        t = t + sd
        if t >= MAX_DISTANCE then
            break
        end
    end
    return 0.0 -- miss
end

-- Sampling function
local function sample(x, y)
    local sum = 0.0
    for i = 1, N do
        local a = TWO_PI * (i + math.random()) / N
        local dx = math.cos(a)
        local dy = math.sin(a)
        sum = sum + trace(x, y, dx, dy)
    end
    return sum / N
end

-- Main function to draw the image
local function draw(window)
    for y = 0, width - 1 do
        for x = 0, height - 1 do
            local brightness = math.min(math.floor(sample(x / width, y / height) * 255), 255)
            local color = fenster.rgb(brightness, brightness, brightness)
            window:set(x, y, color)
        end
    end
end

local keys = require('keys')
local function main()
    local window = fenster.open(width, height, 'Light 2D! 1/2/3/4/5', window_scale, fps)
    local function ispress(key)
        return window.keys[keys[tostring(key)]]
    end

    while window:loop() and not ispress('escape') do
        window:clear()

        for _, value in ipairs({1,2,3,4,5}) do
            if ispress(value) then
                sdfType = value
                break
            end
        end

         draw(window)
    end
end

main()
