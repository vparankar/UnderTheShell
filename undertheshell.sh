#!/bin/bash

clear
tput setaf 3
for((x=0;x<10;x++)); do
  tput cup 0 $x
  echo -n "#"
done
for((y=1;y<9;y++)); do
  tput cup $y 0
  echo -n "#"
  tput cup $y 9
  echo -n "#"
done
for((x=0;x<10;x++)); do
  tput cup 9 $x
  echo -n "#"
done

tput sgr0

