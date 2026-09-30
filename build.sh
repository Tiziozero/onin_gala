#!/usr/bin/env bash
# usage: ./run_tests.sh   (from the dir containing galac, or set GALAC)
# Needs: gcc, galac. Adjust OUT if galac writes the binary somewhere else.

GALAC=${GALAC:-./galac}
OUT=${OUT:-./main}
LIB=./libfntest.so
TMP=$(mktemp -d)
HERE=$(cd "$(dirname "$0")" && pwd)

pass=0; fail=0; xfail=0; xpass=0

gcc -shared -fPIC -o "$LIB" "$HERE/testlib.c" || { echo "couldn't build $LIB"; exit 1; }

# The IR you showed uses @gala.mod_main.main and the C wrapper calls it by
# that name, so the entry point seems tied to the file being called main.gala.
# Compile every test under that name.
compile() {
    cp "$1" "$TMP/main.gala"
    "$GALAC" "$TMP/main.gala" -l "$LIB" -d 2>&1
}

ok()   { echo "PASS  $1"; pass=$((pass+1)); }
bad()  { echo "FAIL  $1"; [ -n "$2" ] && echo "$2" | sed 's/^/      | /'; fail=$((fail+1)); }

# ---------------------------------------------------------------- positive
echo "== positive =="
out=$(compile "$HERE/positive.gala")
if [ $? -ne 0 ]; then
    bad "positive.gala failed to compile" "$out"
else
    run=$(LD_LIBRARY_PATH=. "$OUT" 2>&1)
    rc=$?
    n_ok=$(grep -c '^ok ' <<<"$run")
    if [ $rc -eq 0 ] && [ "$n_ok" -eq 16 ] && ! grep -q FAIL <<<"$run"; then
        ok "positive.gala (16/16)"
    else
        bad "positive.gala ($n_ok/16 ok, exit $rc)" "$run"
    fi
fi

# ---------------------------------------------------------------- negative
# Must fail to compile AND mention a mismatch (a link error alone would also
# be a non-zero exit, which would hide a checker that wrongly accepts).
echo "== negative (must be rejected) =="

PRELUDE='extern fn printf(fmt: ^byte, data: ..any);
extern fn takes_bin(f: fn(l: i32, r: i32): i32);'

neg() {
    local name=$1 src=$2 f="$TMP/$1.gala"
    printf '%s\n%s\n' "$PRELUDE" "$src" > "$f"
    local out; out=$(compile "$f"); local rc=$?
    if [ $rc -ne 0 ] && grep -qiE "mismatch|don't match" <<<"$out"; then
        ok "$name"
    else
        bad "$name (exit $rc, expected a type mismatch)" "$out"
    fi
}

neg arity '
fn one(l: i32): i32 { return l; }
fn main() { takes_bin(one); return; }'

neg arg_type '
fn ff(l: i32, r: f32): i32 { return l; }
fn main() { takes_bin(ff); return; }'

neg ret_type '
fn rv(l: i32, r: i32): i64 { return 0; }
fn main() { takes_bin(rv); return; }'

neg ret_void '
fn vv(l: i32, r: i32) { return; }
fn main() { takes_bin(vv); return; }'

neg not_a_fn '
fn main() { takes_bin(5); return; }'

neg nested_arg '
extern fn takes_nested(f: fn(g: fn(): i32): i32);
fn bad(g: fn(): i64): i32 { return 0; }
fn main() { takes_nested(bad); return; }'

neg nested_ret '
extern fn takes_rf(f: fn(): fn(): i32);
fn ret64(): i64 { return 0; }
fn rf64(): fn(): i64 { return ret64; }
fn main() { takes_rf(rf64); return; }'

neg any_vs_concrete '
extern fn takes_any(f: fn(v: any));
fn i64f(v: i64) { return; }
fn main() { takes_any(i64f); return; }'

neg variadic_vs_fixed '
extern fn takes_var(f: fn(s: ^byte, d: ..any));
fn nonvar(s: ^byte) { return; }
fn main() { takes_var(nonvar); return; }'

neg struct_nominal '
struct A { x: i32, }
struct B { x: i32, }
extern fn takes_a(f: fn(p: A));
fn onb(p: B) { return; }
fn main() { takes_a(onb); return; }'

neg local_var_mismatch '
fn ff(l: i32, r: f32): i32 { return l; }
fn main() {
    f : fn(l: i32, r: i32): i32 = ff;
    return;
}'

# ------------------------------------------------------------ known issues
# These SHOULD compile. They are expected to fail today; XPASS means fixed.
echo "== known issues (expected to fail for now) =="

known() {
    local name=$1 src=$2 f="$TMP/$1.gala"
    printf '%s\n%s\n' "$PRELUDE" "$src" > "$f"
    local out; out=$(compile "$f"); local rc=$?
    if [ $rc -eq 0 ]; then
        echo "XPASS $name  (fixed, move it to positive)"; xpass=$((xpass+1))
    else
        echo "$f"
        cat "$f"
        echo "XFAIL $name"; echo "$out" | head -4 | sed 's/^/      | /'; xfail=$((xfail+1))
    fi
}

# .FixedSizeArray compares elem types by raw id, so the two [2]fn(...) specs
# (different ids) don't match.
known array_of_fn '
fn main() {
    t : [2]fn(l: i32, r: i32): i32 = [2]fn(l: i32, r: i32): i32{};
    return;
}'

# Spec arg names go through new_object/name_exists, which walks parent scopes,
# so a spec arg named like an enclosing local collides.
known spec_arg_shadows_local '
fn other(q: i32) { return; }
fn main() {
    q : i32 = 1;
    f : fn(q: i32) = other;
    return;
}'

# Same thing against a global name.
known spec_arg_shadows_global '
extern fn takes_shadow(f: fn(printf: i32));
fn main() { return; }'

echo
echo "pass=$pass fail=$fail xfail=$xfail xpass=$xpass"
rm -rf "$TMP"
[ $fail -eq 0 ]
