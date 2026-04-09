# BTTF Design System

Last updated: 2026-04-01
Applies to: `BTTF`
Current anchor slice: `Father Time Diorama`

## Core Thesis
This project should feel like a handcrafted miniature Back to the Future world under glass.

Primary read:
- whimsical toy world
- tactile, inviting, hand-touched
- charming enough to invite interaction

Secondary accent:
- retro-futurist stage-model spectacle
- used only during timeline transitions, consequence moments, and ending reveals
- never the baseline look of the whole runtime

This is not a generic cozy diorama.
This is not a theme-park ride all the time.
This is not a sleek sci-fi dashboard game.

It is a treasured BTTF relic that the player is allowed to touch.

## Emotional Target
The emotional sequence should be:

1. Reverent wonder
2. Careful curiosity
3. First proof of consequence
4. Growing responsibility
5. Controlled awe or beautiful disaster

The player should first feel that the world is precious.
Then they should feel that their touch matters.
Then they should feel the cost of changing history.

## World Language
### Scale
- Everything should read as intentionally miniature.
- Small details should support scale illusion: tiny bulbs, painted trim, lacquered surfaces, miniature props, controlled depth cues.
- Depth of field should reinforce scale, not hide composition.

### Materials
Favor:
- painted wood
- lacquer
- enamel signage
- brushed metal accents
- tiny practical bulbs
- lightly worn trim
- tactile collector-object finishes

Avoid:
- generic fantasy-stylized surfaces
- noisy grunge everywhere
- over-realistic grime that kills the toy-world feeling
- plastic-looking “default game asset” materials

### Lighting
Baseline lighting should be:
- warm
- readable
- focal
- controlled

Use theatrical lighting only when the story earns it:
- era transitions
- timeline ripples
- saved ending
- paradox collapse

Do not rely on:
- bloom everywhere
- haze everywhere
- color grading as a substitute for real art direction

### Motion
Idle motion:
- gentle
- charming
- subtle

Reveal motion:
- deliberate
- staged
- easy to read

Consequence motion:
- escalates only after meaningful action
- should clarify causality before it adds spectacle

## Anti-Slop Rules
Do not ship any of these:

- “Cute tiny town” with no specific BTTF identity
- Constant dreamy blur and bloom with no clear focal hierarchy
- Generic retro nostalgia palette disconnected from story function
- UI that looks like stock game prompts or debug overlays
- Every shot equally spectacular
- Every scene equally whimsical
- Random prop clutter that makes interaction harder to read

If a design choice can be described as “clean, modern, cinematic” without saying anything more specific, it is not finished.

## Camera Philosophy
### Default
- guided camera with limited local orbit

### Rules
- The game owns major framing and era transitions.
- The player may make small local adjustments during interaction.
- The player should never be able to destroy the intended hero composition during key reveals.
- Camera transitions must answer one question: “What changed because of me?”

### Composition
- One hero era at a time.
- Other eras may appear as glimpses, reflections, or teaser frames, but should not compete equally.
- The Clock Tower / courthouse should remain a visual and emotional anchor across the project.

## UI Philosophy
UI should feel like museum placards or exhibit captions, not game widgets.

### Allowed Surfaces
- era title card
- artifact caption
- destination/context prompt
- ending outcome caption

### UI Rules
- The world is always the main surface.
- UI appears only when needed and recedes quickly.
- If staging, motion, or lighting can communicate the information, prefer that over more text.
- No persistent dashboard unless a future design explicitly justifies it.

### Tone
Text should feel:
- elegant
- restrained
- curator-like
- readable

Text should never feel:
- jokey by default
- arcade-like
- debug-like
- system-message-like

## Typography Direction
Typography should support the “curated relic” feeling.

Rules:
- Favor high-legibility serif or serif-adjacent display moments for titles and placards.
- Favor restrained readable body text for captions.
- Avoid default game UI fonts that feel synthetic or placeholder-like.
- Do not use typography that feels too tech-startup, too comic, or too theme-park camp.

Until implementation selects exact fonts, the governing rule is:
titles should feel archival or exhibit-like;
support text should disappear into clarity.

## Color Direction
Baseline palette:
- warm practical lights
- aged civic colors
- lacquered collector-object richness
- readable contrast

Accent palette:
- time-ripple electric energy
- controlled future-tech pulses
- corruption tones used sparingly for Biff pressure and collapse states

Color should separate:
- safe vs corrupted
- inert vs interactive
- baseline world vs earned spectacle

Do not rely on color alone for interaction meaning.

## Interaction Feel
Artifact interaction should use a magnetic slot illusion.

Rules:
- The player should feel like they are lifting a physical miniature object.
- The world should still resolve that gesture into authored meaningful destinations.
- Valid destinations attract.
- Invalid space stays quiet.
- Commitment should always feel crisp and unambiguous.
- Cancel should feel graceful, not punishing.

## Readability and Accessibility
### Presentation
- Primary target: desktop and laptop
- Mouse + keyboard first
- Controller can come later
- Mobile-first adaptation is not required for the first polished slice

### Readability
- Critical text must be readable from a small-to-medium viewing distance.
- Decorative styling must never overpower legibility.
- Labels should be short enough to scan instantly.

### Interaction Accessibility
- Valid and invalid states must not rely on color alone.
- Use motion, emphasis, brightness, or attraction behavior as secondary signals.
- Target zones should be forgiving.
- Locked states should fail quietly and consistently.

### Motion Comfort
- Camera easing should feel controlled, not floaty.
- Reveal effects should be readable before they are intense.
- If the project expands, add a reduced-motion mode for transitions and ripple intensity.

## What This Project Is Not
- Not a broad sandbox first
- Not a HUD-heavy systems game first
- Not a generic cozy miniature game
- Not a constant spectacle machine
- Not a realism-first simulation

The first versions should feel small, clear, precious, and intentional.

## Implementation Gate
Before adding a new UI surface, visual effect, or environment treatment, ask:

1. Does this help the player understand history, consequence, or significance?
2. Does this preserve the treasured-miniature feeling?
3. Is this baseline language, or should it be saved for an earned reveal?
4. If removed, does the scene become clearer?

If the answer to `4` is yes, cut it.

