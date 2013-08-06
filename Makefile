all: elymas/interpreter

elymas/interpreter: elymas/interpreter.ey compiler/*.ey
	cd compiler && \
	  ../interpreter/elymas elymas.ey ../elymas/interpreter.ey
	mv -v compiler/interpreter $@
