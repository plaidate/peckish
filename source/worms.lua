-- Worm spots. Each bubbles for a moment, then the worm surfaces for a short
-- window. Wet-sand worms (in the band the last wave left) are worth more.
-- A receding wave spawns a rich burst right behind it. Chicks in the flock
-- snap up worms they walk over (half the energy goes to the player).

Worms = {}

local function spawnSpot(x, y, bubbleT)
    G.worms[#G.worms + 1] = {
        x = x, y = y,
        state = "bubble",
        t = bubbleT or C.WORM_BUBBLE,
        wet = x >= G.tide.wetX - 4,
    }
end

function Worms.reset()
    G.worms = {}
    G.wormTimer = 1.2
end

function Worms.burst(reach)
    for _ = 1, C.BURST_N do
        local x = reach + 6 + math.random() * math.max(10, C.SHORE_X - 20 - reach)
        local y = 30 + math.random() * (C.H - 40)
        spawnSpot(x, y, 0.4 + math.random() * 1.0)
    end
end

function Worms.update(dt)
    local td = G.tide

    G.wormTimer = G.wormTimer - dt
    if G.wormTimer <= 0 and #G.worms < C.WORM_CAP then
        G.wormTimer = C.WORM_INT - G.diff * 0.5 + math.random() * 0.8
        local x
        if math.random() < 0.6 and td.wetX < C.SHORE_X - 24 then
            x = td.wetX + math.random() * (C.SHORE_X - 14 - td.wetX)
        else
            x = C.DUNE_X + 15 + math.random() * (C.SHORE_X - 105 - C.DUNE_X)
        end
        local y = 30 + math.random() * (C.H - 40)
        if x < td.edge - 10 then spawnSpot(x, y) end
    end

    for i = #G.worms, 1, -1 do
        local w = G.worms[i]
        w.t = w.t - dt
        if w.x > td.edge - 2 then
            table.remove(G.worms, i) -- drowned under the wave
        elseif w.t <= 0 then
            if w.state == "bubble" then
                w.state = "up"
                w.t = C.WORM_UP
            else
                table.remove(G.worms, i)
            end
        end
    end

    -- chicks snap up worms they walk over
    for i = #G.worms, 1, -1 do
        local w = G.worms[i]
        if w.state == "up" then
            for _, c in ipairs(G.chicks) do
                if Util.dist(c.x, c.y, w.x, w.y) < 9 then
                    table.remove(G.worms, i)
                    Bird.eat(w.wet and C.WORM_E_WET or C.WORM_E_DRY, true)
                    local pts = Game.addScore(w.wet and C.PTS_WORM_WET or C.PTS_WORM_DRY)
                    Fx.text("+" .. pts, w.x, w.y - 10)
                    Harness.count("chickEats")
                    Sfx.gulp()
                    break
                end
            end
        end
    end
end

-- peck at (px,py): eat the nearest surfaced worm in reach. Returns true if fed.
function Worms.tryPeck(px, py, r)
    local best, bi
    for i, w in ipairs(G.worms) do
        if w.state == "up" then
            local d = Util.dist(px, py, w.x, w.y)
            if d < r and (not best or d < best) then
                best, bi = d, i
            end
        end
    end
    if not bi then return false end
    local w = table.remove(G.worms, bi)
    Bird.eat(w.wet and C.WORM_E_WET or C.WORM_E_DRY)
    local pts = Game.addScore(w.wet and C.PTS_WORM_WET or C.PTS_WORM_DRY)
    Fx.text("+" .. pts, w.x, w.y - 10)
    Fx.puff(w.x, w.y, 3)
    Harness.count("wormsEaten")
    Sfx.gulp()
    return true
end
