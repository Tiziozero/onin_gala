#!/bin/bash
# set -x

# odin build . -debug
# valgrind --leak-check=full --trace-children=no ./onin_gala

odin build . -out=galac
./galac main.gala -o main
# echo $?
