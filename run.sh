#!/bin/bash
set -x

odin run .
clang -o a.out a.ll
./a.out
echo $?
echo "end"
