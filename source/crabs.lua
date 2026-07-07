-- Crabs scuttle out of the surf, wander the wet sand, and race you to
-- surfaced worms. Touch one and it pinches. Peck one to flip it; peck a
-- flipped crab to finish it for points.

Crabs = {}

function Crabs.reset()
    G.crabs = {}
    G.crabTimer = C.CRAB_FIRST
end

function Crabs.update(dt)
    local cap = 1 + math.floor(G.diff * 2 + 0.01)
    G.crabTimer = G.crabTimer - dt
    if G.crabTimer <= 0 and #G.crabs < cap then
        G.crabTimer = C.CRAB_INT - G.diff * 6 + math.random() * 5
        G.crabs[#G.crabs + 1] = {
            x = C.SHORE_X + 30, y = 30 + math.random() * 180,
            tx = C.SHORE_X - 60, ty = 30 + math.random() * 180,
            ang = math.pi, flip = 0, pinchCD = 0, think = 0,
        }
    end

    local b = G.bird
    for i = #G.crabs, 1, -1 do
        local cr = G.crabs[i]
        cr.pinchCD = math.max(0, cr.pinchCD - dt)
        if cr.flip > 0 then
            cr.flip = cr.flip - dt
        else
            cr.think = cr.think - dt
            -- race to a surfaced worm if one is close
            local wx, wy, best
            for _, w in ipairs(G.worms) do
                if w.state == "up" then
                    local d = Util.dist(cr.x, cr.y, w.x, w.y)
                    if d < 80 and (not best or d < best) then
                        best, wx, wy = d, w.x, w.y
                    end
                end
            end
            if wx then
                cr.tx, cr.ty = wx, wy
            elseif cr.think <= 0 then
                cr.think = 1.5 + math.random() * 2
                cr.tx = C.SHORE_X - 90 + math.random() * 110
                cr.ty = 25 + math.random() * 190
            end
            local nx, ny = Util.norm(cr.x, cr.y, cr.tx, cr.ty)
            local spd = C.CRAB_SPD + G.diff * 15
            cr.x = cr.x + nx * spd * dt
            cr.y = cr.y + ny * spd * dt
            cr.ang = math.atan(ny, nx)
            if wx and Util.dist(cr.x, cr.y, wx, wy) < 8 then
                for j = #G.worms, 1, -1 do
                    local w = G.worms[j]
                    if w.state == "up" and w.x == wx and w.y == wy then
                        table.remove(G.worms, j)
                        Harness.count("crabSteals")
                        Fx.puff(wx, wy, 3)
                        break
                    end
                end
            end
            if cr.pinchCD <= 0 and b.stun <= 0 and b.tumble <= 0
                and Util.dist(cr.x, cr.y, b.x, b.y) < 12 then
                cr.pinchCD = 1.2
                Bird.pinched(cr.x, cr.y)
                if G.state ~= "play" then return end
            end
        end
    end
end

-- peck at (px,py): flip a crab, or finish a flipped one. Returns true on hit.
function Crabs.tryPeck(px, py, r)
    for i, cr in ipairs(G.crabs) do
        if Util.dist(px, py, cr.x, cr.y) < r + 4 then
            if cr.flip > 0 then
                table.remove(G.crabs, i)
                local pts = Game.addScore(C.PTS_CRAB)
                Fx.text("+" .. pts, cr.x, cr.y - 12)
                Fx.puff(cr.x, cr.y, 6)
                Harness.count("crabKOs")
                Sfx.gulp()
            else
                cr.flip = C.CRAB_FLIP_T
                Harness.count("crabFlips")
                Fx.text("FLIP!", cr.x, cr.y - 12)
                Sfx.flipPop()
            end
            return true
        end
    end
    return false
end
