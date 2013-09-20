loaded: optimized loaded.ey $(shell find lib -name '*.ey')
	./optimized < loaded.ey || true

optimized: interpreter optimized.ey $(shell find lib -name '*.ey')
	./interpreter < optimized.ey || true
