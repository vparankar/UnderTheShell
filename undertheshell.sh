#!/bin/bash

clear
tput setaf 3

height=10
width=10
score=0
enemy_num=5
reset_game=true

generate_pos(){
  pos_x=$((RANDOM%width))
    pos_y=$((RANDOM%height))

    while true; do
      goal_x=$((RANDOM%width))
      goal_y=$((RANDOM%height))
      [[ $goal_x -ne $pos_x || $goal_y -ne $pos_y ]] && break
    done

    enemy_pos=()
    i=1
    while [[ $i -le $enemy_num ]]; do
      enemy_x=$((RANDOM%width))
      enemy_y=$((RANDOM%height))
      coord="$enemy_x,$enemy_y"
      
      if [[ ($enemy_x -ne $pos_x || $enemy_y -ne $pos_y) && ($enemy_x -ne $goal_x || $enemy_y -ne $goal_y) ]]; then
        enemy_pos+=("$coord") 
        ((i++))
      fi
    done
}

is_goal(){
  [[ $1 -eq $goal_x && $2 -eq $goal_y ]] && return 0
  return 1
}

is_enemy(){
  for e in "${enemy_pos[@]}"; do
    if [[ "$1,$2" == "$e" ]]; then
      return 0
      break
    fi
  done
  return 1
}

draw_grid(){
  for((y=0;y<height;y++)); do
    for((x=0;x<width;x++)); do

      if [[ $x -eq $pos_x && $y -eq $pos_y ]]; then
        tput setaf 4
        echo -n "@"
        tput setaf 3
      elif is_goal $x $y; then
        tput setaf 2
        echo -n "O"
        tput setaf 3
      elif is_enemy $x $y; then
        tput setaf 1
        echo -n "*"
        tput setaf 3
      else
        echo -n "."
      fi
    done
    echo
  done
  echo "Score: $score"
}

stty -echo -icanon time 0 min 0
while true; do

  if [[ $reset_game == true ]]; then
    generate_pos
    reset_game=false
  fi

  clear
  draw_grid

  if is_enemy $pos_x $pos_y; then
    tput setaf 1
    echo "Game Over. Press any key to continue, 'Q' to exit."
    tput setaf 3
    score=0
    reset_game=true
  elif is_goal $pos_x $pos_y; then
    tput setaf 2
    echo "You reached the goal! Press any key to continue, 'Q' to exit."
    tput setaf 3
    ((score++))
    reset_game=true
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
