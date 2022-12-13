ARGS ?= -c

NF_SRC := $(shell ./bin/get-font-files src)
FONT_FLAGS := $(shell ./bin/get-font-files MonoLisa 'otf,ttf,woff,woff2')

## patch | apply nerd fonts patch
patch: ./bin/font-patcher
	@./bin/patch-monolisa \
		$(FONT_FLAGS) \
		$(ARGS)

## update-fonts | move fonts and update fc-cache
.PHONY: update-fonts
update-fonts:
	$(call msg,Adding Fonts To System)
	@./bin/update-fonts
	@fc-cache -f -v

## check | check fc-list for MonoLisa
.PHONY: check
check:
	$(call msg,Checking System for Fonts)
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

msg = $(call tprint,{a.bold}==>{a.end} {a.b_magenta}$(1){a.end} {a.bold}<=={a.end})
USAGE = {a.b_green}Update MonoLisa with Nerd Fonts! {a.end}\n\n{a.header}usage{a.end}:\n	make <recipe>\n
-include .task.mk
