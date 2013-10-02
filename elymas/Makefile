loaded: optimized loaded.ey $(shell find lib -name '*.ey')
	./optimized < loaded.ey || true

optimized: interpreter optimized.ey lib/math.ey lib/sys/opt.ey
	./interpreter < optimized.ey || true
