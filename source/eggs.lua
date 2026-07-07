-- Eggs. Killdeer nest in bare scrapes on open ground: one appears up by the
-- dunes now and then. Stand over it to brood; the hatch meter fills and a
-- chick joins the flock. Wander off and the meter drains; dawdle too long
-- and the egg is gone.

Eggs = {}

function Eggs.reset()
    G.egg = nil
    G.eggTimer = C.EGG_FIRST
end

function Eggs.update(dt)
    local e = G.egg
    if not e then
        if #G.chicks >= C.MAX_FLOCK then return end
        G.eggTimer = G.eggTimer - dt
        if G.eggTimer <= 0 then
            G.egg = {
                x = 25 + math.random() * 90,
                y = 40 + math.random() * 170,
                life = C.EGG_LIFE, prog = 0,
            }
            Fx.text("AN EGG!", G.egg.x + 4, G.egg.y - 22)
            Sfx.blip(880)
        end
        return
    end

    e.life = e.life - dt
    local b = G.bird
    if Util.dist(b.x, b.y, e.x, e.y) < C.EGG_R and b.tumble <= 0 then
        e.prog = e.prog + dt
        if e.prog >= C.EGG_HATCH then
            Flock.add(e.x, e.y)
            local pts = Game.addScore(C.PTS_HATCH)
            Fx.text("CHICK! +" .. pts, e.x, e.y - 16)
            Harness.count("hatches")
            Sfx.hatch()
            G.egg = nil
            G.eggTimer = C.EGG_INT
            return
        end
    else
        e.prog = math.max(0, e.prog - dt * 0.6)
    end
    if e.life <= 0 then
        G.egg = nil
        G.eggTimer = C.EGG_INT * 0.6
    end
end
