#!/bin/bash
set -e

odin run .
clang -o a.out a.ll
./a.out
echo "res:"
echo $?
