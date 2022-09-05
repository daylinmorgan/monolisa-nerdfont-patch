# }> [github.com/daylinmorgan/task.mk] <{ #
# Copyright (c) 2022 Daylin Morgan
# MIT License
# 22.9.5
#
# task.mk should be included at the bottom of your Makefile.
# See below for the standard configuration options that should be set prior to including this file.
# You can update your .task.mk with `make _update-task.mk`

# ---- CONFIG ---- #
HEADER_COLOR ?= b_cyan
PARAMS_COLOR ?= b_magenta
ACCENT_COLOR ?= b_yellow
GOAL_COLOR ?= $(ACCENT_COLOR)
MSG_COLOR ?= faint
HELP_SEP ?= |
HELP_SORT ?= # sort goals alphabetically

# python f-string literals
EPILOG ?=
define USAGE ?=
{ansi.$(HEADER_COLOR)}usage{ansi.end}:
  make <recipe>

endef

# ---- [buitlin recipes] ---- #


## h, help | show this help
.PHONY: help h
help h:
	$(call py,help_py)

.PHONY: _help
_help: export SHOW_HIDDEN=true
_help: help

ifdef PRINT_VARS

$(foreach v,$(PRINT_VARS),$(eval export $(v)))

.PHONY: vars v
vars v:
	$(call py,vars_py,$(PRINT_VARS))

endif

## _print-ansi | show all possible ansi color code combinations
.PHONY:
_print-ansi:
	$(call py,print_ansi_py)

# functions to take f-string literals and pass to python print
tprint = $(call py,info_py,$(1))
tprint-sh = $(call pysh,info_py,$(1))

_update-task.mk:
	$(call tprint,Updating task.mk)
	curl https://raw.githubusercontent.com/daylinmorgan/task.mk/main/task.mk -o .task.mk

export MAKEFILE_LIST

# ---- [python/bash script runner] ---- #

# modified from https://unix.stackexchange.com/a/223093
define \n


endef

escape_shellstring = $(subst `,\`,$(subst ",\",$(subst $$,\$$,$(subst \,\\,$1))))

escape_printf = $(subst \,\\,$(subst %,%%,$1))

create_string = $(subst $(\n),\n,$(call escape_shellstring,$(call escape_printf,$1)))


ifdef DEBUG
define py
@printf "Python Script:\n"
@printf -- "----------------\n"
@printf "$(call create_string,$($(1)))\n"
@printf -- "----------------\n"
@printf "$(call create_string,$($(1)))" | python3
endef
define tbash
@printf "Bash Script:\n"
@printf -- "----------------\n"
@printf "$(call create_string,$($(1)))\n"
@printf -- "----------------\n"
@printf "$(call create_string,$($(1)))" | bash
endef
else
py = @printf "$(call create_string,$($(1)))" | python3
tbash = @printf "$(call create_string,$($(1)))" | bash
endif

pysh = printf "$(call create_string,$($(1)))" | python3

# ---- [python scripts] ---- #


define  help_py


import os
import re

$(ansi_py)

pattern = re.compile(r"^## (.*) \| (.*)")

makefile = ""
for file in os.getenv("MAKEFILE_LIST").split():
    with open(file, "r") as f:
        makefile += f.read() + "\n\n"


def get_help(file):
    for line in file.splitlines():
        match = pattern.search(line)
        if match:
            if not os.getenv("SHOW_HIDDEN") and match.groups()[0].startswith("_"):
                continue
            else:
                yield match.groups()


print(f"""$(USAGE)""")

goals = list(get_help(makefile))
if os.getenv("SORT_HELP",False):
    goals.sort(key=lambda i: i[0])
goal_len = max(len(goal[0]) for goal in goals)

for goal, msg in goals:
    print(
        f"{ansi.$(GOAL_COLOR)}{goal:>{goal_len}}{ansi.end} $(HELP_SEP) {ansi.$(MSG_COLOR)}{msg}{ansi.end}"
    )

print(f"""$(EPILOG)""")


endef

define  ansi_py


import os
import sys

color2byte = dict(
    black=0,
    red=1,
    green=2,
    yellow=3,
    blue=4,
    magenta=5,
    cyan=6,
    white=7,
)

state2byte = dict(
    bold=1, faint=2, italic=3, underline=4, blink=5, fast_blink=6, crossed=9
)


def fg(byte):
    return 30 + byte


def bg(byte):
    return 40 + byte


class Ansi:
    """ANSI color codes"""

    def setcode(self, name, escape_code):
        if not sys.stdout.isatty() or os.getenv("NO_COLOR", False):
            setattr(self, name, "")
        else:
            setattr(self, name, escape_code)

    def __init__(self):
        self.setcode("end", "\033[0m")
        for name, byte in color2byte.items():
            self.setcode(name, f"\033[{fg(byte)}m")
            self.setcode(f"b_{name}", f"\033[1;{fg(byte)}m")
            self.setcode(f"d_{name}", f"\033[2;{fg(byte)}m")
            for bgname, bgbyte in color2byte.items():
                self.setcode(f"{name}_on_{bgname}", f"\033[{bg(bgbyte)};{fg(byte)}m")
        for name, byte in state2byte.items():
            self.setcode(name, f"\033[{byte}m")


a = ansi = Ansi()


endef

define  info_py


$(ansi_py)

print(f"""$(2)""")


endef

define  print_ansi_py


$(ansi_py)

codes_names = {
    getattr(ansi, attr): attr
    for attr in dir(ansi)
    if attr[0:1] != "_" and attr != "end" and attr != "setcode"
}
for code in sorted(codes_names.keys(), key=lambda item: (len(item), item)):
    print("{:>20} {}".format(codes_names[code], code + "******" + ansi.end))



endef

define  vars_py



import os

$(ansi_py)

vars = "$2".split()
length = max((len(v) for v in vars))

print(f"{ansi.$(HEADER_COLOR)}vars:{ansi.end}\n")

for v in vars:
    print(f"  {ansi.b_magenta}{v:<{length}}{ansi.end} = {os.getenv(v)}")

print()


endef

