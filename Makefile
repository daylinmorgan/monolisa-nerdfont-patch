-include .env
ARGS ?= -c

patch: ./bin/font-patcher ## apply nerd fonts patch |> -gs b_magenta -ms bold
	@./patch-monolisa \
		$(ARGS) \
		-f MonoLisa/

update-fonts: ## move fonts and update fc-cache
	$(call msg,Adding Fonts To System)
	@./bin/update-fonts
	@fc-cache -f -v

check: ## check fc-list for MonoLisa
	$(call msg,Checking System for Fonts)
	@fc-list | grep "MonoLisa"

update-src: ## update nerd fonts source
	$(call msg,Updating Source Files)
	@./bin/update-src

lint: ## run pre-commit hooks
	@pre-commit run --all

clean: ## remove patched fonts
	@rm -rf patched/*

# depends on daylinmorgan/yartsu
assets/help.svg:
	yartsu -o $@ -t 'make help' -- $(MAKE) -s help

-include .task.cfg.mk
