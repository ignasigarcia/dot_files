#!/bin/bash

for D in "${PERSONALDEV}"/*
do
  if [ -d "$D" ]; then
    cd $D
    touch tags && rm tags && ${CTAGS} . > /dev/null 2>&1
  fi
done
