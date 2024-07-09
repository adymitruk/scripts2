#!/bin/bash

## Conway's Game of Life

state=0
rows=10
columns=10
grid=()

while true; do
  for row in $(seq 0 $rows); do
    for column in $(seq 0 $columns); do
      echo -n "O"
    done
    echo
  done
  sleep 1
done

--