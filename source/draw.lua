-- All rendering: the beach, the sea, every creature, HUD and screens.
-- 1-bit style: white sand, patterned water, black-outlined white birds.

local gfx <const> = playdate.graphics

Draw = {}

local PAT_WATER <const> = { 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA }
local PAT_DEEP <const> = { 0x11, 0x44, 0x11, 0x44, 0x11, 0x44, 0x11, 0x44 }
local PAT_WET <const> = { 0xFF, 0xBB, 0xFF, 0xFF, 0xFF, 0xEE, 0xFF, 0xFF }

function Draw.init()
    Draw.sand = {}
    for i = 1, 70 do
        Draw.sand[i] = { C.DUNE_X + 4 + math.random(0, C.SHORE_X - C.DUNE_X - 12), math.random(0, C.H) }
    end
    Draw.grass = {}
    for i = 1, 14 do
        Draw.grass[i] = { math.random(6, C.DUNE_X - 8), math.random(10, C.H - 4) }
    end
end

-- ---- terrain ----------------------------------------------------------------

function Draw.beach()
    local td = G.tide
    -- wet band left by the last wave
    if td.wetX < C.SHORE_X - 2 then
        gfx.setPattern(PAT_WET)
        gfx.fillRect(td.wetX, 0, C.W - td.wetX, C.H)
        gfx.setColor(gfx.kColorBlack)
    end
    -- sand speckles
    for _, d in ipairs(Draw.sand) do
        gfx.fillRect(d[1], d[2], 1, 1)
    end
    -- dune boundary and grass tufts
    for y = 0, C.H, 8 do
        gfx.fillRect(C.DUNE_X, y, 1, 4)
    end
    for _, gr in ipairs(Draw.grass) do
        local gx, gy = gr[1], gr[2]
        gfx.drawLine(gx, gy, gx - 3, gy - 5)
        gfx.drawLine(gx, gy, gx, gy - 6)
        gfx.drawLine(gx, gy, gx + 3, gy - 5)
    end
end

function Draw.water()
    local td = G.tide
    local e = td.edge
    -- last high-water mark
    for y = 0, C.H, 6 do
        gfx.fillRect(td.wetX + math.sin(y * 0.25) * 2, y, 1, 2)
    end
    -- the sea
    gfx.setPattern(PAT_WATER)
    gfx.fillRect(e, 0, C.W - e, C.H)
    local dx = math.max(e + 30, C.SHORE_X + 45)
    if dx < C.W then
        gfx.setPattern(PAT_DEEP)
        gfx.fillRect(dx, 0, C.W - dx, C.H)
    end
    -- scalloped foam edge
    gfx.setColor(gfx.kColorWhite)
    for y = 0, C.H, 10 do
        local off = math.sin(y * 0.12 + G.t * 3) * 3
        gfx.fillRect(e + off - 2, y, 6, 10)
    end
    gfx.setColor(gfx.kColorBlack)
    for y = 5, C.H, 10 do
        local off = math.sin(y * 0.12 + G.t * 3) * 3
        gfx.fillRect(e + off - 2, y, 1, 1)
    end
    -- whitecaps rolling in
    gfx.setColor(gfx.kColorWhite)
    for i = 1, 3 do
        local wx = e + 22 + i * 24 + math.sin(G.t * 1.4 + i * 2) * 7
        if wx < C.W - 4 then
            for y = 0, C.H - 10, 18 do
                local yy = y + (i * 6) % 18
                gfx.drawLine(wx, yy, wx - 3, yy + 7)
            end
        end
    end
    gfx.setColor(gfx.kColorBlack)
end

-- ---- creatures --------------------------------------------------------------

