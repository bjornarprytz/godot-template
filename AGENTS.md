# Agent instructions

This is a Godot (GDScript) game jam template. The actual game project lives in `src/`.

## Folder conventions

Every file under `src/` (other than top-level config like `project.godot`, `export_presets.cfg`) belongs in one of:

- `assets/` — raw media: fonts, images, audio, etc. No logic.
- `data/` — static game data: `.tres` resources, csv, config values. Loaded once at startup. No logic beyond simple resource definitions.
- `sys/` — functional backend: game systems, rules, simulation, event definitions. No direct references to UI nodes.
- `ui/` — user-facing layer: input handling, menus, rendering, HUD, anything the player sees or interacts with directly.

`addons/` (third-party/editor plugins) sits outside this categorization.

When adding a new script or scene, decide which of these four it belongs to before creating it. If it doesn't fit cleanly, that's a signal to split it rather than force it into the nearest match.

## Information flow

```
data --> sys --> ui
```

- `data` is loaded at startup and flows into `sys`.
- `sys` consumes data and owns game logic/state.
- `ui` reads from `sys` and presents it / relays player input back into `sys`.

Do not reverse this: `ui` should not be a dependency of `sys`, and `sys` should not be a dependency of `data`.

## sys → ui communication

`sys` talks to `ui` via **signals**, not direct calls. Prefer the narrowest scope that works:

- Default to local signals declared on the relevant system node/class (e.g. `MoveNode.target_changed`, or an enemy's `health_changed`). A health bar should listen directly to the enemy it's tracking, not go through a global bus.
- Use the `Events` autoload (`src/sys/event_bus.gd`, class `EventBus`) sparingly — only for truly global events with no single natural owner, where many unrelated listeners across the game care (e.g. `game_over`). Don't route point-to-point communication through it just for convenience.

`ui` code should connect to signals rather than being polled by, or reaching into, `sys` internals.

## Within `sys`

Systems may reference and depend on each other freely — `sys` is allowed to be as interconnected as necessary. The data/sys/ui layering is the hard boundary; internal coupling between systems is fine.
