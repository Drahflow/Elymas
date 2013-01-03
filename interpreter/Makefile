.PHONY: test

test:
	for f in $$(ls ../examples/working); do \
	  printf "%20s: " $$f; \
	  echo Input | ( cd ../examples/working; ../../interpreter/elymas "$$f"; echo ) \
	    2> "test/$$f.err.test" > "test/$$f.test"; \
	  if diff "test/$$f.test" "test/$$f.correct" && diff "test/$$f.err.test" "test/$$f.err.correct"; then \
	    echo "[32mSuccess.[0m"; \
	  else \
	    echo "[31mFailed.[0m"; \
	  fi \
	done

generate-test:
	mkdir -p test
	for f in $$(ls ../examples/working); do \
	  echo $$f; \
	  echo Input | ( cd ../examples/working; ../../interpreter/elymas "$$f"; echo ) \
	    2> "test/$$f.err.correct" | tee "test/$$f.correct"; \
	  sleep 1; \
	done

generate-test-fast:
	mkdir -p test
	for f in $$(ls ../examples/working); do \
	  echo $$f; \
	  echo Input | ( cd ../examples/working; ../../interpreter/elymas "$$f"; echo ) \
	    2> "test/$$f.err.correct" | tee "test/$$f.correct"; \
	done
