-- The jogger. Pounds down the dry sand from one end of the beach to the
-- other on a telegraphed lane - a blinking "!" and thudding footfalls give
-- warning. Getting underfoot costs energy and scatters the flock.

Jogger = {}

function Jogger.reset()
    G.jogger = nil
    G.jogTimer = C.JOG_FIRST
end

function Jogger.update(dt)
    local j = G.jogger
    if not j then
        G.jogTimer = G.jogTimer - dt
        if G.jogTimer <= 0 then
            local dir = math.random() < 0.5 and 1 or -1
            local x0 = 85 + math.random() * 115
            G.jogger = {
                dir = dir, x0 = x0, x = x0,
                y = dir == 1 and -26 or C.H + 26,
                state = "warn", t = C.JOG_WARN,
                foot = 0, thud = 0,
            }
            Sfx.thud()
        end
        return
    end

    if j.state == "warn" then
        j.t = j.t - dt
        if j.t <= 0 then j.state = "run" end
        return
    end

    j.y = j.y + j.dir * C.JOG_SPD * dt
    j.x = j.x0 + math.sin(j.y * 0.05) * 9
    j.foot = j.foot - dt
    if j.foot <= 0 then
        j.foot = 0.1
        Fx.puff(j.x + math.random(-4, 4), j.y - j.dir * 8, 1)
    end
    j.thud = j.thud - dt
    if j.thud <= 0 then
        j.thud = 0.3
        Sfx.thud()
    end

    local b = G.bird
    if b.jogCD <= 0 and b.tumble <= 0 and Util.dist(j.x, j.y, b.x, b.y) < 15 then
        b.jogCD = 1.5
        b.stun = C.JOG_STUN
        local nx, ny = Util.norm(j.x, j.y, b.x, b.y)
        b.vx, b.vy = nx * 260, ny * 260
        Flock.scatter()
        Harness.count("trampled")
        Fx.text("WATCH IT!", b.x - 20, b.y - 16)
        Sfx.pinch()
        Bird.damage(C.JOG_COST, "FLATTENED BY A JOGGER")
        if G.state ~= "play" then return end
    end

    if (j.dir == 1 and j.y > C.H + 30) or (j.dir == -1 and j.y < -30) then
        G.jogger = nil
        G.jogTimer = C.JOG_INT - G.diff * 8 + math.random() * 10
    end
end
