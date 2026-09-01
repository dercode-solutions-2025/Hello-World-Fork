#!/usr/bin/env bash
# Runs every Hello, World! it possibly can and keeps score.
# Usage: ./run.sh [--cursed]

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

EXPECTED="Hello, World!"
PASS=0; FAIL=0; SKIP=0
FAILED_LANGS=()

c_green=$'\033[32m'; c_red=$'\033[31m'; c_dim=$'\033[2m'; c_yellow=$'\033[33m'; c_off=$'\033[0m'

# try <display name> <required binary> <command...>
try() {
    local name="$1" bin="$2"; shift 2
    if ! command -v "$bin" >/dev/null 2>&1; then
        printf '  %s%-16s  skipped (no %s)%s\n' "$c_dim" "$name" "$bin" "$c_off"
        SKIP=$((SKIP + 1))
        return
    fi
    local out
    out="$("$@" 2>&1)"
    if [[ "$out" == *"$EXPECTED"* ]]; then
        printf '  %s%-16s  ok%s\n' "$c_green" "$name" "$c_off"
        PASS=$((PASS + 1))
    else
        printf '  %s%-16s  FAILED%s %s\n' "$c_red" "$name" "$c_off" "${out:0:60}"
        FAIL=$((FAIL + 1))
        FAILED_LANGS+=("$name")
    fi
}

# compile_run <display name> <compiler> <source> <compile args...>
# Expects the produced binary at $BUILD/out
compile_run() {
    local name="$1" cc="$2"; shift 2
    if ! command -v "$cc" >/dev/null 2>&1; then
        printf '  %s%-16s  skipped (no %s)%s\n' "$c_dim" "$name" "$cc" "$c_off"
        SKIP=$((SKIP + 1))
        return
    fi
    local log
    if ! log="$("$@" 2>&1)"; then
        printf '  %s%-16s  FAILED%s (compile) %s\n' "$c_red" "$name" "$c_off" "${log:0:60}"
        FAIL=$((FAIL + 1)); FAILED_LANGS+=("$name")
        return
    fi
    local out; out="$("$BUILD/out" 2>&1)"
    if [[ "$out" == *"$EXPECTED"* ]]; then
        printf '  %s%-16s  ok%s\n' "$c_green" "$name" "$c_off"
        PASS=$((PASS + 1))
    else
        printf '  %s%-16s  FAILED%s %s\n' "$c_red" "$name" "$c_off" "${out:0:60}"
        FAIL=$((FAIL + 1)); FAILED_LANGS+=("$name")
    fi
}

L="$ROOT/languages"

echo
echo "Interpreted"
echo "-----------"
try Python      python3   python3 "$L/hello.py"
try Ruby        ruby      ruby "$L/hello.rb"
try Perl        perl      perl "$L/hello.pl"
try PHP         php       php "$L/hello.php"
try JavaScript  node      node "$L/hello.js"
try TypeScript  npx       npx -y tsx "$L/hello.ts"
try Lua         lua       lua "$L/hello.lua"
try Bash        bash      bash "$L/hello.sh"
try PowerShell  pwsh      pwsh -File "$L/hello.ps1"
try Tcl         tclsh     tclsh "$L/hello.tcl"
try Julia       julia     julia "$L/hello.jl"
try R           Rscript   Rscript "$L/hello.r"
try Elixir      elixir    elixir "$L/hello.exs"
try Groovy      groovy    groovy "$L/hello.groovy"
try Clojure     clojure   clojure -M "$L/hello.clj"
try AWK         awk       awk -f "$L/hello.awk"
try SQL         sqlite3   sqlite3 -init /dev/null :memory: ".read $L/hello.sql"
try Prolog      swipl     swipl -q -g main -t halt "$L/hello.pro"
try Make        make      make -s -f "$L/hello.mk"
try EmacsLisp   emacs     emacs --batch --script "$L/hello.el"
try Vimscript   vim       vim -es -u NONE -c "source $L/hello.vim" -c "qa!"
try Scheme      guile     guile -q "$L/hello.scm"
try CommonLisp  sbcl      sbcl --script "$L/hello.lisp"
try Erlang      escript   escript "$L/hello.erl"
try Dart        dart      dart run "$L/hello.dart"
try Swift       swift     swift "$L/hello.swift"

