# Father Time Diorama Visual Target

Status: DRAFT

## Purpose

This document resets the visual target for the current `Father Time Diorama` slice.

The current build is mechanically valid but visually wrong. It reads like a test board with labels, not a magical collectible object. The next scene pass should optimize for one question:

**Does this look like a cool toy under glass that invites you to touch history?**

If the answer is no, the scene is still off target.

## Core Visual Thesis

The slice should feel like:

- a **collector snowglobe**
- with a little **museum reverence**
- and just enough **toy-like whimsy**

It should **not** feel like:

- three flat stage slabs
- debug markers and instructional overlays
- generic blockout architecture with names pasted on top
- a strategy board or puzzle prototype

The whole world should first read as **one precious object on a pedestal**. Only after that should the player read the active era inside it.

## Emotional Read

The intended emotional sequence is:

1. **Curiosity**: "What is this object?"
2. **Recognition**: "Oh, this is Hill Valley inside a snowglobe."
3. **Invitation**: "I can move something important here."
4. **Power**: "I am changing history with my hands."
5. **Payoff**: "The whole miniature reconfigured because of me."

If the player instead feels:

- "What am I looking at?"
- "Why are these boxes here?"
- "Why is the HUD explaining everything?"

then the scene is failing its job.

## Object-Level Rules

### The globe itself must be real

The player should see a literal object:

- glass dome silhouette
- strong base/pedestal
- one readable object boundary
- world contained *inside* the object

The current presentation feels like scenery placed on a platform. The next pass should make the object identity unmistakable.

### The pedestal must feel intentional

The pedestal should read as:

- brass or warm dark metal
- collector-display craftsmanship
- subtle plaque or plate language

It should not read as:

- a generic brown box
- a plain debug platform
- oversized furniture

### Background should support the object

The backdrop should frame the globe, not flatten it.

Preferred direction:

- dark museum-wall or display-room feeling
- subtle spotlight/falloff
- enough negative space that the globe silhouette is legible

Avoid:

- flat gray emptiness
- stage-black void with no atmosphere
- bright noisy backgrounds

## Camera and Framing Rules

### Object-first framing

The player must be able to understand the diorama as a whole object without guessing.

Rules:

- the full miniature should mostly fit in frame
- the tray can exist in the foreground, but should not dominate the composition
- the active era should feel centered within the globe, not cropped into abstraction

### One active era, full object context

The camera can still privilege one era at a time, but it should do so while preserving the sense that the player is looking into a single contained object.

Meaning:

- no claustrophobic close-up on anonymous geometry
- no framing that hides the collectible-object silhouette
- transitions should feel like gentle guided inspection of a precious object

### Tilt-shift / miniature feeling

The miniature effect should come from:

- composition
- silhouette scale relationships
- object containment
- selective polish

Not from:

- excessive blur
- fake bloom everywhere
- post-processing trying to rescue weak forms

## Era Composition Targets

## 1955

Visual mood:

- warm postcard miniature
- clear and romantic
- simple but iconic

Composition target:

- **Clock Tower** is the dominant rear landmark
- **Town Square** sits left foreground or left midground
- **Doc's Diner** sits right-midground
- a curved street or rail cue ties the composition together

What the player should understand immediately:

- this is the BTTF hometown miniature
- the flyer matters in this civic/public part of the town
- the world is legible without relying on labels

## 1985

Visual mood:

- louder
- more commercial
- slightly corrupted by excess

Composition target:

- Biff-pressure landmark is bulkier and more aggressive
- mall/commercial shape feels wider and more suburban
- signage or billboard forms break the cleaner 1955 rhythm

What the player should feel:

- this era is less elegant
- more cluttered
- more compromised

## 2015

Visual mood:

- sleek toy-future
- cleaner geometry
- hero-object presentation

Composition target:

- **DeLorean** is a clear hero piece
- **Hover Lane** is long and unmistakably futuristic
- **Clock Tower Spire** should still connect the future to the town's visual identity

What the player should feel:

- this is the payoff era
- the whole slice has been building toward a final commitment here

## Interaction Surface Rules

### Placement spots must feel built in

Valid artifact destinations should look like part of the miniature itself.

Preferred direction:

- brass sockets
- tiny plinths
- engraved plates
- inset mounts

Avoid:

- floating spheres
- generic glowing beacons
- anything that reads like editor gizmos

### The tray should feel ceremonial

The artifact tray is good in principle, but it should feel like:

- a curated handling surface
- a display lip at the front of the globe
- something Father Time would lift artifacts from

It should not feel like:

- a random inventory shelf
- a hotbar
- a separate gameplay UI widget bolted to the scene

### The world should explain itself

The scene should rely less on overlay text and more on:

- recognizable silhouettes
- composition
- material contrast
- placement surface affordance

Labels should be backup support, not the primary source of meaning.

## UI Restraint Rules

The current overlay explains too much because the world explains too little.

Target:

- one small objective plaque
- one small consequence read
- minimal presence

Avoid:

- stacked debug-like instruction blocks
- large dark boxes covering the miniature
- HUD language doing the work that the scene should do

## Ending Tableau Rules

### Saved ending

Saved should feel:

- orderly
- cleaner
- centered
- display-ready

The miniature should look like it has snapped into its intended form.

### Collapse ending

Collapse should feel:

- skewed
- tilted
- unstable
- like the object itself is failing

The miniature should visibly distort, not merely recolor.

## Hard Do / Don't

### Do

- make the globe silhouette readable
- build stronger landmark silhouettes
- use warm collectible-object materials
- stage each era as a deliberate miniature composition
- reduce HUD dependence
- make interaction points feel tactile and embedded

### Don't

- keep stacking polish on generic block forms
- rely on labels to create recognition
- let the tray dominate the lower frame
- use debug-looking markers as final interaction language
- solve weak composition with text
- solve weak forms with post-processing

## Immediate Rebuild Implications

The next implementation pass should prioritize:

1. Rebuild the root scene so the object reads as a real snowglobe/display piece.
2. Recompose each era with stronger silhouette hierarchy, especially `1955`.
3. Replace placement markers with built-in miniature sockets/plinths.
4. Shrink the overlay down to a much lighter plaque treatment.
5. Re-evaluate camera framing only after the rebuilt object exists.

## Success Criteria

The visual reset is successful when:

- a player can identify the scene as a collectible BTTF miniature before reading any text
- `1955` feels recognizable from shape alone
- the active objective feels inviting instead of confusing
- the world feels tactile and toy-like
- the slice looks interesting even in a silent screenshot
