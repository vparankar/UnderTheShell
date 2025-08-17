#!/bin/bash

clear
tput setaf 3

height=10
width=10
score=0

pos_x=$((RANDOM%width))
pos_y=$((RANDOM%height))

while true; do
  goal_x=$((RANDOM%width))
  goal_y=$((RANDOM%height))
  [[ $goal_x -ne $pos_x || $goal_y -ne $pos_y ]] && break
done

stty -echo -icanon time 0 min 0
while true; do
  clear

  for((y=0;y<height;y++)); do
    for((x=0;x<width;x++)); do
      if [[ $x -eq $pos_x && $y -eq $pos_y ]]; then
        tput setaf 1
        echo -n "@"
        tput setaf 3
      elif [[ $x -eq $goal_x && $y -eq $goal_y ]]; then
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


  if [[ $pos_x -eq $goal_x && $pos_y -eq $goal_y ]]; then
    tput setaf 2
    echo "You reached the goal! Press any key to continue, 'Q' to exit."
    tput setaf 3
    ((score++))

    pos_x=$((RANDOM%width))
    pos_y=$((RANDOM%height))

    while true; do
      goal_x=$((RANDOM%width))
      goal_y=$((RANDOM%height))
      [[ $goal_x -ne $pos_x || $goal_y -ne $pos_y ]] && break
    done
    sleep 0.5
  fi

  read -n1 key

  case "$key" in
    a) ((pos_x--));;
    d) ((pos_x++));;
    w) ((pos_y--));;
    s) ((pos_y++));;
    q|Q) break;;
  esac

  ((pos_x<0)) && pos_x=0
  ((pos_x>=width)) && pos_x=$((width-1))
  ((pos_y<0)) && pos_y=0
  ((pos_y>=height)) && pos_y=$((height-1))
  
  sleep 0.05
done

tput sgr0
stty sane
