# Whole Knowledge Design

Whole Knowledge is a quiet, personal Language OS built for serious repeated
use. Its interface should feel editorial, warm, exact, and composed: closer to
a well-made reference book than a gamified learning product. Visual refinement
must always serve the learning loop:

```text
Capture → Understand → Retrieve → Produce → Analyze mistakes → Reuse
```

The primary development reference is dark mode, but light and dark themes share
the same hierarchy, composition, interaction model, and semantic roles.

## Principles

- Content is the ornament. Decoration never competes with language.
- Hierarchy comes from proportion, spacing, typography, and surface contrast.
- One primary task dominates each screen; secondary context recedes.
- Repeated content is presented as editorial rows and sections, not a dashboard
  of interchangeable cards.
- Quiet luxury means material restraint and precise details, not added chrome.
- Product truth stays visible. Empty states and learning metrics never imply
  progress that the system has not measured.

## Color

All interface colors come from semantic tokens in `AppColors`. Raw palette
values should not be scattered through widgets.

### Dark palette

| Role | Value |
| --- | --- |
| Background | `#0A0908` |
| Surface / card | `#12100E` |
| Elevated surface | `#191612` |
| Foreground | `#F2EEE6` |
| Muted foreground | `#AAA298` |
| Border | `#302B24` |
| Brand accent | `#B7A16F` |
| Accent-subtle surface | `#292318` |
| Destructive | `#C97870` |

### Light palette

| Role | Value |
| --- | --- |
| Background | `#F7F3EC` |
| Surface / card | `#FCFAF6` |
| Elevated surface | `#EEE7DC` |
| Foreground | `#201C17` |
| Muted foreground | `#6C655B` |
| Border | `#D8D0C4` |
| Brand accent | `#76613B` |
| Accent-subtle surface | `#E8DFD0` |
| Destructive | `#9B3D36` |

The accent is one replaceable semantic token. It marks primary action, focus,
selection, and meaningful progress. It is not a general decoration color.
Foreground, muted text, and primary-action pairings meet WCAG AA contrast in
both reference palettes.

## Typography

The application uses the Geist family bundled with `shadcn_ui`; no network font
or additional font package is required. The scale is defined centrally in
`AppTypography`.

| Role | Size / line | Weight | Tracking |
| --- | --- | --- | --- |
| Display / page title | 34 / 40 | 600 | -0.6 |
| Feature title | 28 / 34 | 600 | -0.45 |
| Section title | 21 / 28 | 600 | -0.25 |
| Subheading | 17 / 24 | 600 | 0 |
| Lead | 18 / 27 | 400 | 0 |
| Body | 16 / 25 | 400 | 0 |
| Label | 13 / 18 | 600 | +0.25 |
| Metadata | 13 / 19 | 400 | +0.1 |

Page titles are used once. Feature titles identify the dominant task or item.
Labels are short and functional. Metadata may recede in color but must remain
readable. Uppercase is reserved for brief editorial eyebrows and summary
labels, with added tracking.

## Spacing and shape

Spacing uses the centralized 4, 8, 16, 24, 32, 48, and 64 px scale. Compact
screens use 16 px horizontal page padding; wider screens use 24 px. Forms are
limited to 720 px, editorial workspaces to 1180 px, and Library's desktop list
to 400 px.

Controls use a 7 px radius and ordinary surfaces use 12 px. Expressive surfaces
use one of two deterministic asymmetric radii:

- Organic A: 24 / 14 / 24 / 14 px.
- Organic B: 14 / 24 / 14 / 24 px.

The two shapes alternate only when structure benefits from it. They are never
randomized, nested excessively, or applied to every control.

## Layout and navigation

- Below 760 px, the shell uses native Material bottom navigation.
- At and above 760 px, it uses a native Material navigation rail.
- At and above 960 px, Today becomes a dominant 3:2 composition and Library
  becomes a fixed-list / fluid-detail master-detail workspace.
- Navigation keeps native semantics, focus behavior, keyboard handling, and
  state restoration. Whole Knowledge styling is applied through theme tokens.
- Review is a focus mode: shell navigation disappears until completion or an
  explicit pause.

### Today

