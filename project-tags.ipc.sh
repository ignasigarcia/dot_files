#!/bin/bash

for D in "$1"/*
do
  if [ -d "$D" ]; then
    cd $D
    ctags -R --exclude=.svn --tag-relative=yes --regex-PHP='/abstract\s+class\s+([^ ]+)/\1/c/' --regex-PHP='/interface\s+([^ ]+)/\1/c/' --regex-PHP='/(public\s+|static\s+|protected\s+|private\s+)\$([^   =]+)/\2/p/' --regex-PHP='/const\s+([^  =]+)/\1/d/' --regex-PHP='/final\s+(public\s+|static\s+|abstract\s+|protected\s+|private\s+)function\s+\&?\s*([^ (]+)/\2/f/' --PHP-kinds=+cfpd --languages=PHP . > /dev/null 2>&1
  fi
done