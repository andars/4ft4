CFLAGS = -g -Wall

TEST_SOURCES := $(shell find tests -name '*.s')
TEST_BINARIES := $(patsubst tests/%.s,build/%.bin,$(TEST_SOURCES))
TEST_LOGS := $(patsubst %.bin,%.log,$(TEST_BINARIES))

sim: build/sim.o
	$(CC) -o $@ $<

build/%.o: %.c
	mkdir -p build
	$(CC) -c -o $@ $<

$(TEST_BINARIES): build/%.bin: tests/%.s
	mkdir -p $(@D)
	bash -c "./as.py <(grep -v -e '^!' $<) $@ > $@.build.log"

.PHONY: $(TEST_LOGS)
$(TEST_LOGS): build/%.log: build/%.bin tests/%.s sim
	bash ./tests/run.sh $(word 2,$^) $(word 1,$^) > $@ || (cat $@; echo "test $(word 2,$^) failed: $@"; exit 1)
	cat $@

run-%: build/%.bin
	echo "running test for $*"

build-tests: $(TEST_BINARIES)

test: $(TEST_LOGS)
	@echo sources: $(TEST_SOURCES)
	@echo binaries: $(TEST_BINARIES)
	@echo run: $(TEST_LOGS)

clean:
	rm -f sim sim.o
	rm -rf build
