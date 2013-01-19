.PHONY: test

CASES=../examples/working-compiler
EXE=../../compiler/elymas.ey

test:
	for f in $$(ls $(CASES)/*.test | sed -e 's/.*\///g'); do \
	  printf "%20s: " $$f; \
	  echo Input | ( cd $(CASES); $(EXE) "$$f"; echo ) \
	    2> "test/$$f.err.test" | sed -e 's/.*://g' > "test/$$f.test"; \
	  if diff "test/$$f.test" "test/$$f.correct" && diff "test/$$f.err.test" "test/$$f.err.correct"; then \
	    echo "[32mSuccess.[0m"; \
	  else \
	    echo "[31mFailed.[0m"; \
	  fi \
	done

generate-test:
	mkdir -p test
	for f in $$(ls $(CASES)/*.test | sed -e 's/.*\///g'); do \
	  echo $$f; \
	  echo Input | ( cd $(CASES); $(EXE) "$$f"; echo ) \
	    2> "test/$$f.err.correct" | sed -e 's/.*://g' | tee "test/$$f.correct"; \
	  sleep 1; \
	done

generate-test-fast:
	mkdir -p test
	for f in $$(ls $(CASES)/*.test | sed -e 's/.*\///g'); do \
	  echo $$f; \
	  echo Input | ( cd $(CASES); $(EXE) "$$f"; echo ) \
	    2> "test/$$f.err.correct" | sed -e 's/.*://g' | tee "test/$$f.correct"; \
	done
