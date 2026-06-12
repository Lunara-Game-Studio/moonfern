# MoonFern README / Asset Credits

Submission document listing sources used in **MoonFern** and work created by **Lunara Games**.

Repository: https://github.com/Lunara-Game-Studio/moonfern

---

## Game

**MoonFern** is a 2D platformer/adventure game made in **Godot 4.6**. The player controls Nyra, a healer witch connected to a living forest, gathering herbs, brewing potions, defending trees from corruption, and exploring forest environments (ground, underground, and industrial areas).

---

## Team

**Studio:** Lunara Games

**Team members:**
- Ashley
- Mariia
- Oliwia

---

## Team-Made Assets and Work

The following work was created by Lunara Games for this project. This includes design, implementation, and in-project art source files.

### Game design and writing
- MoonFern story, world, and character concept (Nyra, Gleamwrought enemies, forest shield / tree charge mechanics)
- Herb and potion design (`docs/potions-recipes.txt`)
- Environmental hazards design (`docs/EnvironmentalHazardsSpec.rtf`)
- Development planning and iteration notes (`docs/devlog.txt`)
- Traps/obstacles notes (`docs/Traps-Obstacles.txt`)

### Code and systems (GDScript)
All gameplay scripts in `moon-fern/Scripts/`, including:
- Player movement, inventory, pickup/drop, and interaction (`the_witch.gd`)
- Healing tree / tree charge behavior (`healing_tree.gd`)
- Gleamwrought enemy AI (`gleamwrought_enemy.gd`)
- Forest shield manager and HUD (`forest_shield_manager.gd`, `forest_shield_hud.gd`)
- Corruption feedback and player UI (`corruption_feedback.gd`, `player_feedback_ui.gd`, `tree_corruption_hud.gd`)
- Cauldron, herb, and potion logic (`cauldron.gd`, `herb.gd`, `potion.gd`)
- Camera follow and world transitions (`camera_follow.gd`, `Base_to_undeground_transition.gd`)
- Scene helper scripts (`moon-fern/Scenes/world_barrier.gd`, `animated_sprite_2d.gd`)

### Scenes, levels, and integration
- Main game scene (`moon-fern/Scenes/game.tscn`)
- Forest levels and world layout (`base_forest.tscn`, `underground_forest.tscn`, `industrial_forest.tscn`, `forest_ground_art.tscn`)
- Reusable level art chunks (`moon-fern/Scenes/art_chunks/`)
- Enemy, tree, cauldron, herb, and pickup scenes
- TileSet setup (`moon-fern/Sprites/Tiles/GroundTileSet.tres`, `new_tile_set.tres`)
- Portal sprite animation resource (`moon-fern/Sprites/Animations/new_sprite_frames.tres`)

### Art source files (team workspace)
The `art/` folder contains MoonFern concept and production art, including Aseprite source files and iterations, for example:
- `NyraSideNoBackground.png`
- `Mannequin finished version .png`, `Mannequin.Playtestversion.png`
- Tree concepts (`TreePlaytestVersion.png`, `Damaged Home Tree.png`, `Damaged Canopy.png`, `Damaged Underground tree.png`, `Industrial tree.png`, `CanopyTree.Healed.asset.png`, `Healed underground tree.png`)
- `Cauldron .png`, `Portal Light asset.png`
- Ground/environment art iterations (`Updated ground assets .png`, `Ground assets, fixed industrial .png`, `Sprite-0001.aseprite`)
- `Possible background image.png`

### Notes on implementation
Unless noted elsewhere in this document, gameplay scripting, scene integration, level setup, mechanics tuning, and Godot project configuration were completed by the Lunara Games team.

---

## External Assets and Sources

### Game engine
| Resource | Use in MoonFern | Link |
|----------|-----------------|------|
| Godot Engine 4.6 | Game engine | https://godotengine.org/ |
| Godot default project icon (`moon-fern/icon.svg`) | Project icon | https://godotengine.org/ (included with Godot) |

### Editor / development plugins (not shipped as game content)
| Resource | Use in MoonFern | Link |
|----------|-----------------|------|
| Godot Git Plugin | Version control inside the Godot editor | https://github.com/godotengine/godot-git-plugin |