-- b needs x, y, face; optional vx/vy/peckT/display/tumble
function Draw.bird(b)
    local x, y = b.x, b.y
    local ang = b.face or 0
    if (b.tumble or 0) > 0 then ang = ang + G.t * 20 end
    local ca, sa = math.cos(ang), math.sin(ang)
    -- scurrying legs
    local spd = math.sqrt((b.vx or 0) ^ 2 + (b.vy or 0) ^ 2)
    if spd > 12 then
        local ph = math.sin(G.t * 24) * 3
        gfx.fillRect(x - sa * 4 + ca * ph - 1, y + ca * 4 + sa * ph - 1, 2, 2)
        gfx.fillRect(x + sa * 4 - ca * ph - 1, y - ca * 4 - sa * ph - 1, 2, 2)
    end
    -- body (rotated ellipse)
    local body = {}
    for i = 0, 7 do
        local t = i * math.pi / 4
        local ex, ey = math.cos(t) * 8, math.sin(t) * 5
        body[#body + 1] = x + ex * ca - ey * sa
        body[#body + 1] = y + ex * sa + ey * ca
    end
    gfx.setColor(gfx.kColorWhite)
    gfx.fillPolygon(table.unpack(body))
    gfx.setColor(gfx.kColorBlack)
    gfx.drawPolygon(table.unpack(body))
    -- tail feathers
    gfx.drawLine(x - ca * 8, y - sa * 8, x - ca * 13 - sa * 2, y - sa * 13 + ca * 2)
    gfx.drawLine(x - ca * 8, y - sa * 8, x - ca * 13 + sa * 2, y - sa * 13 - ca * 2)
    -- head
    local hx, hy = x + ca * 9, y + sa * 9
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(hx, hy, 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(hx, hy, 4)
    gfx.fillRect(hx - sa * 2 - 0.5, hy + ca * 2 - 0.5, 1.5, 1.5)
    gfx.fillRect(hx + sa * 2 - 0.5, hy - ca * 2 - 0.5, 1.5, 1.5)
    -- beak (stretches mid-peck)
    local bl = (b.peckT or 0) > 0 and 9 or 5
    gfx.setLineWidth(2)
    gfx.drawLine(hx + ca * 3, hy + sa * 3, hx + ca * (3 + bl), hy + sa * (3 + bl))
    -- the killdeer's two black breast bands
    for _, off in ipairs({ 4, 6.5 }) do
        local w = off < 5 and 4.5 or 3.5
        local bx, by = x + ca * off, y + sa * off
        gfx.drawLine(bx - sa * w, by + ca * w, bx + sa * w, by - ca * w)
    end
    gfx.setLineWidth(1)
    -- broken-wing display: one wing dragged out, fluttering
    if b.display then
        for i = -1, 1 do
            local wa = ang + 2.5 + i * 0.3 + math.sin(G.t * 30) * 0.15
            gfx.drawLine(x, y, x + math.cos(wa) * 14, y + math.sin(wa) * 14)
        end
    end
end

function Draw.player()
    local b = G.bird
    if b.stun > 0 and math.floor(G.t * 12) % 2 == 1 then return end
    Draw.bird(b)
    if b.tumble > 0 then
        gfx.setColor(gfx.kColorWhite)
        for i = 1, 3 do
            gfx.fillCircleAtPoint(b.x + math.cos(G.t * 7 + i * 2.1) * 10,
                b.y + math.sin(G.t * 7 + i * 2.1) * 7, 3)
        end
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(b.x, b.y, 11)
    end
end

function Draw.chick(c)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(c.x, c.y, 3.5)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(c.x, c.y, 3.5)
    gfx.drawLine(c.x - 3, c.y - 0.5, c.x + 3, c.y - 0.5) -- chicks wear ONE band
    gfx.fillRect(c.x + 1, c.y - 2.5, 1, 1)
end

function Draw.flock()
    for _, c in ipairs(G.chicks) do
        Draw.chick(c)
    end
end

function Draw.worms()
    for _, w in ipairs(G.worms) do
        if w.state == "bubble" then
            if math.floor(w.t * 8) % 2 == 0 then
                gfx.drawCircleAtPoint(w.x + 2, w.y, 1.5)
                gfx.drawCircleAtPoint(w.x - 2, w.y + 2, 1)
            end
        else
            local blink = w.t < 0.5 and math.floor(G.t * 10) % 2 == 1
            if not blink then
                local ph = G.t * 10 + w.x
                gfx.setLineWidth(2)
                local px, py = w.x, w.y
                for s = 1, 3 do
                    local nx = w.x + math.sin(ph + s * 1.8) * 2.5
                    local ny = w.y - s * 2.4
                    gfx.drawLine(px, py, nx, ny)
                    px, py = nx, ny
                end
                gfx.setLineWidth(1)
                gfx.fillCircleAtPoint(px, py, 1.5)
            end
        end
    end
end

function Draw.crabs()
    for _, cr in ipairs(G.crabs) do
        if cr.flip > 0 then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillEllipseInRect(cr.x - 6, cr.y - 4, 12, 8)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawEllipseInRect(cr.x - 6, cr.y - 4, 12, 8)
            local w = math.sin(G.t * 16) * 2
            for i = -1, 1 do
                gfx.drawLine(cr.x + i * 3, cr.y - 3, cr.x + i * 3 + w, cr.y - 8)
            end
        else
            local ca, sa = math.cos(cr.ang), math.sin(cr.ang)
            gfx.fillEllipseInRect(cr.x - 6, cr.y - 4, 12, 8)
            gfx.fillCircleAtPoint(cr.x + ca * 7 - sa * 4, cr.y + sa * 7 + ca * 4, 2.5)
            gfx.fillCircleAtPoint(cr.x + ca * 7 + sa * 4, cr.y + sa * 7 - ca * 4, 2.5)
            local lw = math.sin(G.t * 12 + cr.x) * 1.5
            for i = -1, 1, 2 do
                gfx.drawLine(cr.x - 4, cr.y + i * 3, cr.x - 7 + lw, cr.y + i * 6)
                gfx.drawLine(cr.x, cr.y + i * 4, cr.x + lw, cr.y + i * 7)
                gfx.drawLine(cr.x + 4, cr.y + i * 3, cr.x + 7 - lw, cr.y + i * 6)
            end
        end
    end
end

function Draw.gull()
    local g = G.gull
    if not g then return end
    local h
    if g.state == "circle" then
        h = 26
    elseif g.state == "dive" then
        h = 26 * (1 - math.min(1, g.t / C.GULL_DIVE_T))
    else
        h = 26 * math.min(1, g.t) + 4
    end
    -- ground shadow
    gfx.setPattern(PAT_WATER)
    local sw = 10 + h * 0.4
    gfx.fillEllipseInRect(g.x - sw / 2, g.y - 4, sw, 8)
    gfx.setColor(gfx.kColorBlack)
    -- the gull itself
    local gy = g.y - h
    local flap = (g.state == "dive") and 2 or math.sin(G.t * 9) * 4
    gfx.setLineWidth(2)
    gfx.drawLine(g.x - 11, gy - flap, g.x, gy)
    gfx.drawLine(g.x, gy, g.x + 11, gy - flap)
    gfx.setLineWidth(1)
    gfx.fillCircleAtPoint(g.x, gy, 2)
end

function Draw.jogger()
    local j = G.jogger
    if not j then return end
    if j.state == "warn" then
        if math.floor(G.t * 8) % 2 == 0 then
            local wy = j.dir == 1 and 28 or C.H - 12
            gfx.drawTextAligned("*!*", j.x, wy, kTextAlignment.center)
        end
        return
    end
    local swing = math.sin(j.y * 0.2) * 4
    gfx.fillCircleAtPoint(j.x - 11, j.y + swing, 2.5)
    gfx.fillCircleAtPoint(j.x + 11, j.y - swing, 2.5)
    gfx.fillEllipseInRect(j.x - 9, j.y - 4, 18, 9)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(j.x, j.y, 3.5)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(j.x, j.y, 3.5)
end

function Draw.egg()
    local e = G.egg
    if not e then return end
    if e.life < 3 and math.floor(G.t * 6) % 2 == 1 then return end
    gfx.drawCircleAtPoint(e.x, e.y, 12)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillEllipseInRect(e.x - 4, e.y - 5, 8, 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawEllipseInRect(e.x - 4, e.y - 5, 8, 10)
    gfx.fillRect(e.x - 1, e.y - 2, 1, 1)
    gfx.fillRect(e.x + 1, e.y + 1, 1, 1)
    if e.prog > 0 then
        gfx.setLineWidth(2)
        gfx.drawArc(e.x, e.y, 16, 0, 360 * e.prog / C.EGG_HATCH)
        gfx.setLineWidth(1)
    end
end

-- ---- HUD and screens --------------------------------------------------------

function Draw.hud()
    local b = G.bird
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(4, 3, 96, 12)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(4, 3, 96, 12)
    if b.energy > 22 or math.floor(G.t * 6) % 2 == 0 then
        gfx.fillRect(6, 5, 92 * b.energy / C.ENERGY_MAX, 8)
    end
    for i = 1, #G.chicks do
        gfx.drawCircleAtPoint(108 + i * 10, 9, 3)
    end
    gfx.drawTextAligned("*" .. G.score .. "*", 396, 3, kTextAlignment.right)
    if #G.chicks > 0 then
        gfx.drawTextAligned("x" .. string.format("%.2f", Game.mult()),
            396, 20, kTextAlignment.right)
    end
    local td = G.tide
    if td.state == "warn" or td.state == "surge" then
        if math.floor(G.t * 8) % 2 == 0 then
            gfx.drawTextAligned(td.sneaker and "*BIG WAVE!*" or "*WAVE!*",
                230, 3, kTextAlignment.center)
        end
    end
end

function Draw.play()
    gfx.clear(gfx.kColorWhite)
    Draw.beach()
    Draw.worms()
    Draw.egg()
    Draw.crabs()
    Draw.jogger()
    Draw.water()
    Draw.flock()
    Draw.player()
    Draw.gull()
    Fx.draw()
    Draw.hud()
end

function Draw.readyOverlay()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(110, 96, 180, 46, 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(110, 96, 180, 46, 4)
    gfx.drawTextAligned("*GET READY!*", 200, 104, kTextAlignment.center)
    gfx.drawTextAligned("peck worms, dodge the surf", 200, 122, kTextAlignment.center)
end

function Draw.title()
    gfx.clear(gfx.kColorWhite)
    Draw.beach()
    Draw.water()
    if not Draw.titleImg then
        local img = gfx.image.new(64, 18)
        gfx.pushContext(img)
        gfx.drawTextAligned("*PECKISH*", 32, 0, kTextAlignment.center)
        gfx.popContext()
        Draw.titleImg = img
    end
    Draw.titleImg:drawScaled(104, 12, 3)
    gfx.drawTextAligned("a killdeer on the tideline", 200, 68, kTextAlignment.center)
    Draw.bird({ x = 90, y = 74, face = -0.35, vx = 20, vy = 0 })
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(52, 92, 296, 112, 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(52, 92, 296, 112, 4)
    local lines = {
        "D-PAD scurry    hold B sprint",
        "A peck    crank the broken-wing act",
        "Worms feed you - sprinting burns energy",
        "Dodge waves, crabs, gulls and joggers",
        "Sit on dune eggs to hatch your flock",
        "HIGH SCORE  " .. G.high,
    }
    for i, s in ipairs(lines) do
        gfx.drawTextAligned(s, 200, 84 + i * 17, kTextAlignment.center)
    end
    if math.floor(G.t * 2) % 2 == 0 then
        gfx.drawTextAligned("*PRESS A*", 200, 214, kTextAlignment.center)
    end
end

function Draw.gameover()
    gfx.clear(gfx.kColorWhite)
    Draw.beach()
    Draw.water()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(80, 74, 240, 92, 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(80, 74, 240, 92, 4)
    local reason = G.overReason ~= "" and G.overReason or "GAME OVER"
    gfx.drawTextAligned("*" .. reason .. "*", 200, 84, kTextAlignment.center)
    gfx.drawTextAligned("SCORE  " .. G.score, 200, 110, kTextAlignment.center)
    gfx.drawTextAligned("BEST  " .. G.high, 200, 128, kTextAlignment.center)
    if G.t > 1 and math.floor(G.t * 2) % 2 == 0 then
        gfx.drawTextAligned("*PRESS A*", 200, 148, kTextAlignment.center)
    end
end
