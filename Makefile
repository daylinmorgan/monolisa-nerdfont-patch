ARGS ?= -c
OK_TYPES := otf ttf woff woff2
NF_SRC := $(shell find src -type f)
ML_TYPES := $(shell find MonoLisa -mindepth 1 -type d -printf "%f ")

UNKNOWN := $(filter-out $(OK_TYPES),$(ML_TYPES))
$(if $(UNKNOWN),$(error unknown font type in ./MonoLisa: $(UNKNOWN)))

.PHONY: patch
patch: $(addprefix patch-,$(ML_TYPES))

patch-%: ./bin/font-patcher
	@echo "==> Patching MonoLisa $* Files <=="
	@./bin/patch-monolisa $* $(ARGS)

.PHONY: update-fonts
update-fonts:
	@echo "==> Adding Fonts To System <=="
	@./bin/update-fonts
	@fc-cache -f -v

.PHONY: check
check:
	@echo "==> Checking System For Fonts <=="
	@fc-list | grep "MonoLisa"

.PHONY: update-src
update-src:
	@echo "==> Updating Source File <=="
	@./bin/update-src

.PHONY: lint
lint:
	@shfmt -w -s $(shell shfmt -f bin/)

.PHONY: clean
clean:
	@rm -r patched/*
