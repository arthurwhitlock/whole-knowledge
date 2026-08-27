# Whole Knowledge Design

Whole Knowledge is calm, content-first, and built for repeated founder use on
Android and Linux. The interface should make the learning loop feel direct:
capture language, understand it, retrieve it, produce it, inspect mistakes,
and reuse it.

## Layout

- Compact screens use 16 px horizontal page padding and full-page navigation.
- Medium screens retain the same task order with more breathing room.
- At 960 px, Today becomes a primary column plus context rail, and Library
  becomes master-detail.
- The application shell changes from bottom navigation to a rail at 760 px.
- Review is a focus mode: shell navigation disappears until completion or an
  explicit pause.

## Shape and spacing

Controls use the centralized 6 px radius. Repeated content surfaces use one of
two deterministic asymmetric shapes: 14/6 px for compact rows and 24/10 px for
prominent task surfaces. The asymmetry is structural, never randomized.
Spacing uses the centralized 8, 16, 24, 32, and 48 px scale.

## Color and type

Use the semantic shadcn-based light and dark schemes. Borders stay subtle,
surfaces remain neutral, and the replaceable brand accent is reserved for
action and focus. Typography should establish hierarchy through weight and
size rather than decoration.

## Interaction and accessibility

- Every action must remain reachable by keyboard, mouse, and touch.
- Focus is visible, controls expose semantics, and errors use live regions.
- Text fields intentionally expose only Cut, Copy, Paste, and Select all in the
  Flutter context menu.
- Background refresh preserves visible content and presents quiet progress.
- Destructive draft clearing is explicit and confirmed.
- Content must reflow without horizontal scrolling at supported text scales.
