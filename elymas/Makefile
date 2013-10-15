shared: loaded shared.ey lib/sys/so.ey
	./loaded < shared.ey

loaded: optimized loaded.ey $(shell find lib -name '*.ey')
	./optimized < loaded.ey

optimized: interpreter optimized.ey lib/math.ey lib/sys/opt.ey
	./interpreter < optimized.ey
