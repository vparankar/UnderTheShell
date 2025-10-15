#!/bin/bash

clear

# Initial Game State
level=1
hp=3
keys_inv=0
score=0
base_width=55
base_height=11
reset_game=true

# Dynamic properties
width=$base_width
height=$base_height
enemy_num=3

is_walkable(){
  local idx=$(($2*width+$1))
  local char="${grid[$idx]}"
  [[ "$char" == "." || "$char" == "^" || "$char" == "&" || "$char" == "K" || "$char" == "D" || "$char" == "O" ]] && return 0
  return 1
}

reset_level(){
  width=$((base_width + (level-1)*4))
  height=$((base_height + (level-1)*2))
  enemy_num=$((3 + level/2))
  
  grid=()
  for((y=0; y<height; y++)); do
    for((x=0; x<width; x++)); do
      grid[$(($y*$width+$x))]="▓"
    done
  done

  unset visited
  declare -Ag visited
  
  carve_path 1 1
  
  # Ensure the goal is at a valid path end (or at least reachable)
  # Place goal at a random path far from start
  local valid_paths=()
  for((y=1; y<height-1; y++)); do
    for((x=1; x<width-1; x++)); do
      if [[ "${grid[$(($y*$width+$x))]}" == "." && ! ($x -lt 5 && $y -lt 5) ]]; then
        valid_paths+=("$x,$y")
      fi
    done
  done
  
  # Shuffle valid paths
  valid_paths=($(shuf -e "${valid_paths[@]}"))
  
  local goal_coords="${valid_paths[0]}"
  goal_x="${goal_coords%,*}"
  goal_y="${goal_coords#*,}"
  grid[$((goal_y*width+goal_x))]="O"
  
  # Place Key and Door
  local key_coords="${valid_paths[1]}"
  local key_x="${key_coords%,*}"
  local key_y="${key_coords#*,}"
  grid[$((key_y*width+key_x))]="K"
  
  # Door should ideally block the goal, but to keep it simple, 
  # we just place it randomly. Finding the key to unlock the door is required to exit.
  # We will enforce: to enter 'O', you must have opened the door or we can just place the Door
  # somewhere on the map that must be opened. Actually, it's better if touching 'O' checks if Door is opened.
  # Let's place a Door anywhere, picking it up gives score, but really let's just make the door block the Goal.
  # Instead of complex blocking, you just need a Key to step on Goal.
  
  # Place Traps
  local traps_count=$((level + 2))
  for ((i=0; i<traps_count; i++)); do
    local tc="${valid_paths[$((i+2))]}"
    local tx="${tc%,*}"
    local ty="${tc#*,}"
    grid[$((ty*width+tx))]="^"
  done
  
  # Place Portals (Pair)
  local p1="${valid_paths[$((traps_count+3))]}"
  portal1_x="${p1%,*}"
  portal1_y="${p1#*,}"
  grid[$((portal1_y*width+portal1_x))]="&"
  
  local p2="${valid_paths[$((traps_count+4))]}"
  portal2_x="${p2%,*}"
  portal2_y="${p2#*,}"
  grid[$((portal2_y*width+portal2_x))]="&"

  # Reset player
  pos_x=1
  pos_y=1
  keys_inv=0
  
  spawn_enemies
}

carve_path(){
  local x=$1
  local y=$2

  visited["$x,$y"]=1
  grid[$(($y*$width+$x))]="."

  local dirs=("up" "right" "left" "down")
  dirs=($(shuf -e "${dirs[@]}"))

  for dir in "${dirs[@]}"; do
    local nx ny wx wy
    case "$dir" in
      up) nx=$x; ny=$(($y-2)); wx=$x; wy=$(($y-1));; 
      right) nx=$(($x+2)); ny=$y; wx=$(($x+1)); wy=$y;;
      left) nx=$(($x-2)); ny=$y; wx=$(($x-1)); wy=$y;;
      down) nx=$x; ny=$((y+2)); wx=$x; wy=$((y+1));;
    esac

    if [[ ($nx -gt 0 && $nx -lt $((width-1)) && $ny -gt 0 && $ny -lt $((height-1))) && -z ${visited["$nx,$ny"]} ]]; then
      grid[$((wy*width+wx))]="."
      carve_path "$nx" "$ny"
    fi
  done 
}

