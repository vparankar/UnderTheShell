#!/bin/bash

clear
tput setaf 3

height=11
width=55
score=0
enemy_num=5
reset_game=true

goal_x=$((width-2))
goal_y=$((height-2))

is_enemy(){
  for e in "${enemy_pos[@]}"; do
    if [[ "$1,$2" == "$e" ]]; then
      return 0
    fi
  done
  return 1
}

is_goal(){
  [[ $1 -eq $goal_x && $2 -eq $goal_y ]] && return 0
  return 1
}

is_wall(){
  if [[ "${grid[$(($2*width+$1))]}" == "▓" ]]; then
    return 0
  fi
  return 1
}

reset_grid(){
  grid=()
  for((y=0; y<height; y++)); do
    for((x=0; x<width; x++)); do
      grid[$(($y*$width+$x))]="▓"
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

spawn_enemies(){
  enemy_pos=()
  while [[ ${#enemy_pos[@]} -lt $enemy_num ]]; do
    local enemy_x=$((RANDOM%width))
    local enemy_y=$((RANDOM%height))
    if [[ "${grid[$((enemy_y*width+enemy_x))]}" == "." ]] &&
    [[ "$enemy_x,$enemy_y" != "$pos_x,$pos_y" && "$enemy_x,$enemy_y" != "$goal_x,$goal_y" ]] &&
    [[ ! " ${enemy_pos[*]} " =~ " $enemy_x,$enemy_y " ]]; then
      enemy_pos+=("$enemy_x,$enemy_y")
    fi
  done
}

draw_grid(){
  for((y=0;y<height;y++)); do
    for((x=0;x<width;x++)); do

      if [[ $x -eq $pos_x && $y -eq $pos_y ]]; then
        tput setaf 4; echo -n "@"; tput setaf 3
      elif is_goal $x $y; then
        tput setaf 2; echo -n "O"; tput setaf 3
      elif is_enemy $x $y; then
        tput setaf 1; echo -n "*"; tput setaf 3
      else
        echo -n "${grid[$(($y*$width+$x))]}"
      fi
    done
    echo
  done
  echo "Score: $score"
}

move_enemies(){
    new_enemy_pos=()
    for e in "${enemy_pos[@]}"; do
      enemy_x="${e%,*}"
      enemy_y="${e#*,}"

      dirs=("up" "right" "left" "down")
      dir="${dirs[$((RANDOM%4))]}"

      case "$dir" in
        up) nx=$enemy_x; ny=$((enemy_y-1));;
        right) nx=$((enemy_x+1)); ny=$enemy_y;;
        left) nx=$((enemy_x-1)); ny=$enemy_y;;
        down) nx=$enemy_x; ny=$((enemy_y+1));;
      esac

      if [[ "${grid[$((ny*width+nx))]}" == "." ]] &&
         [[ "$nx,$ny" != "$goal_x,$goal_y" ]]; then
        enemy_x=$nx
        enemy_y=$ny
      fi

      new_enemy_pos+=("$enemy_x,$enemy_y")
    done
  enemy_pos=("${new_enemy_pos[@]}")
}

update_grid() {
  tput cup $old_y $old_x
  echo -n "."

  tput cup $pos_y $pos_x
  tput setaf 4; echo -n "@"; tput setaf 3

  for e in "${enemy_pos[@]}"; do
    ex=${e%,*}
    ey=${e#*,}
    tput cup $ey $ex
    echo -n "."
  done

  move_enemies

  for e in "${enemy_pos[@]}"; do
    ex=${e%,*}
    ey=${e#*,}
    tput cup $ey $ex
    tput setaf 1; echo -n "*"; tput setaf 3
  done
  tput cup $height 0
  echo "Score: $score"
}

stty -echo -icanon time 0 min 0
tput civis
while true; do
  if [[ $reset_game == true ]]; then
    clear
    reset_grid
    carve_path 1 1
    goto_start
    spawn_enemies
    draw_grid 
    reset_game=false
  else
    update_grid
  fi
  
  read -n1 -t 0.5 key

  old_x=$pos_x
  old_y=$pos_y

  case "$key" in
    a) ((pos_x--));;
    d) ((pos_x++));;
    w) ((pos_y--));;
    s) ((pos_y++));;
    q|Q) clear; break;;
  esac

  if is_wall $pos_x $pos_y; then
    pos_x=$old_x
    pos_y=$old_y
  elif is_enemy $pos_x $pos_y; then
    tput setaf 1; echo "Game Over. Press any key to continue, 'Q' to exit."; tput setaf 3
    score=0
    reset_game=true
    read -n1
  elif is_goal $pos_x $pos_y; then
    tput setaf 2; echo "You reached the goal! Press any key to continue, 'Q' to exit."; tput setaf 3
    ((score++))
    reset_game=true
    read -n1
  fi
  sleep 0.1
done

tput sgr0
tput cnorm
stty sane