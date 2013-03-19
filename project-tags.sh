#!/bin/bash

PERSONALDEV="/sites/personaldev/igarcia"

for D in "${PERSONALDEV}"/*
do
  if [ -d "$D" ]; then
    cd $D
    touch tags && rm tags && ctags -R --languages=php . > /dev/null 2>&1
  fi
done