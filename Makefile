# Peckish - a killdeer on the tideline, for Playdate.
#
#   make            release build -> out/Peckish.pdx
#   make smoke      instrumented build -> out/PeckishSmoke.pdx
#
# Staging copies source/* into build/<variant>/source and writes
# smokeflag.lua (pdc wants one source root; smokeflag is generated).

OUT := out

all: release

release: build/release/source
	pdc build/release/source $(OUT)/Peckish.pdx

smoke: build/smoke/source
	pdc build/smoke/source $(OUT)/PeckishSmoke.pdx

build/release/source: source/*
	mkdir -p $@ $(OUT)
	cp source/* $@/
	echo 'SMOKE_BUILD = false' > $@/smokeflag.lua

build/smoke/source: source/*
	mkdir -p $@ $(OUT)
	cp source/* $@/
	echo 'SMOKE_BUILD = true' > $@/smokeflag.lua

clean:
	rm -rf build $(OUT)

.PHONY: all release smoke clean
