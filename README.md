# UnderTheShell

A thrilling puzzle-maze game written entirely in Bash!

## Gameplay
Navigate your way through procedurally generated mazes, avoiding enemies and traps. Your objective is to find the **Key** to unlock the **Goal**. 
Survive as long as you can across progressively harder levels.

## Controls
- `W` / `A` / `S` / `D` - Move Up / Left / Down / Right
- `Q` - Quit the game
- `R` - Restart the game (upon Game Over)

## Legend
- `@` : **Player** (You)
- `O` : **Goal** (Proceed to the next level. Requires a Key!)
- `K` : **Key** (Collect these to open the Goal)
- `*` : **Enemy** (Avoid them! They will chase you if you get too close)
- `^` : **Trap** (Stepping on this hurts you)
- `&` : **Portal** (Stepping on one teleports you to the other)
- `▓` : **Wall** (Impassable)
- `.` : **Path** (Walkable space)

## Installation

You can install the game globally to play it anywhere by running:
```bash
sudo ./install.sh
```

Then you can launch the game from any directory by simply typing:
```bash
undertheshell
```

## Uninstallation

To uninstall, simply remove the executable:
```bash
sudo rm /usr/local/bin/undertheshell
```
