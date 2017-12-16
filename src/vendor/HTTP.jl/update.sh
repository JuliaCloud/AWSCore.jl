#!/bin/bash

for file in *.jl
do
    diff -u ../../../../HTTP/src/$file $file
    cp ../../../../HTTP/src/$file .
done
