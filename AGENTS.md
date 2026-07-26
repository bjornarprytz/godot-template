# Agent instructions

This is a Godot (GDScript) game jam template. The actual game project lives in `src/`.

## Folder conventions

Every file under `src/` (other than top-level config like `project.godot`, `export_presets.cfg`) belongs in one of:

- `assets/` — raw media: fonts, images, audio, etc. No logic.
- `data/` — static game data: `.tres` resources, csv, config values. Loaded once at startup via Godot's own resource system. No logic beyond simple resource definitions.
- `infra/` — external dependencies for game systems: save files, settings, databases, or other persistence/I/O. Owns (de)serialization into game data types, so `sys` never contains conditional logic around file access or parsing. Not for asset loading (textures, audio, scenes) — Godot's resource system already handles that well.
- `sys/` — functional backend: game systems, rules, simulation, event definitions. No direct references to UI nodes.
- `ui/` — user-facing layer: input handling, menus, rendering, HUD, anything the player sees or interacts with directly.

`addons/` (third-party/editor plugins) sits outside this categorization.

When adding a new script or scene, decide which of these categories it belongs to before creating it. If it doesn't fit cleanly, that's a signal to split it rather than force it into the nearest match.

## Information flow

```
data --> [infra] --> sys --> ui
```

- `data` is loaded at startup, either straight into `sys` or via `infra` first (e.g. seeding a database) — whichever fits the game.
- `infra` reads/writes external state (saves, settings, databases, etc.) at runtime, deserializing it into game data types before it reaches `sys`.
- `sys` consumes data and owns game logic/state.
- `ui` reads from `sys` and presents it / relays player input back into `sys`.

The exact routing of `data` through `infra` is a per-project judgment call; the hard rule is only the overall direction, not the precise wiring.

Do not reverse this: `ui` should not be a dependency of `sys`, and `sys` should not be a dependency of `data` or `infra`.

## sys → ui communication

`sys` talks to `ui` via **signals**, not direct calls. Prefer the narrowest scope that works:

- Default to local signals declared on the relevant system node/class (e.g. `MoveNode.target_changed`, or an enemy's `health_changed`). A health bar should listen directly to the enemy it's tracking, not go through a global bus.
- Use the `Events` autoload (`src/sys/event_bus.gd`, class `EventBus`) sparingly — only for truly global events with no single natural owner, where many unrelated listeners across the game care (e.g. `game_over`). Don't route point-to-point communication through it just for convenience.

`ui` code should connect to signals rather than being polled by, or reaching into, `sys` internals.

## Node access

Always use the `%` unique-name accessor (e.g. `%Speed`, `%Move`) to reference child nodes, rather than `get_node("...")` or relative `NodePath`s. Mark the referenced node as "Access as Unique Name" in the scene tree so it stays resolvable if the hierarchy is reorganized.

## Config belongs in config files

Project-level settings (input actions, autoloads, etc.) belong in `project.godot`; scene structure belongs in `.tscn` files. Define and edit them there — through the Godot editor or directly — rather than mutating them from GDScript at runtime (e.g. no `InputMap.add_action(...)` in code). Editing them in code obscures what the project's structure actually is.

## Within `sys`

Systems may reference and depend on each other freely — `sys` is allowed to be as interconnected as necessary. The data/sys/ui layering is the hard boundary; internal coupling between systems is fine.