The review queue is the dominant filled surface. It owns the strongest title,
accent treatment, and primary action. Recently captured, completed today, and
next review form an unboxed context rail with dividers and quieter type. Quick
Capture is tertiary.

### Capture

Capture is a centered, calm, focused document that advances through Entry,
Checking, Meaning, Re-encounter, Production, and Discovered without becoming a
generic wizard. One initial word/expression field dominates Entry. The suggested
Vocabulary/Expression type remains visible, lightweight, and overridable.

Library and dictionary progress appear independently. Vocabulary meanings use
editorial part-of-speech headings and rows rather than sense cards; every POS
stays visible, each group initially shows two senses, and expansion is local to
that group. A selected dictionary meaning is summarized first and editable by
progressive disclosure. Manual meaning and optional encounter details remain
available without competing with the primary task.

First production is part of Discovery. Meaning or type edits preserve authored
production but invalidate stale confirmation visibly. The in-flow primary and
defer actions remain keyboard/IME-aware and scrollable rather than being pinned
behind input. Re-encounter keeps learned answers hidden until reveal, selects a
sense before presenting one shared action group, and uses the existing focused
Review. Discovered ends with `Done` primary and `Capture another` secondary.

### Library

Library uses dense editorial rows rather than mini-cards. Selection is shown by
a subtle fill, asymmetric shape, and narrow accent marker. The detail pane
prioritizes language, meaning, and context, then shows truthful review,
production, and next-review data in one learning summary. Individual review
attempts are the only repeated record surfaces.

### Review

Review exposes four explicit stages: Retrieve, Check, Produce, and Self-rate.
The current stage is visible, announced semantically, and reinforced by a
restrained progress line. The language stays visually dominant while notes,
response, and actions change in place.

## Motion

Motion is functional and centralized in `AppMotion`:

| Intent | Duration | Use |
| --- | --- | --- |
| Instant | 120 ms | exits and tiny feedback |
| Interaction | 160 ms | selection and control-state changes |
| Standard | 220 ms | stage and content transitions |
| Structural | 300 ms | bounded size changes |

Transitions use opacity, 4–8 px translation, selection color, or bounded size.
No bounce, parallax, decorative looping, large travel, or animation framework
is appropriate. `MediaQuery.disableAnimations` reduces all nonessential custom
transition durations to zero while preserving state changes and meaning.

## Components and states

- Primary buttons use the brand accent and a high-contrast foreground.
- Outline and ghost buttons express secondary and tertiary actions.
- Inputs use subtle borders, visible semantic focus rings, and destructive
  colors only for genuine errors.
- Selected navigation and Library rows use accent-subtle surfaces, not bright
  pills.
- Loading preserves stable content where possible. Errors use live regions and
  keep retry actions adjacent to the failure.
- Empty states are concise and truthful; they do not manufacture streaks,
  mastery, rewards, or urgency.

## Accessibility

- Every action remains reachable by keyboard, mouse, and touch.
- Native navigation behavior is preserved and selected states are semantic.
- Focus is visible and uses the semantic ring / brand-accent token.
- Errors and review-stage changes use live regions or explicit semantic labels.
- Text and controls retain readable contrast in light and dark themes.
- Content reflows without horizontal scrolling at supported text scales.
- Capture actions wrap into a readable vertical flow at large text scales and
  retain at least a 48 px target at ordinary scales.
- Phase headings receive focus after transitions; invalid fields and revealed
  meanings receive focus when recovery requires it.
- Independent service progress, errors, phase changes, review timing, and
  Discovered state use concise live-region or explicit semantic announcements.
- Motion honors the platform reduced-motion preference.
- Text fields intentionally expose only Cut, Copy, Paste, and Select all in the
  compact Flutter context menu.
- Destructive draft clearing remains explicit and confirmed.

## Anti-patterns

Do not introduce cartoon mascots, childish gamification, fake streaks,
decorative rewards, bright lime learning colors, neon, gradients,
glassmorphism, oversized KPI dashboards, giant rounded cards, excessive pills
or shadows, arbitrary animation, or decoration without function. Do not turn
the native Flutter application into a literal web shadcn clone.
