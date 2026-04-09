# TODOs

## Add Reusable Ripple/Content Compiler After The Second Playable Slice

**What:** Replace the one-off first-slice content loader with a small reusable ripple/content compiler once the project has at least two playable destiny threads.

**Why:** The current v1 plan correctly uses one explicit slice table plus one root director. That will stay clean for a single sequence, but a second slice will start duplicating artifact rules, branch logic, validation checks, and runtime compilation steps unless there is a shared content pipeline.

**Pros:** Reduces duplicated content logic, gives later slices a cleaner expansion path, and keeps validation consistent across multiple story threads.

**Cons:** Adds abstraction and maintenance burden too early if attempted before the first slice is proven. It is not worth paying that cost for one guided demo.

**Context:** `/plan-eng-review` deliberately chose the boring v1 shape: one root play scene, one authoritative run-state object, one root director script, one slice content table, and one separate tuning config. That is the right first implementation. This TODO exists to mark the point where that approach should evolve instead of being copied.

**Depends on / blocked by:** Ship the first slice or commit to a second playable destiny thread with shared artifact / branch semantics.

**Trigger To Revisit:** The moment a second playable slice would copy the first slice's content schema, validation rules, or branch-resolution flow.
