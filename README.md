# Advanced Enemy Patrol & Search AI

This is a modular enemy AI system for Roblox (Luau) built with advanced search and patrol mechanics. Enemies can detect, pursue, and investigate players intelligently using a mix of raycasting, pathfinding, and proximity-based logic.

> designed for realism, and performance in a maze based map

---

## Features

* **Field of view detection** with limb-based visibility
* **Search mode** triggered by last known location
* **LOS-based chasing** (ignores pathfinding when direct sight exists)
* **Sound-based player tracking** (footstep simulation)
* **Stamina system** for enemy movement control
* **Dynamic attack cooldowns**
* Modular, customizable config (range, FOV, behavior)

---

## How It Works

The enemy can exist in one of three behavior states:

1. **PATROLLING** – Moves between predefined nodes using Roblox’s PathfindingService.
2. **SEARCHING** – Investigates the last known location of the player using a radial node scan.
3. **CHASING** – Chases the player directly if they’re in line of sight, skipping pathfinding.

It uses:

* Dot product FOV checks
* Raycasting for visibility
* Distance/limb ratio to gauge player visibility strength
* Coroutine-based state switching

## File Hierarchy

```
YourEnemy/
├── Configuration (ModuleScript)
├── Main (Folder)
│   ├── Main.lua
│   ├── State/
│   │   ├── Patrolling.lua
│   │   └── Searching.lua
│   │   └── Chasing.lua
├── Animate (Script)
```

---

## Files

* `Main.lua` → core AI logic + utilities (distance, LOS, node scanning, pathing)
* `EnemyScript.lua` → entry point that controls state switching
* `State.lua` → type checking module, defines actions
* `State/Patrolling.lua` → defines patrol behavior (waypoints, looping, idle delay)
* `State/Searching.lua` → handles node-based search around last known player location
* `State/Chasing.lua` → handles chasing logic when player is in line of sight

---

## AI Behavior Breakdown

### Visibility Check

* Checks 4 key body parts (head, torso, arms)
* Returns how many are visible and only proceeds if above a certain threshold
* Weights visibility by proximity (e.g. closer = higher priority)

### Pathing

* Waypoint-based system using `PathfindingService`
* Switches to direct pursuit (no pathing) when target is in LOS
* Visual debug option: drops neon markers at path waypoints

### Search Logic

* Gets all nodes in radius of last known location
* Visits unsearched nodes and raycasts to determine visible neighbors
* Marks visited nodes via attributes

---

## License

MIT License. do whatever just provide a bare minimum of credit

---

## Credits

developed by `dogo8me2`
