#!/bin/bash

clear
tput setaf 3

height=10
width=10
score=0
enemy_num=5
walls_num=10
reset_game=true

generate_pos(){
  local used_coords=()
  local coords

  walls_pos=()
  while [[ ${#walls_pos[@]} -lt $walls_num ]]; do
    walls_x=$((RANDOM%width))
    walls_y=$((RANDOM%height))
    coords="$walls_x,$walls_y"
    if [[ ! " ${used_coords[*]} " =~ " $coords " ]]; then
      walls_pos+=("$coords")
      used_coords+=("$coords")
    fi
  done

  while true; do
    pos_x=$((RANDOM%width))
    pos_y=$((RANDOM%height))
    coords="$pos_x,$pos_y"
    if [[ ! " ${used_coords[*]} " =~ " $coords " ]]; then
      used_coords+=("$coords")
      break
    fi
  done

  while true; do
    goal_x=$((RANDOM%width))
    goal_y=$((RANDOM%height))
    coords="$goal_x,$goal_y"
    if [[ ! " ${used_coords[*]} " =~ " $coords " ]]; then
      used_coords+=("$coords")
      break
    fi
  done

  enemy_pos=()
  while [[ ${#enemy_pos[@]} -lt $enemy_num ]]; do
    enemy_x=$((RANDOM%width))
    enemy_y=$((RANDOM%height))
    coords="$enemy_x,$enemy_y"

    if [[ ! " ${used_coords[*]} " =~ " $coords " ]]; then
      enemy_pos+=("$coords")
      used_coords+=("$coords")
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
    fi
  done
  return 1
}

is_wall(){
  for w in "${walls_pos[@]}"; do
    if [[ "$1,$2" == "$w" ]]; then
      return 0
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
      elif is_wall $x $y; then
        tput setaf 7
        echo -n "#"
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

  new_x=$pos_x
  new_y=$pos_y
  case "$key" in
    a) ((new_x--));;
    d) ((new_x++));;
    w) ((new_y--));;
    s) ((new_y++));;
    q|Q) break;;
  esac

  if ! is_wall $new_x $new_y; then
    pos_x=$new_x
    pos_y=$new_y
  fi

  ((pos_x<0)) && pos_x=0
  ((pos_x>=width)) && pos_x=$((width-1))
  ((pos_y<0)) && pos_y=0
  ((pos_y>=height)) && pos_y=$((height-1))
  
  sleep 0.05
done

tput sgr0
stty sane
