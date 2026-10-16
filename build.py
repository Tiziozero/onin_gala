#!/usr/bin/env python3
"""Build galac, then compile and run gala programs.

  ./build.py                 build galac, compile main.gala, run it
  ./build.py build           build galac, compile main.gala
  ./build.py memcheck        like run, but under valgrind
  ./build.py test [filter]   compile + run every tests/test_*.gala
  --no-build                 skip the `odin build` step
"""
import argparse
import glob
import os
import shutil
import subprocess
import sys

GALAC = "./galac"
MAIN_SRC = "main.gala"
PROGRAM = "program"
TEST_DIR = "tests"
TEST_BIN = os.path.join(TEST_DIR, "main")  # "main" is gitignored
TEST_TIMEOUT = 10  # seconds; catches infinite loops

ENV = os.environ.copy()
ENV["LD_LIBRARY_PATH"] = ".:/" + (":" + ENV["LD_LIBRARY_PATH"] if "LD_LIBRARY_PATH" in ENV else "")


def paint(text, code):
    return f"\033[{code}m{text}\033[0m" if sys.stdout.isatty() else text


def green(t): return paint(t, 32)
def red(t): return paint(t, 31)
def dim(t): return paint(t, 2)


def indent(text, prefix="    "):
    return "\n".join(prefix + line for line in text.rstrip().splitlines())


def as_text(x):
    if x is None:
        return ""
    return x.decode(errors="replace") if isinstance(x, bytes) else x


def run_captured(cmd, timeout=None):
    """Run cmd; return (returncode, stdout+stderr). returncode is None on timeout."""
    try:
        p = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            env=ENV,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as e:
        return None, as_text(e.stdout)
    return p.returncode, p.stdout


def build_galac():
    code, out = run_captured(["odin", "build", ".", "-out=galac"])
    if out.strip():
        print(out.rstrip())
    print("odin returned", code)
    return code == 0


def compile_gala(src, out):
    """Compile src to out. Removes a stale binary first so a failed compile can't run old code."""
    if os.path.exists(out):
        os.remove(out)
    return run_captured([GALAC, "-o", out, src])


# ---------- run / memcheck ----------

def run_program():
    print("running.", flush=True)
    cmd = ["stdbuf", "-oL"] if shutil.which("stdbuf") else []
    p = subprocess.Popen(
        cmd + ["./" + PROGRAM],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        env=ENV,
    )
    for line in p.stdout:
        print(line, end="", flush=True)
    p.stdout.close()
    result = p.wait()
    print(f"\nprogram returned {result}")
    return result


def memcheck():
    result = subprocess.run(
        ["valgrind", "--leak-check=full", PROGRAM], env=ENV
    ).returncode
    print("memcheck returned", result)
    return result


# ---------- tests ----------

def judge(code, output):
    """Return (passed, reason). The test programs exit 0 even when checks fail,
    so the output decides: no `FAIL:` lines and an `all passed` line."""
    if code is None:
        return False, f"timed out after {TEST_TIMEOUT}s"
    if code != 0:
        return False, f"exited with code {code}"
    lines = output.splitlines()
    if any(line.startswith("FAIL:") for line in lines):
        return False, "checks failed"
    if not any("all passed" in line for line in lines):
        return False, "no 'all passed' line (crashed early?)"
    return True, ""


def run_tests(name_filter):
    files = sorted(glob.glob(os.path.join(TEST_DIR, "test_*.gala")))
    if name_filter:
        files = [f for f in files if name_filter in os.path.basename(f)]
    if not files:
        print("no tests found")
        return False

    failed = []
    for src in files:
        name = os.path.basename(src)

        code, output = compile_gala(src, TEST_BIN)
        if code != 0:
            print(f"{red('FAIL')} {name}: compile error (code {code})")
            print(indent(output))
            failed.append(name)
            continue

        code, output = run_captured([TEST_BIN], timeout=TEST_TIMEOUT)
        passed, reason = judge(code, output)
        if passed:
            print(f"{green('ok')}   {name}")
            continue

        print(f"{red('FAIL')} {name}: {reason}")
        fails = [l for l in output.splitlines() if l.startswith("FAIL:")]
        print(indent("\n".join(fails) if fails else output))
        failed.append(name)

    print()
    print(f"{len(files) - len(failed)}/{len(files)} passed")
    return not failed


# ---------- main ----------

def main():
    ap = argparse.ArgumentParser(description="Build and run gala programs.")
    ap.add_argument("command", nargs="?", default="run",
                    choices=["run", "build", "memcheck", "test"])
    ap.add_argument("filter", nargs="?", default="",
                    help="for `test`: only run files whose name contains this")
    ap.add_argument("--no-build", action="store_true",
                    help="skip the `odin build` step")
    args = ap.parse_args()

    if not args.no_build and not build_galac():
        sys.exit(1)

    if args.command == "test":
        sys.exit(0 if run_tests(args.filter) else 1)

    code, output = compile_gala(MAIN_SRC, PROGRAM)
    if output.strip():
        print(output.rstrip())
    print("compiler returned", code)
    if code != 0:
        sys.exit(code)

    if args.command == "build":
        return

    try:
        result = memcheck() if args.command == "memcheck" else run_program()
    except KeyboardInterrupt:
        print("^C - canceling run.")
        return
    if result != 0:
        sys.exit(result)


if __name__ == "__main__":
    main()
