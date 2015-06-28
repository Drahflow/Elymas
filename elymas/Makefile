all: loaded shared

shared: optimized shared.ey $(shell find lib -name '*.ey')
	./optimized shared.ey

loaded: optimized loaded.ey $(shell find lib -name '*.ey')
	./optimized loaded.ey

optimized: interpreter optimized.ey lib/math.ey lib/txt.ey lib/sys/opt.ey
	./interpreter optimized.ey

.PHONY: all
