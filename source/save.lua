-- High-score persistence in the "killdeer" datastore.

Save = {}

function Save.load()
    local d = playdate.datastore.read("killdeer")
    G.high = (d and d.high) or 0
end

function Save.store()
    playdate.datastore.write({ high = G.high }, "killdeer")
end
