# Agent instructions

This is a Godot (GDScript) game jam template. The actual game project lives in `src/`.

## Folder conventions

Every file under `src/` (other than top-level config like `project.godot`, `export_presets.cfg`) belongs in one of:

- `assets/` — raw media: fonts, images, audio, etc. No logic.
- `data/` — static game data: `.tres` resources, csv, config values. Loaded once at startup via Godot's own resource system. No logic beyond simple resource definitions.
- `infra/` — external dependencies for game systems: save files, settings, databases, or other persistence/I/O. Owns (de)serialization into game data types, so `system` never contains conditional logic around file access or parsing. Not for asset loading (textures, audio, scenes) — Godot's resource system already handles that well.
- `system/` — the functional core: game data types and the functions/methods that mutate them (e.g. `MoveState`, `MoveStats`). No dependency on Godot nodes. The one exception is facade nodes living at the top level of `system/` (e.g. `MoveSystem`, `EventBus`) — these instantiate the core types, expose their state as signals, and expose mutation as plain methods, so the rest of the game never touches the pure logic directly.
- `interface/` — the interactive layer: input, menus, rendering, HUD, and any node that translates system state into what the player sees/hears, or player action into calls on `system`. Expect this to be the biggest folder in most games.

`addons/` (third-party/editor plugins) sits outside this categorization.

When adding a new script or scene, decide which of these categories it belongs to before creating it. If it doesn't fit cleanly, that's a signal to split it rather than force it into the nearest match.

## Information flow

Loading is directional; runtime is not.

```
data --> [infra] --> system <==> interface <--> player
```

- `data` is loaded at startup, either straight into `system` or via `infra` first (e.g. seeding a database) — whichever fits the game. The exact routing of `data` through `infra` is a per-project judgment call.
- `infra` reads/writes external state (saves, settings, databases, etc.) at runtime, deserializing it into game data types before it reaches `system`.
- `system` owns game logic/state and knows nothing about `interface` — it never imports or references anything from `interface/`.
- `interface` and `system` talk back and forth at runtime: `system` facades emit signals when state changes, `interface` calls the facades' methods to feed player input in.

Do not reverse the loading direction: `system` should not be a dependency of `data` or `infra`. But unlike loading, the `system`/`interface` runtime relationship is a two-way conversation, not a pipeline stage.

## system ⇄ interface communication

`system` exposes itself to `interface` only through its top-level facade nodes — never through the pure data/logic types directly. A facade:

- Emits **signals** when its state changes (e.g. `MoveSystem.moved(position, rotation)`).
- Exposes **methods** for `interface` to call in response to player input (e.g. `MoveSystem.move_to(target)`).

Prefer the narrowest signal scope that works:

- Default to local signals declared on the relevant facade (e.g. `MoveSystem.moved`, or an enemy's `health_changed`). A health bar should listen directly to the enemy it's tracking, not go through a global bus.
- Use the `Events` autoload (`src/system/event_bus.gd`, class `EventBus`) sparingly — only for truly global events with no single natural owner, where many unrelated listeners across the game care (e.g. `game_over`). Don't route point-to-point communication through it just for convenience.

`interface` code should connect to signals and call facade methods, rather than reaching into a facade's private state or the pure data/logic types underneath it.

## Node access

Always use the `%` unique-name accessor (e.g. `%Speed`, `%Move`) to reference child nodes, rather than `get_node("...")` or relative `NodePath`s. Mark the referenced node as "Access as Unique Name" in the scene tree so it stays resolvable if the hierarchy is reorganized.

## Config belongs in config files

Project-level settings (input actions, autoloads, etc.) belong in `project.godot`; scene structure belongs in `.tscn` files. Define and edit them there — through the Godot editor or directly — rather than mutating them from GDScript at runtime (e.g. no `InputMap.add_action(...)` in code). Editing them in code obscures what the project's structure actually is.

## Within `system`

Systems may reference and depend on each other freely — `system` is allowed to be as interconnected as necessary. The data/system/interface layering is the hard boundary; internal coupling between systems is fine.

A typical `system` feature is two files: a pure data/logic class with no `extends Node` (e.g. `MoveState`, a plain `RefCounted` holding state plus an `advance(delta)` method) and a thin facade `Node` at the top level of `system/` that owns an instance of it and exposes it as signals/methods (e.g. `MoveSystem`). Not every system needs both — simple cases can skip the facade — but reach for this split before letting node-dependent logic creep into the pure data/logic class.