spawn_enemies(){
  enemy_pos=()
  local spawn_count=$enemy_num
  while [[ ${#enemy_pos[@]} -lt $spawn_count ]]; do
    local ex=$((RANDOM%width))
    local ey=$((RANDOM%height))
    if [[ "${grid[$((ey*width+ex))]}" == "." ]] &&
       [[ "$ex,$ey" != "$pos_x,$pos_y" && "$ex,$ey" != "$goal_x,$goal_y" ]] &&
       [[ ! " ${enemy_pos[*]} " =~ " $ex,$ey " ]] &&
       [[ $(( (ex-pos_x)*(ex-pos_x) + (ey-pos_y)*(ey-pos_y) )) -gt 25 ]]; then
      enemy_pos+=("$ex,$ey")
    fi
  done
}

is_enemy(){
  for e in "${enemy_pos[@]}"; do
    if [[ "$1,$2" == "$e" ]]; then return 0; fi
  done
  return 1
}

draw_grid(){
  clear
  for((y=0;y<height;y++)); do
    for((x=0;x<width;x++)); do
      if [[ $x -eq $pos_x && $y -eq $pos_y ]]; then
        tput setaf 4; echo -n "@"; tput sgr0
      elif is_enemy $x $y; then
        tput setaf 1; echo -n "*"; tput sgr0
      else
        local char="${grid[$(($y*$width+$x))]}"
        case "$char" in
          "O") tput setaf 2; echo -n "O"; tput sgr0 ;;
          "K") tput setaf 3; echo -n "K"; tput sgr0 ;;
          "D") tput setaf 3; echo -n "D"; tput sgr0 ;;
          "^") tput setaf 1; echo -n "^"; tput sgr0 ;;
          "&") tput setaf 6; echo -n "&"; tput sgr0 ;;
          "▓") tput setaf 7; echo -n "▓"; tput sgr0 ;;
          *) echo -n "." ;;
        esac
      fi
    done
    echo
  done
  draw_hud
}

draw_hud(){
  tput cup $height 0
  tput el
  tput setaf 3; echo -n "Level: $level  |  Score: $score  |  HP: $hp  |  Keys: $keys_inv"; tput sgr0
  echo
}

move_enemies(){
  local new_enemy_pos=()
  for e in "${enemy_pos[@]}"; do
    local ex="${e%,*}"
    local ey="${e#*,}"
    
    # Very simple AI: 50% chance to move towards player if close
    local dx=$((pos_x - ex))
    local dy=$((pos_y - ey))
    local dist=$(( dx*dx + dy*dy ))
    
    local moved=false
    if [[ $dist -le 36 && $((RANDOM%2)) -eq 0 ]]; then
      local nx=$ex
      local ny=$ey
      if [[ $((RANDOM%2)) -eq 0 ]]; then
        [[ $dx -gt 0 ]] && nx=$((ex+1)) || nx=$((ex-1))
      else
        [[ $dy -gt 0 ]] && ny=$((ey+1)) || ny=$((ey-1))
      fi
      
      if [[ "${grid[$((ny*width+nx))]}" == "." && ! " ${new_enemy_pos[*]} " =~ " $nx,$ny " ]]; then
        ex=$nx
        ey=$ny
        moved=true
      fi
    fi
    
    # Random movement if didn't move towards player
    if [[ $moved == false ]]; then
      local dirs=("up" "right" "left" "down")
      local dir="${dirs[$((RANDOM%4))]}"
      local nx=$ex
      local ny=$ey
      case "$dir" in
        up) ny=$((ey-1));; right) nx=$((ex+1));; left) nx=$((ex-1));; down) ny=$((ey+1));;
      esac
      if [[ "${grid[$((ny*width+nx))]}" == "." && ! " ${new_enemy_pos[*]} " =~ " $nx,$ny " ]]; then
        ex=$nx
        ey=$ny
      fi
    fi
    new_enemy_pos+=("$ex,$ey")
  done
  enemy_pos=("${new_enemy_pos[@]}")
}

