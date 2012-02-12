#!/bin/sh

rdmd --main -unittest -gc \
-I/home/vnayar/d/include/d -L-L/home/vnayar/d/lib \
-L-ldl -L-lGL -L-lSDL_image -L-lDerelictSDL -L-lDerelictUtil -L-lDerelictGL \
$1
