-- The killdeer. D-pad scurries, B sprints (burns energy faster), A pecks,
-- cranking performs the broken-wing display (slow, but lures the gull).
-- Energy drains every second just for being alive; it only comes back
-- through worms. Zero energy ends the run.

Bird = {}

function Bird.reset()
    G.bird = {
        x = 150, y = 130,
        vx = 0, vy = 0,
        face = 0,
        energy = C.ENERGY_START,
        stun = 0,
        tumble = 0, tumbleCD = 0,
        peckCD = 0, peckT = 0,
        displayT = 0, display = false,
        jogCD = 0,
        inWater = false,
    }
    G.crumbs = {}
    G.chicks = {}
end

function Bird.update(dt, inp)
    local b = G.bird
    b.stun = math.max(0, b.stun - dt)
    b.tumble = math.max(0, b.tumble - dt)
    b.tumbleCD = math.max(0, b.tumbleCD - dt)
    b.peckCD = math.max(0, b.peckCD - dt)
    b.peckT = math.max(0, b.peckT - dt)
    b.jogCD = math.max(0, b.jogCD - dt)
    b.displayT = math.max(0, b.displayT - dt)

    -- broken-wing display: keep cranking to keep limping
    if math.abs(inp.crank or 0) > 5 and b.stun <= 0 and b.tumble <= 0 then
        if b.displayT <= 0 then
            Harness.count("displays")
            Sfx.display()
        end
        b.displayT = 0.4
    end
    b.display = b.displayT > 0

    local control = b.stun <= 0 and b.tumble <= 0
    local moving = inp.mvx ~= 0 or inp.mvy ~= 0
    local running = control and inp.run and moving and not b.display
    local spd = running and C.RUN_SPD or C.WALK_SPD
    if b.display then spd = spd * 0.45 end
    if b.inWater then spd = spd * 0.5 end

    if control and moving then
        local nx, ny = Util.norm(0, 0, inp.mvx, inp.mvy)
        b.vx = b.vx + nx * C.ACCEL * dt
        b.vy = b.vy + ny * C.ACCEL * dt
        local v = math.sqrt(b.vx * b.vx + b.vy * b.vy)
        if v > spd then
            b.vx, b.vy = b.vx / v * spd, b.vy / v * spd
        end
        b.face = math.atan(b.vy, b.vx)
    else
        local d = (b.tumble > 0) and 1.6 or C.DAMP
        b.vx = b.vx - b.vx * math.min(1, d * dt)
        b.vy = b.vy - b.vy * math.min(1, d * dt)
    end

    b.x = Util.clamp(b.x + b.vx * dt, 8, C.W - 8)
    b.y = Util.clamp(b.y + b.vy * dt, 20, C.H - 8)

    -- metabolism
    local drain = C.DRAIN_WALK
    if running then drain = drain + C.DRAIN_RUN end
    if b.display then drain = drain + C.DRAIN_DISPLAY end
    if b.inWater then drain = drain + C.DRAIN_WADE end
    b.energy = b.energy - drain * dt
    if b.energy <= 0 then
        b.energy = 0
        Game.over("STARVED ON THE TIDELINE")
        return
    end

    -- pecking
    if control and inp.peck and b.peckCD <= 0 then
        b.peckCD = C.PECK_CD
        b.peckT = 0.12
        local px = b.x + math.cos(b.face) * 10
        local py = b.y + math.sin(b.face) * 10
        local fed = Worms.tryPeck(px, py, C.PECK_R)
            or Worms.tryPeck(b.x, b.y, C.PECK_R - 2)
            or Crabs.tryPeck(px, py, C.PECK_R)
            or Crabs.tryPeck(b.x, b.y, C.PECK_R - 2)
        if not fed then Sfx.peckMiss() end
    end

    -- breadcrumbs for the flock
    local last = G.crumbs[1]
    if not last or Util.dist(b.x, b.y, last.x, last.y) > 5 then
        table.insert(G.crumbs, 1, { x = b.x, y = b.y })
        if #G.crumbs > 60 then table.remove(G.crumbs) end
    end
end

function Bird.eat(val, byChick)
    local b = G.bird
    b.energy = math.min(C.ENERGY_MAX, b.energy + (byChick and val * 0.5 or val))
end

-- energy loss that can end the run, with the reason it would end
function Bird.damage(cost, reason)
    local b = G.bird
    b.energy = b.energy - cost
    if b.energy <= 0 then
        b.energy = 0
        Game.over(reason)
    end
end

function Bird.tumble()
    local b = G.bird
    b.tumble = C.TUMBLE_T
    b.tumbleCD = 3.0
    b.vx = -C.TUMBLE_PUSH - math.random(0, 60)
    b.vy = math.random(-70, 70)
    Fx.puff(b.x, b.y, 8)
    Fx.text("TUMBLED!", b.x - 20, b.y - 16)
    Harness.count("tumbles")
    Sfx.tumble()
    Bird.damage(C.TUMBLE_COST, "SWEPT AWAY BY A WAVE")
end

function Bird.pinched(cx, cy)
    local b = G.bird
    b.stun = C.PINCH_STUN
    local nx, ny = Util.norm(cx, cy, b.x, b.y)
    b.vx, b.vy = nx * 220, ny * 220
    Fx.text("OUCH!", b.x, b.y - 14)
    Harness.count("pinches")
    Sfx.pinch()
    Bird.damage(C.PINCH_COST, "PINCHED OUT BY A CRAB")
end