update_grid() {
  # Redraw old player pos
  tput cup $old_y $old_x
  local old_char="${grid[$((old_y*width+old_x))]}"
  case "$old_char" in
    "O") tput setaf 2; echo -n "O"; tput sgr0 ;;
    "&") tput setaf 6; echo -n "&"; tput sgr0 ;;
    *) echo -n "." ;;
  esac

  # Draw new player pos
  tput cup $pos_y $pos_x
  tput setaf 4; echo -n "@"; tput sgr0

  # Erase old enemies
  for e in "${enemy_pos[@]}"; do
    local ex=${e%,*}
    local ey=${e#*,}
    tput cup $ey $ex
    local char="${grid[$((ey*width+ex))]}"
    case "$char" in
      "O") tput setaf 2; echo -n "O"; tput sgr0 ;;
      "K") tput setaf 3; echo -n "K"; tput sgr0 ;;
      "&") tput setaf 6; echo -n "&"; tput sgr0 ;;
      "^") tput setaf 1; echo -n "^"; tput sgr0 ;;
      *) echo -n "." ;;
    esac
  done

  move_enemies

  # Draw new enemies
  for e in "${enemy_pos[@]}"; do
    local ex=${e%,*}
    local ey=${e#*,}
    tput cup $ey $ex
    tput setaf 1; echo -n "*"; tput sgr0
  done
  
  draw_hud
}

game_over(){
  tput cup $((height+2)) 0
  tput setaf 1; echo "GAME OVER! You reached Level $level with $score points."; tput sgr0
  echo "Press 'R' to Restart or 'Q' to Quit."
  while true; do
    read -n1 key
    case "$key" in
      r|R) level=1; hp=3; score=0; reset_game=true; break;;
      q|Q) clear; tput sgr0; tput cnorm; stty sane; exit 0;;
    esac
  done
}

stty -echo -icanon time 0 min 0
tput civis

while true; do
  if [[ $reset_game == true ]]; then
    reset_level
    draw_grid 
    reset_game=false
  fi
  
  read -n1 -t 0.3 key

  old_x=$pos_x
  old_y=$pos_y

  nx=$pos_x
  ny=$pos_y

  case "$key" in
    a|A) ((nx--));;
    d|D) ((nx++));;
    w|W) ((ny--));;
    s|S) ((ny++));;
    q|Q) clear; tput sgr0; tput cnorm; stty sane; exit 0;;
  esac

  # Interaction Logic
  local target_idx=$((ny*width+nx))
  local target_char="${grid[$target_idx]}"

  if [[ "$target_char" != "▓" ]]; then
    pos_x=$nx
    pos_y=$ny
  fi

  # Player interacts with cell
  target_char="${grid[$((pos_y*width+pos_x))]}"
  
  if is_enemy $pos_x $pos_y; then
    ((hp--))
    tput cup $((height+1)) 0
    tput setaf 1; echo -n "Ouch! Hit an enemy!              "; tput sgr0
    if [[ $hp -le 0 ]]; then game_over; continue; fi
  elif [[ "$target_char" == "K" ]]; then
    ((keys_inv++))
    ((score+=10))
    grid[$((pos_y*width+pos_x))]="."
    tput cup $((height+1)) 0
    tput setaf 3; echo -n "Picked up a Key!                 "; tput sgr0
  elif [[ "$target_char" == "^" ]]; then
    ((hp--))
    grid[$((pos_y*width+pos_x))]="."
    tput cup $((height+1)) 0
    tput setaf 1; echo -n "Stepped on a Trap!               "; tput sgr0
    if [[ $hp -le 0 ]]; then game_over; continue; fi
  elif [[ "$target_char" == "&" ]]; then
    if [[ $pos_x -eq $portal1_x && $pos_y -eq $portal1_y ]]; then
      pos_x=$portal2_x
      pos_y=$portal2_y
    else
      pos_x=$portal1_x
      pos_y=$portal1_y
    fi
    tput cup $((height+1)) 0
    tput setaf 6; echo -n "Whoosh! Teleported!              "; tput sgr0
  elif [[ "$target_char" == "O" ]]; then
    if [[ $keys_inv -gt 0 ]]; then
      tput cup $((height+1)) 0
      tput setaf 2; echo -n "Level Complete! Next Level...    "; tput sgr0
      ((score+=50))
      ((level++))
      ((hp++)) # bonus hp for completing level
      sleep 1
      reset_game=true
      continue
    else
      tput cup $((height+1)) 0
      tput setaf 3; echo -n "You need a Key to open the Goal! "; tput sgr0
      pos_x=$old_x
      pos_y=$old_y
    fi
  else
    tput cup $((height+1)) 0
    tput el
  fi
  
  # Ensure enemy collision is checked again after player moves
  if is_enemy $pos_x $pos_y; then
    ((hp--))
    tput cup $((height+1)) 0
    tput setaf 1; echo -n "Ouch! Enemy got you!             "; tput sgr0
    if [[ $hp -le 0 ]]; then game_over; continue; fi
  fi

  update_grid
done

tput sgr0
tput cnorm
stty sane