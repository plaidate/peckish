-- Controls: d-pad scurries, B sprints, A pecks, crank = broken-wing display.
-- The smoke autopilot forages worms, retreats from forecast waves, broods
-- eggs, lures gulls off its chicks - and deliberately blunders once into a
-- wave and a crab, sacrifices one chick, then starves itself to exercise
-- every failure path.

Input = {}

-- returns { mvx, mvy (-1/0/1), run, peck (bool), crank (deg) }
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end
    local mvx, mvy = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then mvx = -1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then mvx = 1 end
    if playdate.buttonIsPressed(playdate.kButtonUp) then mvy = -1 end
    if playdate.buttonIsPressed(playdate.kButtonDown) then mvy = 1 end
    return {
        mvx = mvx, mvy = mvy,
        run = playdate.buttonIsPressed(playdate.kButtonB),
        peck = playdate.buttonJustPressed(playdate.kButtonA),
        crank = playdate.getCrankChange(),
    }
end

function Input.confirm()
    if Harness.enabled then return G.t > 0.7 end
    return playdate.buttonJustPressed(playdate.kButtonA)
end

local function steer(inp, tx, ty, dead)
    local b = G.bird
    dead = dead or 6
    if math.abs(tx - b.x) > dead then inp.mvx = Util.sign(tx - b.x) end
    if math.abs(ty - b.y) > dead then inp.mvy = Util.sign(ty - b.y) end
end

Harness.autopilot = function()
    local inp = { mvx = 0, mvy = 0, run = false, peck = false, crank = 0 }
    if G.state ~= "play" then return inp end
    local b = G.bird
    local td = G.tide
    local cnt = Harness.counters
    local starving = G.playT > 100 -- staged failure: stop eating, exercise game over

    -- dodge a committed gull dive (always - even while starving)
    local gull = G.gull
    if gull and gull.state == "dive" then
        inp.run = true
        inp.mvx = (b.x < gull.cx) and -1 or 1
        inp.mvy = (b.y < gull.cy) and -1 or 1
        return inp
    end

    if starving then
        steer(inp, 40, 120) -- idle in the dunes and fade away
        return inp
    end

    -- once: stand in the surf to get tumbled
    if (cnt.tumbles or 0) == 0 and G.playT > 12 and td.state ~= "calm" then
        steer(inp, math.max(td.reach + 20, 200), b.y)
        return inp
    end

    -- once: walk into a crab to get pinched
    if (cnt.pinches or 0) == 0 and G.playT > 25 then
        for _, cr in ipairs(G.crabs) do
            if cr.flip <= 0 then
                steer(inp, cr.x, cr.y, 2)
                return inp
            end
        end
    end

    -- gull circling: sacrifice the first chick it wants, lure it ever after
    if gull and gull.state == "circle" then
        if gull.chick and (cnt.gullTakes or 0) == 0 then
            steer(inp, 60, 60)
        else
            inp.crank = 120
        end
        return inp
    end

    -- wave incoming: stay out of its forecast reach
    if td.state ~= "calm" and td.state ~= "recede" and b.x > td.reach - 24 then
        inp.run = b.energy > 30
        inp.mvx = -1
        return inp
    end

    -- brood the egg when nothing is urgent
    if G.egg and #G.chicks < C.MAX_FLOCK and b.energy > 45 then
        steer(inp, G.egg.x, G.egg.y, 3)
        return inp
    end

    -- hunt worms (prefer surfaced ones, avoid anything the next wave covers)
    local tx, ty, best
    for _, w in ipairs(G.worms) do
        local safe = td.state == "calm" or w.x < td.reach - 20
        if safe and w.x < td.edge - 6 then
            local d = Util.dist(b.x, b.y, w.x, w.y)
            local bias = (w.state == "up") and 0 or 60
            if not best or d + bias < best then
                best, tx, ty = d + bias, w.x, w.y
            end
        end
    end
    if tx then
        local d = Util.dist(b.x, b.y, tx, ty)
        if d < 12 then
            if math.abs(tx - b.x) > 2 then inp.mvx = Util.sign(tx - b.x) end
            if math.abs(ty - b.y) > 2 then inp.mvy = Util.sign(ty - b.y) end
            inp.peck = true
        else
            inp.run = d > 70 and b.energy > 35
            steer(inp, tx, ty, 3)
        end
        return inp
    end

    -- patrol mid-beach while the next meal brews
    steer(inp, 170 + math.sin(G.t * 0.6) * 60, 120 + math.cos(G.t * 0.4) * 60)
    return inp
end
