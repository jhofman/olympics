#!/bin/bash
#
# file: pull_medalists.sh
#
# description: downloads athlete pages for medalists
#
# usage: ./pull_medalists.sh <medalists.tsv>
#
# requirements: wget
#
# author: jake hofman (gmail: jhofman)
#

if [ $# -lt 1 ]
then
    echo "usage: ./pull_medalists <medalists.tsv>"
    exit 1
else
    file=$1
fi

cut -f7 $file | \
    sort | uniq | grep '.html$' | \
    xargs wget -mkr -l 1 -np -N
