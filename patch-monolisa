#!/usr/bin/env python3

import argparse
import itertools
import os
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import List, Set


class Color:
    def __init__(self):
        self.bold = "\033[1m"
        self.red = "\033[1;31m"
        self.green = "\033[1;32m"
        self.yellow = "\033[1;33m"
        self.magenta = "\033[1;35m"
        self.cyan = "\033[1;36m"
        self.end = "\033[0m"

        if os.getenv("NO_COLOR"):
            for attr in self.__dict__:
                setattr(self, attr, "")


class Spinner:
    # https://raw.githubusercontent.com/Tagar/stuff/master/spinner.py
    def __init__(self, message, delay=0.1):
        # self.spinner = itertools.cycle(["-", "/", "|", "\\"])
        self.spinner = itertools.cycle([f"{c}  " for c in "⣾⣽⣻⢿⡿⣟⣯⣷"])

        self.delay = delay
        self.busy = False
        self.spinner_visible = False
        sys.stdout.write(message)

    def write_next(self):
        with self._screen_lock:
            if not self.spinner_visible:
                sys.stdout.write(next(self.spinner))
                self.spinner_visible = True
                sys.stdout.flush()

    def remove_spinner(self, cleanup=False):
        with self._screen_lock:
            if self.spinner_visible:
                # sys.stdout.write("\b")
                sys.stdout.write("\b\b\b")
                self.spinner_visible = False
                if cleanup:
                    sys.stdout.write(" ")  # overwrite spinner with blank
                    # sys.stdout.write("\r")  # move to next line
                    sys.stdout.write("\r\033[K")
                sys.stdout.flush()

    def spinner_task(self):
        while self.busy:
            self.write_next()
            time.sleep(self.delay)
            self.remove_spinner()

    def __enter__(self):
        if sys.stdout.isatty():
            self._screen_lock = threading.Lock()
            self.busy = True
            self.thread = threading.Thread(target=self.spinner_task)
            self.thread.start()

    def __exit__(self, exc_type, exc_val, exc_traceback):
        if sys.stdout.isatty():
            self.busy = False
            self.remove_spinner(cleanup=True)
        else:
            sys.stdout.write("\r")


def run_cmd(
    command: List[str], fontfile: Path, verbose: bool, ignore_error: bool = False
) -> None:
    """run a subcommand
    Args:
        command: Subcommand to be run in subprocess.
        fontfile: Path to font file that will be patched
        verbose: If true, print subcommand output.
    """

    p = subprocess.run(
        command,
        stdout=None if verbose else subprocess.PIPE,
        stderr=None if verbose else subprocess.STDOUT,
        errors="replace",  # different encoding should hopefully just result in bad UI but working fonts
    )

    if p.returncode != 0 and not ignore_error:
        print()
        print(p.stdout)
        err_msg = (
            f"{color.red}ERROR{color.end}: patching font file "
            f"{fontfile.name} see above for font-patcher output"
        )
        echo(err_msg, hue="red")
        sys.exit(1)


def get_args():
    parser = argparse.ArgumentParser(prog="patch-monolisa")
    parser.add_argument(
        "-f",
        "--font-path",
        help="path to font files",
        action="append",
        type=Path,
        required=True,
    )
    parser.add_argument(
        "-o", "--output", help="target output directory", default="patched", type=Path
    )
    parser.add_argument(
        "-d", "--docker", help="use nerdfonts/patcher docker image", action="store_true"
    )
    parser.add_argument(
        "-v", "--verbose", help="show subprocess output", action="store_true"
    )
    return parser.parse_known_args()


def patch_single_font(
    font_path: Path, output_dir: Path, fp_args: str, verbose: bool
) -> None:
    # update display name to full resolved path
    rel_path = font_path.absolute()
    output_path = (output_dir / rel_path.parent.name).absolute()
    output_path.mkdir(exist_ok=True, parents=True)

    cmd = [
        "fontforge",
        "-script",
        f"{Path(__file__).parent}/font-patcher",
        "--glyphdir",
        f"{Path(__file__).parent}/src/glyphs/",
        "-out",
        f"{output_path}",
        f"{font_path.absolute()}",
    ]

    if fp_args:
        cmd += fp_args.split(" ")

    if verbose:
        echo(f"cmd: {' '.join(cmd)}")
        run_cmd(cmd, font_path, verbose)
    else:
        with Spinner(
            f"{color.yellow}:::{color.end} Patching font "
            f"{color.bold}{font_path.name}{color.end}... "
        ):
            run_cmd(cmd, font_path, verbose)

    echo(f"{rel_path} patched!", hue="green")


def collect_files_by_dir(fontfiles: List[Path]) -> Set[Path]:
    return set([f.parent.absolute() for f in fontfiles])


def patch_font_dir_docker(
    font_dir_path: Path, output_dir: Path, fp_args: str, verbose: bool
) -> None:
    output_path = (
        output_dir / font_dir_path.relative_to(font_dir_path.parent)
    ).absolute()
    output_path.mkdir(exist_ok=True, parents=True)

    cmd = [
        "docker",
        "run",
        "--rm",
        "-v",
        f"{font_dir_path}:/in",
        "-v",
        f"{output_path}:/out",
        "nerdfonts/patcher",
    ]

    if fp_args:
        cmd += fp_args.split(" ")

    # ignoring the fact that docker exits with code 1
    if verbose:
        echo(f"cmd: {' '.join(cmd)}")
        run_cmd(cmd, font_dir_path, verbose, ignore_error=True)
    else:
        with Spinner(
            f"{color.yellow}:::{color.end} Patching fonts in "
            f"{color.bold}{font_dir_path.name}{color.end}... "
        ):
            run_cmd(cmd, font_dir_path, verbose, ignore_error=True)

    echo(f"{font_dir_path.name}/ fonts patched!", hue="green")


def get_font_files(p):
    exts = ["otf", "ttf", "woff", "woff2"]

    if p.is_file():
        return (p,)

    if p.is_dir():
        return (f for ext in exts for f in p.glob(f"**/*.{ext}"))
    return ()


def echo(msg: str, header=False, hue="cyan") -> None:
    if header:
        print(f"==>{color.magenta} {msg} {color.end}<==")
    else:
        print(f"{color.__dict__[hue]}::{color.end} {msg}")


def main():
    echo("MonoLisa NerdFont Patcher", header=True)
    args, fp_args = get_args()
    fp_args = " ".join(fp_args)
    if fp_args:
        echo(f"Flags passed to font-patcher: {fp_args}")
    if args.verbose:
        echo("Patching the following files")
        for fontfile in args.font_path:
            sys.stdout.write(f"  {color.magenta}->{color.end} {fontfile}\n")

    fontfiles = [f for p in args.font_path for f in get_font_files(p)]

    if args.docker:
        echo("==> DOCKER MODE ENABLED")
        for font_dir in collect_files_by_dir(fontfiles):
            patch_font_dir_docker(font_dir, args.output, fp_args, args.verbose)
    else:
        for fontfile in fontfiles:
            patch_single_font(Path(fontfile), args.output, fp_args, args.verbose)

    echo("fonts are patched", hue="green")
    echo("Happy typing!", hue="green")


if __name__ == "__main__":
    color = Color()
    main()
