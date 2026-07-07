-- Tunables (C) and live state (G). Fixed 30fps step.
-- Top-down beach: dune grass on the left, dry sand in the middle, wet sand
-- along the shore, ocean on the right. Waves surge in from the right edge;
-- the freshly wet sand a wave leaves behind is where the best worms are.

C = {
    DT = 1 / 30,
    W = 400,
    H = 240,

    DUNE_X = 55,      -- left of this: dune grass (no worms, waves never reach)
    SHORE_X = 310,    -- calm waterline; water covers x > G.tide.edge

    -- the killdeer
    ENERGY_MAX = 100,
    ENERGY_START = 70,
    DRAIN_WALK = 2.0,     -- energy/sec: a shorebird's metabolism never idles
    DRAIN_RUN = 3.0,      -- extra while sprinting (B held)
    DRAIN_DISPLAY = 1.5,  -- extra while doing the broken-wing act
    DRAIN_WADE = 2.0,     -- extra while paddling in the shallows
    WALK_SPD = 95,
    RUN_SPD = 175,
    ACCEL = 900,
    DAMP = 5.0,
    PECK_R = 15,
    PECK_CD = 0.22,

    -- hazard costs
    TUMBLE_T = 1.1,
    TUMBLE_COST = 15,
    TUMBLE_PUSH = 240,
    PINCH_COST = 10,
    PINCH_STUN = 0.7,
    GULL_COST = 16,
    GULL_STUN = 0.9,
    JOG_COST = 12,
    JOG_STUN = 0.8,

    -- worms
    WORM_INT = 2.0,
    WORM_CAP = 6,
    WORM_BUBBLE = 1.1,
    WORM_UP = 2.4,
    WORM_E_DRY = 9,
    WORM_E_WET = 14,
    BURST_N = 5,          -- rich feeding right after every wave

    -- tide
    WAVE_FIRST = 6,
    WAVE_GAP_MIN = 6,
    WAVE_GAP_VAR = 6,
    WAVE_WARN = 1.0,
    WAVE_SURGE_T = 0.8,
    WAVE_HOLD = 0.6,
    WAVE_RECEDE_T = 1.6,
    SNEAKER_EXTRA = 55,   -- sneaker waves reach this much further up the beach

    -- hazards
    CRAB_FIRST = 10,
    CRAB_INT = 16,
    CRAB_SPD = 40,
    CRAB_FLIP_T = 3.0,
    GULL_FIRST = 18,
    GULL_INT = 22,
    GULL_CIRCLE_T = 2.6,
    GULL_DIVE_T = 0.5,
    GULL_HIT_R = 14,
    JOG_FIRST = 26,
    JOG_INT = 30,
    JOG_WARN = 1.1,
    JOG_SPD = 130,

    -- flock
    EGG_FIRST = 12,
    EGG_INT = 20,
    EGG_LIFE = 14,
    EGG_R = 22,
    EGG_HATCH = 2.2,
    MAX_FLOCK = 3,

    -- points (all multiplied by the flock bonus)
    PTS_WORM_DRY = 50,
    PTS_WORM_WET = 80,
    PTS_CRAB = 150,
    PTS_LURE = 200,
    PTS_HATCH = 100,
    PTS_WAVE = 25,
}

G = {
    state = "title", -- title | ready | play | gameover
    t = 0,
    playT = 0,
    diff = 0,
    score = 0,
    high = 0,
    overReason = "",
}