echo
echo "Compiled"
echo "--------"
compile_run C        gcc      gcc      "$L/hello.c"    -o "$BUILD/out"
compile_run "C++"    g++      g++      "$L/hello.cpp"  -o "$BUILD/out"
compile_run Rust     rustc    rustc    "$L/hello.rs"   -o "$BUILD/out"
compile_run Go       go       go       build -o "$BUILD/out" "$L/hello.go"
compile_run Zig      zig      zig      build-exe "$L/hello.zig" -femit-bin="$BUILD/out"
compile_run Nim      nim      nim      c --hints:off -o:"$BUILD/out" "$L/hello.nim"
compile_run Crystal  crystal  crystal  build -o "$BUILD/out" "$L/hello.cr"
compile_run D        ldc2     ldc2     -of="$BUILD/out" "$L/hello.d"
compile_run Odin     odin     odin     build "$L/hello.odin" -file -out:"$BUILD/out"
compile_run Haskell  ghc      ghc      -v0 -o "$BUILD/out" -outputdir "$BUILD" "$L/hello.hs"
compile_run OCaml    ocamlfind ocamlfind ocamlopt -package "" -o "$BUILD/out" "$L/hello.ml"
compile_run Fortran  gfortran gfortran "$L/hello.f90" -o "$BUILD/out"
compile_run COBOL    cobc     cobc     -x -o "$BUILD/out" "$L/hello.cob"
compile_run Pascal   fpc      fpc      -o"$BUILD/out" "$L/hello.pas"
compile_run Ada      gnatmake gnatmake -o "$BUILD/out" -D "$BUILD" "$L/hello.adb"
compile_run BASIC    fbc      fbc      -x "$BUILD/out" "$L/hello.bas"
compile_run ObjC     gnustep-config clang "$L/hello.m" -o "$BUILD/out" $(gnustep-config --objc-flags 2>/dev/null) $(gnustep-config --base-libs 2>/dev/null)

if command -v nasm >/dev/null 2>&1 && command -v ld >/dev/null 2>&1; then
    if nasm -f elf64 "$L/hello.asm" -o "$BUILD/hello.o" >/dev/null 2>&1 \
       && ld "$BUILD/hello.o" -o "$BUILD/out" >/dev/null 2>&1; then
        out="$("$BUILD/out")"
        if [[ "$out" == *"$EXPECTED"* ]]; then
            printf '  %s%-16s  ok%s\n' "$c_green" Assembly "$c_off"; PASS=$((PASS + 1))
        else
            printf '  %s%-16s  FAILED%s\n' "$c_red" Assembly "$c_off"; FAIL=$((FAIL + 1)); FAILED_LANGS+=(Assembly)
        fi
    else
        printf '  %s%-16s  FAILED%s (assemble)\n' "$c_red" Assembly "$c_off"; FAIL=$((FAIL + 1)); FAILED_LANGS+=(Assembly)
    fi
else
    printf '  %s%-16s  skipped (no nasm)%s\n' "$c_dim" Assembly "$c_off"; SKIP=$((SKIP + 1))
fi

echo
echo "Ceremony required"
echo "-----------------"
if command -v javac >/dev/null 2>&1; then
    try Java java sh -c "cd '$BUILD' && javac -d '$BUILD' '$L/Hello.java' && java -cp '$BUILD' Hello"
else
    try Java java java "$L/Hello.java"
fi
try Kotlin kotlinc sh -c "kotlinc '$L/hello.kt' -include-runtime -d '$BUILD/h.jar' 2>/dev/null && java -jar '$BUILD/h.jar'"
try Scala  scala   scala "$L/hello.scala"
try "C#"   dotnet  sh -c "cd '$BUILD' && dotnet new console -o cs >/dev/null 2>&1 && cp '$L/hello.cs' cs/Program.cs && dotnet run --project cs 2>/dev/null"
try "F#"   dotnet  sh -c "cd '$BUILD' && dotnet new console -lang F# -o fs >/dev/null 2>&1 && cp '$L/hello.fs' fs/Program.fs && dotnet run --project fs 2>/dev/null"

if [[ "${1:-}" == "--cursed" ]]; then
    echo
    echo "Cursed"
    echo "------"
    C="$ROOT/cursed"
    try Brainfuck bf         bf "$C/hello.bf"
    try Befunge   befunge    befunge "$C/hello.b93"
    try LOLCODE   lci        lci "$C/hello.lol"
    try Malbolge  malbolge   malbolge "$C/hello.mal"
    try INTERCAL  ick        ick "$C/hello.i"
    try Shakespeare spl2c    spl2c "$C/hello.spl"
fi

TOTAL=$((PASS + FAIL))
echo
printf '%s─────────────────────────────────────%s\n' "$c_dim" "$c_off"
printf '  %sPASS %d%s   %sFAIL %d%s   %sSKIP %d%s\n' \
    "$c_green" "$PASS" "$c_off" "$c_red" "$FAIL" "$c_off" "$c_yellow" "$SKIP" "$c_off"
if (( FAIL > 0 )); then
    printf '  broken: %s\n' "${FAILED_LANGS[*]}"
fi
if (( SKIP > 0 )); then
    printf '  %s%d toolchains not installed. Your disk thanks you.%s\n' "$c_dim" "$SKIP" "$c_off"
fi
echo

exit $(( FAIL > 0 ))
