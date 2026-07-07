-- The flock: chicks hatched from dune eggs. They trail the player along a
-- breadcrumb path, eat worms they run over, and multiply the score - but
-- gulls can snatch them and surging waves wash them away.

Flock = {}

function Flock.add(x, y)
    G.chicks[#G.chicks + 1] = { x = x, y = y, scaredT = 0, jx = 0, jy = 0 }
end

function Flock.update(dt)
    for i, c in ipairs(G.chicks) do
        local crumb = G.crumbs[i * 6] or G.crumbs[#G.crumbs]
        local tx = crumb and crumb.x or G.bird.x
        local ty = crumb and crumb.y or G.bird.y
        c.scaredT = math.max(0, c.scaredT - dt)
        if c.scaredT > 0 then
            tx, ty = tx + c.jx, ty + c.jy
        end
        local k = math.min(1, dt * 5.5)
        c.x = c.x + (tx - c.x) * k
        c.y = c.y + (ty - c.y) * k
    end
end

function Flock.scatter()
    for _, c in ipairs(G.chicks) do
        c.scaredT = 0.9
        c.jx = math.random(-40, 40)
        c.jy = math.random(-40, 40)
    end
end

function Flock.washCheck(edge)
    for i = #G.chicks, 1, -1 do
        local c = G.chicks[i]
        if c.x > edge + 3 then
            table.remove(G.chicks, i)
            Fx.text("WASHED AWAY!", c.x - 30, c.y)
            Fx.puff(c.x, c.y, 6)
            Harness.count("washed")
            Sfx.washed()
        end
    end
end
