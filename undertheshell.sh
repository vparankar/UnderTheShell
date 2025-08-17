#!/bin/bash

clear
tput setaf 3

height=10
width=10
posx=$((RANDOM%width))
posy=$((RANDOM%height))

score=0

while true; do
  goalx=$((RANDOM%width))
  goaly=$((RANDOM%height))
  [[ $goalx -ne $posx || $goaly -ne $posy ]] && break
done

stty -echo -icanon time 0 min 0
while true; do
  clear
  for((y=0;y<height;y++)); do
    for((x=0;x<width;x++)); do
      if [[ $x -eq $posx && $y -eq $posy ]]; then
        tput setaf 1
        echo -n "@"
        tput setaf 3
      elif [[ $x -eq $goalx && $y -eq $goaly ]]; then
        tput setaf 2
        echo -n "O"
        tput setaf 3
      else
        echo -n "."
      fi
    done
    echo
  done
  echo "Score: $score"


  if [[ $posx -eq $goalx && $posy -eq $goaly ]]; then
    tput setaf 2
    echo "You reached the goal! Press any key to continue, 'Q' to exit."
    tput setaf 3
    ((score++))
    while true; do
      goalx=$((RANDOM%width))
      goaly=$((RANDOM%height))
      [[ $goalx -ne $posx || $goaly -ne $posy ]] && break
    done
    sleep 0.5
  fi

  read -n1 key

  case "$key" in
    a) ((posx--));;
    d) ((posx++));;
    w) ((posy--));;
    s) ((posy++));;
    q|Q) break;;
  esac

  ((posx<0)) && posx=0
  ((posx>=width)) && posx=$((width-1))
  ((posy<0)) && posy=0
  ((posy>=height)) && posy=$((height-1))
  
  sleep 0.05
done

tput sgr0
stty sane
