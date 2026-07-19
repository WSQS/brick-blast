# brick-blast

A classic brick-breaker game built with [Godot 4.7](https://godotengine.org).

## Features

- **Ball & paddle physics**: `CharacterBody2D` + `move_and_collide` for CCD (no tunneling)
- **Combo system**: consecutive brick destructions build combo, scaling score
- **Ball stick**: ball waits on paddle until launch (Space / click)
- **Star rating**: 1-3 stars based on combo performance and lives lost
- **Upgrade system**: choose 1 of 3 upgrades after clearing all bricks (5 types: wide paddle, slow ball, extra life, multi-ball, pierce)
- **Pause / resume**: Esc, on-screen pause button (top-right), or Android back gesture to toggle
- **Main menu**: title screen with Start / Quit

## Requirements

- Godot 4.7+ (GL Compatibility renderer)
- GUT v9.6.1 (bundled in `addons/gut/`)

## Getting Started

```bash
# Clone
git clone <repo-url>
cd brick-blast

# Open in Godot
# Launch the Godot editor and open the project, then press F5 to run
```

The game starts at the main menu (`res://scene/menu.tscn`).

## Controls

| Action | Key / Input |
|--------|-------------|
| Move paddle | Mouse / Arrow keys |
| Launch ball | Space / Click |
| Pause | Esc / Pause button (top-right) / Android back gesture |
| Restart | Restart button (after game over) |

## Project Structure

```
brick-blast/
├── scene/          # .tscn scene files (main, menu, ball, brick, paddle, upgrade_panel)
├── script/         # .gd scripts
├── test/unit/      # GUT unit tests (77 tests)
├── docs/           # Design decisions, roadmap, analysis
├── addons/gut/     # GUT testing framework
├── .github/        # CI workflows, copilot instructions, skills
├── export_presets.cfg  # Windows/Linux/Android/Web export presets
├── project.godot   # Godot project config
└── CHANGELOG.md    # Change history
```

## Code Formatting

GDScript files are auto-formatted with [gdformat](https://github.com/Scony/godot-gdscript-toolkit) via a pre-commit hook.

```bash
# First-time setup (after cloning)
sh hooks/install.sh

# Format manually anytime
gdformat script/ test/unit/
```

## Running Tests

**Linux:**
```bash
"/path/to/godot" --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit 2>&1
```

**Windows:**
```bash
cmd /c '"<godot_path>" --headless -s addons\gut\gut_cmdln.gd -gdir=res://test/unit -gexit 2>&1'
```

## Documentation

- [CHANGELOG.md](CHANGELOG.md) - change history
- [docs/decisions.md](docs/decisions.md) - architecture decision records
- [docs/roadmap.md](docs/roadmap.md) - version roadmap and feature plan
- [docs/formal-elements-analysis.md](docs/formal-elements-analysis.md) - game design analysis
- [.github/copilot-instructions.md](.github/copilot-instructions.md) - project conventions and gotchas

## License

MIT
