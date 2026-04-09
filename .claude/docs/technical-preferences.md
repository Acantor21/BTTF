# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (primary), C++ via GDExtension for performance-critical code
- **Rendering**: Forward+ renderer, desktop-first 3D presentation
- **Physics**: Jolt Physics 3D (Godot 4.6 default)

## Naming Conventions

- **Classes**: PascalCase (`FatherTimeDioramaRoot`)
- **Variables**: snake_case (`active_era_id`)
- **Signals/Events**: snake_case past tense (`artifact_resolved`)
- **Files**: snake_case matching class or responsibility (`father_time_run_state.gd`)
- **Scenes/Prefabs**: PascalCase matching the root node (`FatherTimeDioramaRoot.tscn`)
- **Constants**: UPPER_SNAKE_CASE (`ENDING_COLLAPSE`)

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.6 ms
- **Draw Calls**: [TO BE CONFIGURED after the first graybox pass]
- **Memory Ceiling**: [TO BE CONFIGURED after the first asset pass]

## Testing

- **Framework**: Native headless Godot scene/script tests now, GdUnit4 when the test harness is added
- **Minimum Coverage**: 100% for slice data contracts and branch/state transitions; integration coverage for boot flow and both endings
- **Required Tests**: Boot validation, artifact/slot contracts, deterministic director sequencing, negative interaction paths, ending branches

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- Runtime node-path lookups or ID resolution inside interaction/reveal hot paths
- Mixing authored slice content with timing/tuning constants in the same file
- Splitting first-slice sequencing into separate camera/caption/ending manager scripts

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- GdUnit4 when the test harness is introduced

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- First slice: one root play scene, one root director, one authoritative run state, one slice content table, one separate tuning config
