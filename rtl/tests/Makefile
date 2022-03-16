SELF:=$(lastword $(MAKEFILE_LIST))
OUT=$(realpath $(dir $(SELF))/..)/testruns/tests
$(info writing test output to $(OUT))

TEST_MODULES := rom-wb ram-wb system-wb

.PHONY: all $(TEST_MODULES)

.PHONY: all
all: $(TEST_MODULES)

$(TEST_MODULES):
	@mkdir -p $(OUT)/$@ && $(MAKE) -C $(OUT)/$@ -f $(realpath $@/Makefile)
