#!/bin/bash
set -x

odin build . -out=galac && ./galac main.gala -o main
export LD_LIBRARY_PATH=./ && ./main
