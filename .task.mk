# }> [github.com/daylinmorgan/task.mk] <{ #
# Copyright (c) 2022 Daylin Morgan
# MIT License
TASKMK_VERSION ?= 23.1.1
# task.mk should be included at the bottom of your Makefile with `-include .task.mk`
# See below for the standard configuration options that should be set prior to including this file.
# You can update your .task.mk with `make _update-task.mk`
# ---- [config] ---- #
HEADER_STYLE ?= b_cyan
ACCENT_STYLE ?= b_yellow
PARAMS_STYLE ?= $(ACCENT_STYLE)
GOAL_STYLE ?= $(ACCENT_STYLE)
MSG_STYLE ?= faint
DIVIDER ?= ─
DIVIDER_STYLE ?= default
HELP_SEP ?= │
WRAP ?= 100
# python f-string literals
EPILOG ?=
USAGE ?={ansi.header}usage{ansi.end}:\n  make <recipe>\n
INHERIT_SHELL ?=
# ---- [builtin recipes] ---- #
ifeq (help,$(firstword $(MAKECMDGOALS)))
  HELP_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
	export HELP_ARGS
endif
h help: ## show this help
	$(call py,help_py)
_help: export SHOW_HIDDEN=true
_help: help
ifdef PRINT_VARS
TASKMK_VARS=$(subst $(eval ) ,<|>,$(foreach v,$(PRINT_VARS),$(v)=$($(v))))
.PHONY: vars v
v vars:
	$(call py,vars_py,$(TASKMK_VARS))
endif
### |> -ws --hidden
### task.mk builtins: |> -d --hidden
_print-ansi: ## show all possible ansi color code combinations
	$(call py,print_ansi_py)
# functions to take f-string literals and pass to python print
tprint = $(call py,print_py,$(1))
tprint-verbose= $(call py-verbose,print_py,$(1))
tconfirm = $(call py,confirm_py,$(1))
_update-task.mk: ## downloads version of task.mk (TASKMK_VERSION=)
	$(call tprint,{a.b_cyan}Updating task.mk{a.end})
	curl https://raw.githubusercontent.com/daylinmorgan/task.mk/$(TASKMK_VERSION)/task.mk -o .task.mk
.PHONY: h help _help _print-ansi _update-task.mk
TASK_MAKEFILE_LIST := $(filter-out $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)),$(MAKEFILE_LIST))
export MAKEFILE_LIST MAKE TASK_MAKEFILE_LIST
ifndef INHERIT_SHELL
SHELL := $(shell which bash)
endif
# ---- [python/bash script runner] ---- #
define _newline