### Third-party libraries used by Godot Git Plugin
Documented in `moon-fern/addons/godot-git-plugin/THIRDPARTY.md`:
- godot-cpp (MIT): https://github.com/godotengine/godot-cpp
- libgit2 (GPLv2 + linking exception): https://github.com/libgit2/libgit2
- libssh2 (BSD-3-Clause): https://github.com/libssh2/libssh2
- OpenSSL (OpenSSL License): https://github.com/openssl/openssl

---

## In-Game Visual Assets (Sprites)

These image files are used in the built game under `moon-fern/Sprites/`. They are part of the MoonFern repository and appear to be team production art (many have matching files or iterations in `art/`), but individual authorship/licensing has not been separately documented in-repo.

| Asset file | Used for |
|------------|----------|
| `Nyra.png` | Player character sprite |
| `Gleamwright.png` | Gleamwrought enemy sprite |
| `Ground Floor Tree.png` | Healable forest tree |
| `Cauldron .png` | Cauldron interactable |
| `working_assets.png` | Herb and potion pickup sprites |
| `Portal_Light asset.png`, `Portal_Light asset2.png` | Animated world portal |
| `ForestGroundAssets1.png` | Forest ground/platform art chunks |
| `Ground Assets 2.png` | Ground floor tileset source |
| `Ground assets, fixed industrial .png` | Industrial area tileset source |

### Present in project but not confirmed in active scenes
| Asset file | Notes |
|------------|-------|
| `Updated ground assets .png` | Present in `Sprites/`; source link / usage confirmation needed |
| `Sprites/Garbage/Sprite-0001.png` | Appears to be unused/archive |
| `Sprites/Garbage/working_assets.png` | Duplicate/archive copy |

---

## Audio / Music / Sound Effects

No audio files (`.wav`, `.ogg`, `.mp3`) were found in the project at the time this document was created.

The `audio/` folder exists but is empty.

**Status:** No external audio sources to credit yet.

---

## Fonts

No custom font files (`.ttf`, `.otf`) were found in the project. The game appears to use Godot's default UI fonts.

---

## Helpful References / Tutorials

### Godot and GDScript documentation
- Godot documentation: https://docs.godotengine.org/
- GDScript reference: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html

### Design inspiration (not imported assets)
The following were used as **creative references** for writing and herb/potion ideas, not as downloaded game assets:
- *Harry Potter* (Devil's Snare / mandrake references in design docs)
- *The Witcher 3* (Feainnewedd, wolfsbane references in `docs/potions-recipes.txt`)
- *Zootopia* (Night Howler reference in `docs/potions-recipes.txt`)
- *How to Lose a Guy in 10 Days* (Love Fern inspiration note in `docs/potions-recipes.txt`)
- *Hollow Knight* (General Design and Aesthetic)
- *Assassins Creed 2D 1/2 Game* (General Design and Aesthetic)
- *Avatar* (Forest Inspiration)
- Star Stable (Druid's Sorrow reference in `docs/potions-recipes.txt`)
- And Many More

### Helpful videos / tutorials
    No tutorial URLs were found in project files, comments, or documentation.

    **Status:** Add any YouTube, course, or tutorial links your team used during development here.

---

## Needs Confirmation

Please confirm with the team before submission if any item below was downloaded from an external asset store or creator.

| Item | Why confirmation is needed |
|------|--------------------------|
| `Nyra.png` | Strong match to team art in `art/NyraSideNoBackground.png`, but no explicit credit file |
| `Gleamwright.png` | Custom enemy name; likely team-made |
| `Ground Floor Tree.png` | Related tree art exists in `art/` |
| `ForestGroundAssets1.png` | May be team tile/environment art |
| `Ground Assets 2.png` | May be team tile/environment art |
| `Ground assets, fixed industrial .png` | May be team tile/environment art |
| `Updated ground assets .png` | Present in repo; usage and source unclear |
| `Portal_Light asset.png` / `Portal_Light asset2.png` | Related file in `art/`; confirm creator |
| `Cauldron .png` | Related file in `art/`; confirm creator |
| `working_assets.png` | WIP sprite sheet name; confirm whether all sprites are original |
| GitHub Copilot Godot addon | Third-party editor plugin; add source repository link |
| Any tutorials/videos used during development | Not documented in repo |

---

## Notes

- This document was generated from repository inspection of `moon-fern/`, `art/`, `docs/`, and related project folders.
- If your instructor requires a plain-text file, you can submit this document as-is or copy it into a `.txt` file.
- For the main project overview, see `README.md` in the repository root.

---

*Last updated: June 2026*
