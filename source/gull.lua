-- The gull. Circles as a shadow over its mark (it prefers chicks), then
-- dives at a committed point. Cranking the broken-wing display while it
-- circles lures it onto the player instead - sprint clear as it commits
-- and it grabs nothing but sand (bonus points).

Gull = {}

function Gull.reset()
    G.gull = nil
    G.gullTimer = C.GULL_FIRST
end

local function chickAlive(c)
    for _, x in ipairs(G.chicks) do
        if x == c then return true end
    end
    return false
end

function Gull.update(dt)
    local b = G.bird
    local g = G.gull

    if not g then
        G.gullTimer = G.gullTimer - dt
        if G.gullTimer <= 0 then
            local target = nil
            if #G.chicks > 0 and math.random() < 0.75 then
                target = G.chicks[math.random(#G.chicks)]
            end
            G.gull = { state = "circle", t = 0, chick = target,
                       x = -20, y = 40, lured = false }
            Sfx.screech()
        end
        return
    end

    g.t = g.t + dt
    if g.state == "circle" then
        -- the broken-wing act pulls its eye onto the player
        if b.display then
            g.chick = nil
            g.lured = true
        end
        if g.chick and not chickAlive(g.chick) then g.chick = nil end
        local tx, ty
        if g.chick then tx, ty = g.chick.x, g.chick.y else tx, ty = b.x, b.y end
        local a = g.t * 3.4
        local gx = tx + math.cos(a) * 34
        local gy = ty + math.sin(a) * 20
        g.x = g.x + (gx - g.x) * math.min(1, dt * 4)
        g.y = g.y + (gy - g.y) * math.min(1, dt * 4)
        if g.t > C.GULL_CIRCLE_T then
            g.state = "dive"
            g.t = 0
            if g.chick then g.cx, g.cy = g.chick.x, g.chick.y
            else g.cx, g.cy = b.x, b.y end
            g.sx, g.sy = g.x, g.y
            Sfx.dive()
        end
    elseif g.state == "dive" then
        local k = math.min(1, g.t / C.GULL_DIVE_T)
        g.x = Util.lerp(g.sx, g.cx, k)
        g.y = Util.lerp(g.sy, g.cy, k)
        if k >= 1 then
            local hit = false
            for i = #G.chicks, 1, -1 do
                local c = G.chicks[i]
                if Util.dist(c.x, c.y, g.cx, g.cy) < C.GULL_HIT_R then
                    table.remove(G.chicks, i)
                    hit = true
                    Harness.count("gullTakes")
                    Fx.text("TAKEN!", c.x - 16, c.y - 12)
                    Sfx.taken()
                    break
                end
            end
            if not hit and b.tumble <= 0
                and Util.dist(b.x, b.y, g.cx, g.cy) < C.GULL_HIT_R then
                hit = true
                b.stun = C.GULL_STUN
                Harness.count("gullHits")
                Fx.text("HIT!", b.x, b.y - 14)
                Sfx.taken()
                Bird.damage(C.GULL_COST, "CARRIED OFF BY A GULL")
                if G.state ~= "play" then return end
            end
            if not hit and g.lured then
                local pts = Game.addScore(C.PTS_LURE)
                Fx.text("LURED AWAY! +" .. pts, g.cx - 30, g.cy - 10)
                Harness.count("lures")
                Sfx.blip(1200)
            end
            Fx.puff(g.cx, g.cy, 5)
            g.state = "leave"
            g.t = 0
        end
    elseif g.state == "leave" then
        g.x = g.x + 170 * dt
        g.y = g.y - 90 * dt
        if g.t > 1.2 then
            G.gull = nil
            G.gullTimer = C.GULL_INT - G.diff * 8 + math.random() * 6
        end
    end
end
