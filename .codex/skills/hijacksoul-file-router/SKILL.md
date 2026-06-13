---
name: hijacksoul-file-router
description: Use when adding, creating, moving, or organizing files in the HijackSoul Godot project. Routes new scripts, scenes, data, art, audio, tools, docs, and resources into the correct project folder according to the architecture docs.
---

# HijackSoul File Router

Use this skill whenever a task creates, moves, renames, imports, or organizes files in this repository.

Primary references:
- `hijacksoul/Docs/项目架构文档_精简版.md`
- `hijacksoul/Docs/项目架构文档_完整版.md`

In this repository, the architecture document's `GodotProject/` maps to `hijacksoul/`.

## Core Workflow

1. Identify the file's role before creating it: source asset, final runtime asset, generated data, global service, gameplay module, UI, level, glue, editor tool, external tool, or documentation.
2. Put the file in the matching folder from the routing table below. Create missing folders when needed.
3. Keep root-level files rare: only repo config, update scripts, high-level docs, and top-level `_Assets/` or `_Tools/` belong at the repo root.
4. If the requested location conflicts with the routing table, preserve the user's explicit request but mention the mismatch.
5. Do not move or delete user-created files unless explicitly asked.

## Routing Table

| File purpose | Target folder |
| --- | --- |
| Art source files, references, PSD/Aseprite/Blender files | `_Assets/Art/Source/` or `_Assets/Art/Reference/` |
| Art export intermediates before Godot import | `_Assets/Art/Export/` |
| Design Excel source tables | `_Assets/Design/Excel/` |
| Design docs, planning docs, balance notes | `_Assets/Design/Docs/` or `_Assets/Design/Balance/` |
| Audio source files and references | `_Assets/Audio/Source/` or `_Assets/Audio/Reference/` |
| Pipeline rules and cross-role conventions | `_Assets/Pipeline/` |
| External scripts such as Excel-to-JSON converter | `_Tools/` |
| Runtime art/audio/fonts/themes loaded by Godot | `hijacksoul/assets/` |
| Generated JSON data read by the game | `hijacksoul/data/` |
| Global services: event bus, scene/audio/save/data managers, game state | `hijacksoul/autoload/` |
| Gameplay systems and domain logic | `hijacksoul/modules/<module_name>/` |
| UI scenes, panels, menus, HUD, common controls | `hijacksoul/ui/<ui_area>/` |
| Level scenes, spawn points, trigger areas, exits | `hijacksoul/levels/` |
| Connection/bootstrap code between modules | `hijacksoul/glue/` |
| Inspector-configured `.tres` resources | `hijacksoul/resources/` |
| Godot editor plugins/importers | `hijacksoul/tools/` |
| Project architecture docs | `hijacksoul/Docs/` |
| Codex project skills | `.codex/skills/<skill-name>/SKILL.md` |

## Architecture Rules

- `hijacksoul/data/` is generated/read-only. Do not hand-edit JSON unless the user explicitly asks for a temporary example or fixture.
- `hijacksoul/assets/` is runtime-read-only. Do not put source files such as PSD, Blender, Aseprite, or Excel files there.
- `hijacksoul/autoload/` is global infrastructure. Do not put concrete gameplay rules there.
- `hijacksoul/modules/` contains gameplay modules. Modules should avoid direct references to other modules' internals; prefer public APIs, signals, or EventBus.
- `hijacksoul/ui/` handles display and input. Do not put gameplay rules there.
- `hijacksoul/levels/` should contain placement and light scene-specific setup, not complex systems.
- `hijacksoul/glue/` only connects modules and startup flow. Do not put inventory, combat, quest, or AI rules there.
- Runtime writes should go to Godot `user://`, not `hijacksoul/data/` or `hijacksoul/assets/`.

## Naming Guidance

- Prefer lowercase snake_case for Godot scripts, scenes, data files, and folders.
- Keep module files grouped with their module, for example `hijacksoul/modules/player/player.gd`.
- Keep UI files grouped by screen or panel, for example `hijacksoul/ui/pause_menu/pause_menu.tscn`.
- Keep shared level components in `hijacksoul/levels/shared/`.

## When Unsure

If a file could fit multiple folders, choose based on who owns it:
- 策划 source data and docs: `_Assets/Design/`
- 美术/audio source material: `_Assets/Art/` or `_Assets/Audio/`
- Runtime-loaded assets: `hijacksoul/assets/`
- Gameplay code: `hijacksoul/modules/`
- Cross-module wiring: `hijacksoul/glue/`
- Global service: `hijacksoul/autoload/`

If ownership is still unclear, ask one short clarification before creating the file.
