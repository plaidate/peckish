-- The tide. Waves surge in from the right on a timer: calm -> warn (foam
-- gathers, warning sound) -> surge -> hold -> recede -> calm. Anything left
-- of the water's edge is dry; the player caught in a surge is tumbled, and
-- flock chicks are washed away. Each receding wave leaves a wet band that
-- sprouts a burst of worms.

Waves = {}

function Waves.reset()
    G.tide = {
        state = "calm",
        t = 0,
        lap = 0,
        edge = C.SHORE_X,          -- water covers x > edge
        base = C.SHORE_X,
        reach = C.SHORE_X,
        sneaker = false,
        wetX = C.SHORE_X - 24,     -- left extent of the wet band
        count = 0,
        nextIn = C.WAVE_FIRST,
    }
end

function Waves.update(dt)
    local td = G.tide
    td.t = td.t + dt
    td.lap = td.lap + dt

    if td.state == "calm" then
        td.edge = td.base + math.sin(td.lap * 1.4) * 5
        td.nextIn = td.nextIn - dt
        if td.nextIn <= 0 then
            td.state = "warn"
            td.t = 0
            local minR = C.SHORE_X - (60 + G.diff * 70)
            td.reach = minR + math.random() * 40
            td.sneaker = math.random() < 0.12 + G.diff * 0.1
            if td.sneaker then td.reach = td.reach - C.SNEAKER_EXTRA end
            Sfx.waveWarn()
        end
    elseif td.state == "warn" then
        -- the water pulls back a touch before it comes
        td.edge = td.base + 6 + math.sin(td.t * 18) * 3
        if td.t > C.WAVE_WARN then
            td.state = "surge"
            td.t = 0
            Sfx.waveCrash()
        end
    elseif td.state == "surge" then
        local k = math.min(1, td.t / C.WAVE_SURGE_T)
        td.edge = Util.lerp(td.base + 6, td.reach, 1 - (1 - k) * (1 - k))
        if k >= 1 then
            td.state = "hold"
            td.t = 0
        end
    elseif td.state == "hold" then
        td.edge = td.reach + math.sin(td.t * 9) * 2
        if td.t > C.WAVE_HOLD then
            td.state = "recede"
            td.t = 0
        end
    elseif td.state == "recede" then
        local k = math.min(1, td.t / C.WAVE_RECEDE_T)
        td.edge = Util.lerp(td.reach, td.base, k * k)
        if k >= 1 then
            td.state = "calm"
            td.t = 0
            td.count = td.count + 1
            td.wetX = td.reach
            td.nextIn = C.WAVE_GAP_MIN + math.random() * C.WAVE_GAP_VAR - G.diff * 3
            Harness.count("wavesSurvived")
            Game.addScore(C.PTS_WAVE)
            Worms.burst(td.reach)
        end
    end

    -- the wet band slowly dries back toward the shore
    if td.wetX < td.base - 24 then
        td.wetX = td.wetX + dt * 2.2
    end

    -- water effects on the player
    local b = G.bird
    b.inWater = b.x > td.edge + 2
    if b.inWater and (td.state == "surge" or td.state == "hold")
        and b.tumble <= 0 and b.tumbleCD <= 0 then
        Bird.tumble()
        if G.state ~= "play" then return end
    end

    -- chicks caught by the surge are washed away
    if td.state == "surge" or td.state == "hold" then
        Flock.washCheck(td.edge)
    end
end
