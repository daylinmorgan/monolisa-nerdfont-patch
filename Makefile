ARGS ?= -c
OK_TYPES := otf ttf woff woff2
NF_SRC := $(shell find src -type f)
ML_TYPES := $(shell find MonoLisa -mindepth 1 -type d -printf "%f ")

UNKNOWN := $(filter-out $(OK_TYPES),$(ML_TYPES))
$(if $(UNKNOWN),$(error unknown font type in ./MonoLisa: $(UNKNOWN)))

msg = $(call tprint,{a.bold}==>{a.end} {a.b_magenta}$(1){a.end} {a.bold}<=={a.end})

## patch | add nerd fonts to MonoLisa
.PHONY: patch
patch: $(addprefix patch-,$(ML_TYPES))

patch-%: ./bin/font-patcher
	$(call msg, Patching MonoLisa $* Files)
	@./bin/patch-monolisa $* $(ARGS)

## update-fonts | move fonts and update fc-cache
.PHONY: update-fonts
update-fonts:
	$(call msg,Adding Fonts To System)
	@./bin/update-fonts
	@fc-cache -f -v

## check | check fc-list for MonoLisa
.PHONY: check
check:
	$(call msg, Checking System for Fonts)
	@fc-list | grep "MonoLisa"

## update-src | update nerd fonts source
.PHONY: update-src
update-src:
	$(call msg,Updating Source Files)
	@./bin/update-src

## lint | check shell scripts
.PHONY: lint
lint:
	@shfmt -w -s $(shell shfmt -f bin/)

## clean | remove patched fonts
.PHONY: clean
clean:
	@rm -r patched/*

define USAGE
{a.b_green}Update MonoLisa with Nerd Fonts! {a.end}

{a.$(HEADER_COLOR)}usage{a.end}:
	make <recipe>

endef

-include .task.mk
$(if $(filter help,$(MAKECMDGOALS)),.task.mk: ; curl -fsSL https://raw.githubusercontent.com/daylinmorgan/task.mk/v22.9.5/task.mk -o .task.mk)
