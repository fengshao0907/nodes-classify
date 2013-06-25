#!/bin/bash

[ -e output ] || mkdir output

rm -rf output/*
for f in `ls | grep -Pv 'build\.sh|output'`;do
    cp -r $f output/
done

exit 0
