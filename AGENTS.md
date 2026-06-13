# HijackSoul Agent Guide

This repository contains a Godot data-driven game framework. Follow this guide for all automated edits in this project.

## Project Layout

The architecture docs use `GodotProject/`; in this repository that folder is `hijacksoul/`.

```text
.
├── _Assets/              Source files, not loaded by the game
│   ├── Art/              Art sources, exports, references
│   ├── Design/           Design Excel files, docs, balance notes
│   ├── Audio/            Audio sources and references
│   └── Pipeline/         Naming, export, and data rules
├── _Tools/               External production tools, such as Excel to JSON converters
└── hijacksoul/           Godot project
    ├── assets/           Final runtime assets loaded by Godot
    ├── data/             Generated JSON data, runtime read-only
    ├── autoload/         Global services
    ├── modules/          Gameplay modules
    ├── ui/               UI screens, panels, menus, HUD
    ├── levels/           Level scenes and placement
    ├── glue/             Cross-module wiring and bootstrap code
    ├── resources/        Inspector-configured resources
    └── tools/            Godot editor tools and importers
```

Project architecture references live in `hijacksoul/Docs/`.

## Core Principle

Designers edit Excel, tools convert it to JSON, the game reads JSON, modules process it, and UI displays it.

```text
Excel -> converter -> JSON -> hijacksoul/data/ -> modules -> ui
```

## File Placement Rules

- Put source art/audio/design files under `_Assets/`; the game should not load these directly.
- Put external production tools under `_Tools/`.
- Put final Godot runtime assets under `hijacksoul/assets/`.
- Put generated JSON under `hijacksoul/data/`; do not hand-edit it unless explicitly asked.
- Put global services such as event bus, scene manager, audio manager, save manager, data manager, and game state under `hijacksoul/autoload/`.
- Put gameplay logic under `hijacksoul/modules/<module_name>/`.
- Put UI display and input code under `hijacksoul/ui/<ui_area>/`.
- Put level scenes, spawn points, triggers, and exits under `hijacksoul/levels/`.
- Put only connection/bootstrap logic under `hijacksoul/glue/`.
- Put Godot editor plugins/importers under `hijacksoul/tools/`.
- Put Codex project skills under `.codex/skills/<skill-name>/`.

When creating or moving files, also follow `.codex/skills/hijacksoul-file-router/SKILL.md`.

## Architecture Rules

- Designers only edit Excel and design docs; they do not hand-edit JSON.
- Modules should not directly reach into other modules' internals. Use public APIs, Godot signals, or EventBus.
- `glue/` only connects systems. Do not put inventory, combat, quest, AI, or damage rules there.
- `autoload/` provides infrastructure and shared services. Do not put concrete gameplay rules there.
- `ui/` handles display and input. Do not put gameplay rules there.
- `levels/` should contain placement and light scene-specific setup, not complex systems.
- Runtime writes should go to Godot `user://`, not `hijacksoul/data/` or `hijacksoul/assets/`.

## Current Phase

The project is in theme-unknown foundation setup.

Allowed now:
- Build `autoload/` service skeletons.
- Build empty or generic `modules/` scaffolding.
- Build generic UI such as main menu, pause menu, settings, HUD shell, and common controls.
- Build Excel-to-JSON tooling.
- Define naming, export, and data rules.

Avoid until the game theme is known:
- Specific enemy AI, damage formulas, quest conditions, or final gameplay rules.
- Final level layouts, enemy placement, story flow, or theme-specific content.
- Final Excel content or final art direction assets.

## Godot Conventions

- Prefer lowercase snake_case for Godot folders, scripts, scenes, and data files.
- Keep scripts and scenes grouped by feature, for example `hijacksoul/modules/player/player.gd` and `hijacksoul/ui/pause_menu/pause_menu.tscn`.
- Keep shared level components in `hijacksoul/levels/shared/`.
- Preserve `.import` files for committed source assets; do not commit `.godot/` cache files.

## Validation

- Before editing, check `git status --short` and avoid overwriting unrelated user changes.
- After Godot code or scene changes, run a Godot headless check when Godot is available.
- For file organization changes, verify ignored generated folders such as `hijacksoul/.godot/` remain ignored.
