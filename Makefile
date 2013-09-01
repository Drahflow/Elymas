all: elymas/loaded

elymas/loaded: elymas/interpreter $(shell find elymas/lib/ -name '*.ey' )
	cd elymas && $(MAKE) loaded

elymas/interpreter: elymas/interpreter.ey compiler/*.ey interpreter/Metal.so interpreter/ACME
	cd compiler && \
	  ../interpreter/elymas elymas.ey ../elymas/interpreter.ey
	mv -v compiler/interpreter $@

interpreter/Metal.so interpreter/ACME:
	cd ACME-Bare-Metal/ && \
	  perl Makefile.PL && \
	  $(MAKE)
	cd interpreter && \
	  ln -vs ../ACME-Bare-Metal/blib/arch/auto/ACME/Bare/Metal/Metal.so . && \
	  ln -vs ../ACME-Bare-Metal/lib/ACME ACME
