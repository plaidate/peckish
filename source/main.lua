-- Peckish - a standalone Playdate game.
-- You are a killdeer, a little shorebird scurrying the tideline. Worms
-- surface in the sand - richest where a wave just receded - and your
-- metabolism never stops burning, faster when you sprint. Dodge the surf,
-- crabs, a hungry gull and an oblivious jogger; brood dune eggs to grow a
-- chick flock that multiplies your score. Zero energy ends the run.

import "CoreLibs/graphics"

import "config"
import "util"
import "harness"
import "save"
import "sfx"
import "fx"
import "worms"
import "waves"
import "flock"
import "bird"
import "crabs"
import "gull"
import "jogger"
import "eggs"
import "input"
import "draw"

Game = {}

Save.load()
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(SMOKE_BUILD and 0 or 30)
Harness.shotPath = "build/peckish-shot.png"
Draw.init()
Fx.reset()
Bird.reset()
Waves.reset()
Worms.reset()
Crabs.reset()
Gull.reset()
Jogger.reset()
Eggs.reset()

function Game.mult()
    return 1 + 0.25 * #G.chicks
end

-- all scoring flows through here so the flock bonus always applies
function Game.addScore(n)
    local gained = math.floor(n * Game.mult() + 0.5)
    G.score = G.score + gained
    return gained
end

local function startGame()
    G.score = 0
    G.playT = 0
    G.diff = 0
    G.overReason = ""
    Bird.reset()
    Waves.reset()
    Worms.reset()
    Crabs.reset()
    Gull.reset()
    Jogger.reset()
    Eggs.reset()
    Fx.reset()
    G.state = "ready"
    G.t = 0
    Harness.count("games")
    Sfx.fanfare()
end

function Game.over(reason)
    if G.state ~= "play" then return end
    G.overReason = reason
    if G.score > G.high then
        G.high = G.score
        Save.store()
    end
    G.state = "gameover"
    G.t = 0
    Harness.count("gameovers")
    Sfx.lose()
end

-- ---- play update ------------------------------------------------------------

local warnBeep = 0

local function updatePlay(dt)
    G.playT = G.playT + dt
    G.diff = math.min(1, G.playT / 150)

    local inp = Input.gather()
    Bird.update(dt, inp)
    if G.state ~= "play" then return end
    Flock.update(dt)
    Waves.update(dt)
    if G.state ~= "play" then return end
    Worms.update(dt)
    Crabs.update(dt)
    if G.state ~= "play" then return end
    Gull.update(dt)
    if G.state ~= "play" then return end
    Jogger.update(dt)
    if G.state ~= "play" then return end
    Eggs.update(dt)

    warnBeep = warnBeep - dt
    if G.bird.energy < 22 and warnBeep <= 0 then
        warnBeep = 1.1
        Sfx.lowWarn()
    end
end

-- ---- top-level loop ---------------------------------------------------------

local function tick()
    local dt = C.DT
    G.t = G.t + dt
    Util.runPending(dt)
    Fx.update(dt)

    if G.state == "title" then
        if Input.confirm() then startGame() end
        Draw.title()
    elseif G.state == "ready" then
        Draw.play()
        Draw.readyOverlay()
        if G.t > 1.2 then
            G.state = "play"
            G.t = 0
        end
    elseif G.state == "play" then
        updatePlay(dt)
        if G.state == "play" then Draw.play() end
    elseif G.state == "gameover" then
        Draw.gameover()
        if G.t > 1 and Input.confirm() then
            G.state = "title"
            G.t = 0
        end
    end
end

Harness.extra = function(t)
    t.state = G.state
    t.overReason = G.overReason
    t.score = G.score
    t.high = G.high
    t.energy = G.bird and math.floor(G.bird.energy + 0.5) or 0
    t.flock = G.chicks and #G.chicks or 0
    t.playT = math.floor(G.playT)
    t.tide = G.tide and G.tide.state or "?"
    t.wormsUp = G.worms and #G.worms or 0
    t.crabsUp = G.crabs and #G.crabs or 0
end

local frame = 0
function playdate.update()
    frame = frame + 1
    Harness.frame(frame, tick)
end
