-- Synth sound effects: a seaside kit. Gulps for worms, noise swells for
-- waves, harsh saws for pinches, high squares for the gull.

local snd <const> = playdate.sound

Sfx = {}

local tri = snd.synth.new(snd.kWaveTriangle)
local tri2 = snd.synth.new(snd.kWaveTriangle)
local sq = snd.synth.new(snd.kWaveSquare)
local saw = snd.synth.new(snd.kWaveSawtooth)
local noise = snd.synth.new(snd.kWaveNoise)
local noise2 = snd.synth.new(snd.kWaveNoise)

function Sfx.blip(f)
    tri:playNote(f or 660, 0.25, 0.05)
end

function Sfx.gulp()
    tri2:playNote(520, 0.3, 0.05)
    Util.after(0.05, function() tri2:playNote(330, 0.28, 0.07) end)
end

function Sfx.peckMiss()
    noise:playNote(900, 0.12, 0.03)
end

function Sfx.waveWarn()
    noise2:playNote(120, 0.25, 0.5)
    saw:playNote(90, 0.2, 0.4)
end

function Sfx.waveCrash()
    noise2:playNote(200, 0.5, 0.45)
end

function Sfx.tumble()
    saw:playNote(400, 0.35, 0.1)
    Util.after(0.08, function() saw:playNote(280, 0.3, 0.12) end)
    Util.after(0.18, function() saw:playNote(180, 0.3, 0.16) end)
    noise:playNote(300, 0.4, 0.3)
end

function Sfx.pinch()
    saw:playNote(150, 0.45, 0.15)
    noise:playNote(240, 0.3, 0.08)
end

function Sfx.flipPop()
    sq:playNote(300, 0.3, 0.04)
    Util.after(0.04, function() sq:playNote(600, 0.25, 0.05) end)
end

function Sfx.screech()
    sq:playNote(1800, 0.28, 0.09)
    Util.after(0.1, function() sq:playNote(1400, 0.25, 0.14) end)
end

function Sfx.dive()
    saw:playNote(1200, 0.3, 0.3)
end

function Sfx.taken()
    Sfx.fanfare({ 740, 620, 494 }, 0.09)
end

function Sfx.washed()
    Sfx.fanfare({ 500, 380, 260 }, 0.08)
    noise:playNote(200, 0.3, 0.2)
end

function Sfx.display()
    for i = 0, 3 do
        Util.after(i * 0.05, function() tri:playNote(900 + (i % 2) * 250, 0.22, 0.04) end)
    end
end

function Sfx.hatch()
    Sfx.fanfare({ 659, 830, 988, 1319 }, 0.07)
end

function Sfx.thud()
    noise:playNote(90, 0.2, 0.05)
end

function Sfx.lowWarn()
    tri:playNote(220, 0.2, 0.1)
end

function Sfx.fanfare(notes, step)
    notes = notes or { 523, 659, 784, 1047 }
    for i, n in ipairs(notes) do
        Util.after((i - 1) * (step or 0.1), function() tri:playNote(n, 0.3, (step or 0.1) * 1.4) end)
    end
end

function Sfx.lose()
    Sfx.fanfare({ 494, 415, 349, 262 }, 0.14)
end
