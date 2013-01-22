.PHONY: test

CASES=../examples/working-compiler
EXE=../../compiler/elymas.ey
ABSTRACT=s/00006[0-9A-F]\{11\}/<heap>/g;s/00007[0-9A-F]\{11\}/<stack>/g;s/00002[0-9A-F]\{11\}/<aslr stack>/g;s/<aslr stack> ......../<aslr stack>/g

test:
	for f in $$(ls $(CASES)/*.test | sed -e 's/.*\///g'); do \
	  printf "%20s: " $$f; \
	  echo Input | ( cd $(CASES); $(EXE) "$$f"; echo ) \
	    2> "test/$$f.err.test" | sed -e '$(ABSTRACT)' > "test/$$f.test"; \
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
	    2> "test/$$f.err.correct" | sed -e '$(ABSTRACT)' | tee "test/$$f.correct"; \
	  sleep 1; \
	done

generate-test-fast:
	mkdir -p test
	for f in $$(ls $(CASES)/*.test | sed -e 's/.*\///g'); do \
	  echo $$f; \
	  echo Input | ( cd $(CASES); $(EXE) "$$f"; echo ) \
	    2> "test/$$f.err.correct" | sed -e '$(ABSTRACT)' | tee "test/$$f.correct"; \
	done