endef
_escape_shellstring = $(subst `,\`,$(subst ",\",$(subst $$,\$$,$(subst \,\\,$1))))
_escape_printf = $(subst \,\\,$(subst %,%%,$1))
_create_string = $(subst $(_newline),\n,$(call _escape_shellstring,$(call _escape_printf,$1)))
_printline = printf -- "<----------------------------------->\n"
ifdef TASKMK_DEBUG
define _debug_runner
@printf "$(1) Script:\n";$(_printline);
@printf "$(call _create_string,$(3))\n" | cat -n
@$(_printline)
@$(2) <(printf "$(call _create_string,$(3))")
endef
py = $(call _debug_runner,Python,python3,$($(1)))
tbash = $(call _debug_runner,Bash,bash,$($(1)))
else
py = @python3 <(printf "$(call _create_string,$($(1)))")
tbash = @bash <(printf "$(call _create_string,$($(1)))")
endif
py-verbose = python3 <(printf "$(call _create_string,$($(1)))")
# ---- [python scripts] ---- #
define  help_py
import argparse
from collections import namedtuple
import os
import re
import subprocess
import sys
from textwrap import wrap
$(utils_py)
a = ansi = Ansi(target="stdout")
MaxLens = namedtuple("MaxLens", "goal msg")
pattern = re.compile(
    r"""
(?:
  ^\#\#\#\s+ # <- raw message
  |
  ^(?:
    (?:\#\#\s+)?
    (?P<goal>.*?)(?:\s+\|>|:.*?\#\#)\s+
  ) # <- a custom goal or actual recipe
)
(?P<msg>.*?)?\s? # <- help text (optional)
(?:\|>\s+
  (?P<msgargs>.*?)
)? # <- style args (optional)
$$
""",
    re.X,
)
goal_pattern = re.compile(r"""^(?!#|\t)(.*):.*\n\t""", re.MULTILINE)
def parseargs(argstring):
    parser = argparse.ArgumentParser()
    parser.add_argument("--align")
    parser.add_argument("-d", "--divider", action="store_true")
    parser.add_argument("-ws", "--whitespace", action="store_true")
    parser.add_argument("-ms", "--msg-style", type=str)
    parser.add_argument("-gs", "--goal-style", type=str)
    parser.add_argument("--hidden", action="store_true")
    return parser.parse_args(argstring.split())
def divider(len):
    return ansi.style(f"  {cfg.div*len}", "div_style")
def gen_makefile():
    makefile = ""
    for file in os.getenv("MAKEFILE_LIST", "").split():
        with open(file, "r") as f:
            makefile += f.read() + "\n\n"
    return makefile
def parse_help(file, hidden=False):
    for line in file.splitlines():
        match = pattern.search(line)
        if match:
            if (
                not hidden
                and not os.getenv("SHOW_HIDDEN")
                and str(match.groupdict().get("goal")).startswith("_")
            ):
                pass
            else:
                yield {k: v for k, v in match.groupdict().items() if v is not None}
def recipe_help_header(goal):
    item = [
        i
        for i in list(parse_help(gen_makefile(), hidden=True))
        if "goal" in i and goal == i["goal"]
    ]
    if item:
        return fmt_goal(
            item[0]["goal"],
            item[0]["msg"],
            len(item[0]["goal"]),
            item[0].get("msgargs", ""),
        )
    else:
        return f"  {ansi.style(goal,'goal')}"
def get_goal_deps(goal="task.mk"):
    make = os.getenv("MAKE", "make")
    cmd = [make, "-p", "-n", "-i"]
    for file in os.getenv("TASK_MAKEFILE_LIST", "").split():
        cmd.extend(["-f", file])
    database = subprocess.check_output(cmd, universal_newlines=True)
    dep_pattern = re.compile(r"^" + goal + ":(.*)?")
    for line in database.splitlines():
        match = dep_pattern.search(line)
        if match and match.groups()[0]:
            return wrap(
                f"{ansi.style('deps','default')}: {ansi.style(match.groups()[0].strip(),'msg')}",
                width=cfg.wrap,
                initial_indent="  ",
                subsequent_indent="  ",
            )
def parse_goal(file, goal):
    goals = goal_pattern.findall(file)
    matched_goal = [i for i in goals if goal in i.split()]
    output = []
    if matched_goal:
        output.append(recipe_help_header(matched_goal[0]))
        deps = get_goal_deps(matched_goal[0])
        if deps:
            output.extend(deps)
        lines = file.splitlines()
        loc = [n for n, l in enumerate(lines) if l.startswith(f"{matched_goal[0]}:")][0]
        recipe = []
        for line in lines[loc + 1 :]:
            if not line.startswith("\t"):
                break
            recipe.append(f"  {line.strip()}")
        output.append(divider(max((len(l.strip()) for l in recipe))))
        output.append("\n".join(recipe))
    else:
        deps = get_goal_deps(goal)
        if deps:
            output.append(recipe_help_header(goal))
            output.extend(deps)
    if not output:
        output.append(f"{ansi.style('ERROR','b_red')}: Failed to find goal: {goal}")
    return output
def fmt_goal(goal, msg, max_goal_len, argstr):
    args = parseargs(argstr)
    goal_style = args.goal_style.strip() if args.goal_style else "goal"
    msg_style = args.msg_style.strip() if args.msg_style else "msg"
    return (
        ansi.style(f"  {goal:>{max_goal_len}}", goal_style)
        + f" $(HELP_SEP) "
        + ansi.style(msg, msg_style)
    )
def fmt_rawmsg(msg, argstr, maxlens):
    args = parseargs(argstr)
    lines = []
    msg_style = args.msg_style.strip() if args.msg_style else "msg"
    if not os.getenv("SHOW_HIDDEN") and args.hidden:
        return []
    if msg:
        if args.align == "sep":
            lines.append(
                f"{' '*(maxlens.goal+len(cfg.sep)+4)}{ansi.style(msg,msg_style)}"
            )
        elif args.align == "center":
            lines.append(f"  {ansi.style(msg.center(sum(maxlens)),msg_style)}")
        else:
            lines.append(f"  {ansi.style(msg,msg_style)}")
    if args.divider:
        lines.append(divider(len(cfg.sep) + sum(maxlens) + 2))
    if args.whitespace:
        lines.append("\n")
    return lines
def print_help():
    lines = [cfg.usage]
    items = list(parse_help(gen_makefile()))
    maxlens = MaxLens(
        *(
            max((*(len(item[x]) for item in items if x in item), 0))
            for x in ["goal", "msg"]
        )
    )
    for item in items:
        if "goal" in item:
            lines.append(
                fmt_goal(
                    item["goal"], item["msg"], maxlens.goal, item.get("msgargs", "")
                )
            )
        else:
            lines.extend(fmt_rawmsg(item["msg"], item.get("msgargs", ""), maxlens))
    lines.append(cfg.epilog)
    print("\n".join(lines))
def print_arg_help(help_args):
    print(f"{ansi.style('task.mk recipe help','header')}\n")
    for arg in help_args.split():
        print("\n".join((*parse_goal(gen_makefile(), arg), "\n")))
def main():
    help_args = os.getenv("HELP_ARGS")
    if help_args:
        print_arg_help(help_args)
        print(f"{ansi.faint}exiting task.mk{ansi.end}")
        sys.exit(1)
    else:
        print_help()
if __name__ == "__main__":
    main()
endef
define  print_py
$(utils_py)
sys.stderr.write(f"""$(2)\n""")
endef
define  print_ansi_py
$(utils_py)
import sys
codes_names = {
    getattr(ansi, attr): attr
    for attr in ansi.__dict__
    if attr
    not in [
        "target",
        "header",
        "accent",
        "params",
        "goal",
        "msg",
        "div_style",
    ]
}
for code in sorted(codes_names.keys(), key=lambda item: (len(item), item)):
    sys.stderr.write(
        f"{codes_names[code]:>20} {cfg.sep} {code+'*****'+ansi.end} {cfg.sep} {repr(code)}\n"
    )
endef
define  vars_py
import os
$(utils_py)
ansi = Ansi(target="stdout")
task_vars = tuple(v.split('=') for v in "$2".split('<|>'))
length = max((len(v[0]) for v in task_vars))
rows = (f"  {ansi.params}{v[0]:<{length}}{ansi.end} = {v[1]}" for v in task_vars)
print('\n'.join((f"{ansi.header}vars{ansi.end}:\n", *rows,'')))
endef
define  confirm_py
import sys
$(utils_py)
def confirm():
    """
    Ask user to enter Y or N (case-insensitive).
    :return: True if the answer is Y.
    :rtype: bool
    """
    answer = ""
    while answer not in ["y", "n"]:
        sys.stderr.write(f"""$(2) {a.b_red}[Y/n]{a.end} \n""")
        answer = input().lower()
    return answer == "y"
if confirm():
    sys.exit()
else:
    sys.exit(1)
endef
define  utils_py
import os
import sys
from dataclasses import dataclass
@dataclass
class Config:
    div: str
    sep: str
    epilog: str
    usage: str
    wrap: int
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
addfg = lambda byte: byte + 30
addbg = lambda byte: byte + 40
class Ansi:
    """ANSI escape codes"""
    def __init__(self, target="stdout"):
        self.target = target
        self.setcode("end", "\033[0m")
        self.setcode("default", "\033[38m")
        self.setcode("bg_default", "\033[48m")
        for name, byte in color2byte.items():
            self.setcode(name, f"\033[{addfg(byte)}m")
            self.setcode(f"b_{name}", f"\033[1;{addfg(byte)}m")
            self.setcode(f"d_{name}", f"\033[2;{addfg(byte)}m")
            for bgname, bgbyte in color2byte.items():
                self.setcode(
                    f"{name}_on_{bgname}", f"\033[{addbg(bgbyte)};{addfg(byte)}m"
                )
        for name, byte in state2byte.items():
            self.setcode(name, f"\033[{byte}m")
        self.add_cfg()
    def setcode(self, name, escape_code):
        """create attr for style and escape code"""
        if os.getenv("NO_COLOR", False):
            setattr(self, name, "")
        elif (self.target == "stderr" and not sys.stderr.isatty()) or (
            self.target == "stdout" and not sys.stdout.isatty()
        ):
            setattr(self, name, "")
        else:
            setattr(self, name, escape_code)
    def custom(self, fg=None, bg=None):
        """use custom color"""
        code, end = "\033[", "m"
        if not sys.stdout.isatty() or os.getenv("NO_COLOR", False):
            return ""
        else:
            if fg:
                if isinstance(fg, int):
                    code += f"38;5;{fg}"
                elif (isinstance(fg, list) or isinstance(fg, tuple)) and len(fg) == 1:
                    code += f"38;5;{fg[0]}"
                elif (isinstance(fg, list) or isinstance(fg, tuple)) and len(fg) == 3:
                    code += f"38;2;{';'.join((str(i) for i in fg))}"
                else:
                    print("Expected one or three values for fg as a list")
                    sys.exit(1)
            if bg:
                if isinstance(bg, int):
                    code += f"{';' if fg else ''}48;5;{bg}"
                elif (isinstance(bg, list) or isinstance(bg, tuple)) and len(bg) == 1:
                    code += f"{';' if fg else ''}48;5;{bg[0]}"
                elif (isinstance(bg, list) or isinstance(bg, tuple)) and len(bg) == 3:
                    code += f"{';' if fg else ''}48;2;{';'.join((str(i) for i in bg))}"
                else:
                    print("Expected one or three values for bg as a list")
                    sys.exit(1)
            return code + end

    def add_cfg(self):
        cfg_styles = {
            "header": "$(HEADER_STYLE)",
            "accent": "$(ACCENT_STYLE)",
            "params": "$(PARAMS_STYLE)",
            "goal": "$(GOAL_STYLE)",
            "msg": "$(MSG_STYLE)",
            "div_style": "$(DIVIDER_STYLE)",
        }
        for name, style in cfg_styles.items():
            self.setcode(name, getattr(self, style))
    def style(self, text, style):
        if style not in self.__dict__:
            print(f"unknown style: {style}")
            sys.exit(1)
        else:
            return f"{self.__dict__[style]}{text}{self.__dict__['end']}"
a = ansi = Ansi()
cfg = Config(
    "$(DIVIDER)", "$(HELP_SEP)", f"""$(EPILOG)""", f"""$(USAGE)""", int("$(WRAP)")
)
endef
