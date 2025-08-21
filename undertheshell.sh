#!/bin/bash

clear
tput setaf 3

height=21
width=21
score=0
enemy_num=5
reset_game=true

goal_x=$((width-2))
goal_y=$((height-2))

reset_grid(){
  grid=()
  for((y=0; y<height; y++)); do
    for((x=0; x<width; x++)); do
      grid[$(($y*$width+$x))]="#"
    done
  done

  unset visited
  declare -Ag visited
}

carve_path(){
  local x=$1
  local y=$2

  visited["$x,$y"]=1
  grid[$(($y*$width+$x))]="."

  dirs=("up" "right" "left" "down")
  dirs=($(shuf -e "${dirs[@]}"))

  for dir in "${dirs[@]}"; do
    case "$dir" in
      up) nx=$x; ny=$(($y-2)); wx=$x; wy=$(($y-1));; 
      right) nx=$(($x+2)); ny=$y; wx=$(($x+1)); wy=$y;;
      left) nx=$(($x-2)); ny=$y; wx=$(($x-1)); wy=$y;;
      down) nx=$x; ny=$((y+2)); wx=$x; wy=$((y+1));;
    esac

    if [[ ($nx -ge 0 && $nx -lt $width && $ny -ge 0 && $ny -lt $height) && -z ${visited["$nx,$ny"]} ]]; then
      grid[$((wy*width+wx))]="."
      carve_path "$nx" "$ny"
    fi
  done 
}

goto_start(){
  pos_x=1
  pos_y=1
}

is_goal(){
  [[ $1 -eq $goal_x && $2 -eq $goal_y ]] && return 0
  return 1
}

is_wall(){
  if [[ "${grid[$(($2*width+$1))]}" == "#" ]]; then
    return 0
  fi
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
      else
        echo -n "${grid[$(($y*$width+$x))]}"
      fi
    done
    echo
  done
  echo "Score: $score"
}

stty -echo -icanon time 0 min 0
while true; do
  if [[ $reset_game == true ]]; then
    reset_grid
    carve_path 1 1
    goto_start
    reset_game=false
  fi

  clear
  draw_grid

  if is_goal $pos_x $pos_y; then
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

  sleep 0.05
done

tput sgr0
stty sane