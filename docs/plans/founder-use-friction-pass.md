# Founder-Use Friction Pass

## Objective

Remove the observed M0 friction in Capture, Today, Library, and Review while preserving the existing learning loop and architecture:

```text
Capture → Retrieve → Produce → Resurface
```

This is a reliability, continuity, and product-identity pass. It does not add a new learning mode or restart market research.

## What already exists

- Flutter application with Linux desktop and Android as first-class targets.
- `shadcn_ui` component foundation with centralized color, spacing, and radius files.
- Adaptive shell using bottom navigation below 760px and a navigation rail at wider sizes.
- Stable `IndexedStack` screen identity across shell breakpoint changes.
- Supabase repositories behind application interfaces; widgets do not import the SDK.
- Learning items with append-only review attempts and transactional review completion.
- Dark and light neutral themes with one replaceable semantic brand-accent token.

There was no `DESIGN.md` before this review. This pass will add a concise one and keep runtime values in Dart theme tokens.

## Design decisions

1. Today uses one ordered flow on narrow and medium layouts. At 960px and above it becomes a primary column plus a narrower context rail.
2. Library uses a dedicated full-width detail surface below 960px and a list/detail workspace at 960px and above.
3. Meaning lookup results stay in the Capture scroll flow directly below Meaning. Parts of speech are headings and senses are selectable rows.
4. Today distinguishes first use, waiting, and completed-today states using persisted data, never session-only flags or fake values.
5. A Capture draft is meaningful when any user-authored field is nonblank or a lexical sense was selected. Changing only item type is not meaningful.
6. Exiting Review pauses the in-memory session. Today offers Resume review; only successful completion or explicit discard clears the production response.
7. Feature surfaces use deterministic asymmetric 24/14 radii. Controls remain 6px; compact surfaces use a restrained uniform 10px.
8. The content breakpoint is 960px. The shell navigation breakpoint may remain 760px.
9. `Draft restored` is an inline polite status beneath the Capture introduction and remains until the first edit, sense selection, save, or discard.
10. Android production text selection uses a compact controlled toolbar with Cut, Copy, Paste, and Select all when applicable. Desktop retains its appropriate mouse/keyboard editing behavior.

## Information architecture

```text
Workspace
├── Today
│   ├── Due / Resume review                 primary
│   ├── Completed today                     secondary continuity
│   ├── Recently captured                   context
│   └── Next review                         context
├── Capture
│   ├── Type + language
│   ├── Meaning actions
│   │   └── Inline grouped lookup results
│   ├── Editable meaning
│   ├── Context + source
│   └── Save / Discard
└── Library
    ├── Item list
    └── Item detail
        ├── Captured fields + schedule/counts
        └── Chronological review history
```

Wide Today:

```text
┌──────────────────────────────────┬──────────────────────┐
│ Due / Resume                     │ Recently captured    │
│ primary review action            │ compact item rows    │
│                                  │                      │
│ Completed today                  │ Next review          │
│ actual counts + practiced items  │ calendar-aware label │
└──────────────────────────────────┴──────────────────────┘
```

Wide Library:

```text
┌────────────────────────┬─────────────────────────────────┐
│ Library list           │ Selected learning item          │
│ stable selected row    │ fields, counts, review history  │
└────────────────────────┴─────────────────────────────────┘
```

## Interaction states

| Feature | Loading | Empty | Error | Success | Partial / refresh |
|---|---|---|---|---|---|
| Capture draft | Local restore before normal workspace destination is chosen | Default clean form | Local read/write failure leaves current controllers usable and reports restrained status | Draft restored into all fields and lexical selection | Debounced local writes; latest controller state wins |
| Dictionary lookup | Inline bounded skeleton/progress beside lookup action | `No meanings found`; manual entry stays available | Inline failure with Retry; manual entry stays enabled | POS headings with selectable senses | Existing typed meaning remains untouched until a sense is selected |
| Today initial load | Restrained content-shaped skeleton; never empty copy | First capture, waiting, or completed-today state selected from successful data | Full load failure with Retry | Due, continuity, and next-review data shown | Existing content remains interactive; small refresh status only |
| Library detail | Detail-shaped placeholder while history loads | `No review history yet` within an otherwise usable item detail | Item remains visible; history section shows retryable failure | Metadata and chronological attempts | Selected item/list remain visible during refresh |
| Review | Existing item/stage remains visible while saving | No due work returns to Today completion/waiting state | Response, stage, and submission ID remain intact with retry | Successful rating advances queue | Exit pauses; background refresh cannot erase active state |

Overlapping loads use generation/request identity so stale completions cannot replace newer state.

## Today zero-due rules

- No learning items: first-capture state with Capture as the primary action.
- Learning items, no due items, no completed attempts today: `Nothing due right now`, recent captures, and next review.
- Completed attempts today: `You're done for today`, real reviewed/produced counts, recently practiced items, and next review.
- Completion state is reconstructed from repository data after restart; it is not an in-memory celebration flag.

## Capture lookup behavior

- Lookup occurs only after explicit `Find meaning` activation.
- `Enter manually` always focuses/enables the editable Meaning field.
- Results group every supported returned part of speech and preserve provider order of senses.
- Selecting a sense fills Meaning, retains the selected part of speech, closes the expanded results, and leaves Meaning editable.
- Context is displayed as supporting capture data only and does not rank senses.
- Provider identifiers are not persisted.
- Failure and zero results never block Save.

## Library detail behavior

- Mobile and medium: selecting a row opens a full-width detail surface with a clear Back action.
- Wide: selecting a row keeps the list visible and moves keyboard focus to the detail heading; Escape or the list returns focus to the selected row.
- Review attempts are ordered newest-first for scanability while preserving exact timestamps.
- Retrieval and production attempts from one submission may be visually grouped without hiding either record.
- Production response text is selectable and wraps; no charts or inferred mastery values are shown.
- Crossing 960px preserves the selected item and loaded history.

## Review focus behavior

- Active Review hides the shell's primary bottom navigation and navigation rail.
- A top-leading Back/Close action pauses the session and returns to Today.
- Today replaces Start review with Resume review while a session is paused.
- Production text, item, stage, progress, and submission ID survive pause/resume and save failures.
- Explicit discard uses consequence-bearing copy and is never triggered by ordinary Back.
- Mobile spacing contracts when the IME is visible; actions remain reachable without large dead areas.
- Android uses the controlled essential selection toolbar only for the production field; desktop keeps standard editing affordances.

## Visual system

```text
control             6px uniform
compactSurface     10px uniform
organicA           TL 24, TR 14, BR 24, BL 14
organicB           TL 14, TR 24, BR 14, BL 24
```

Usage:

- Inputs, buttons, toolbars, navigation indicators: control radius.
- Small status/error containers: compact surface radius.
- Primary Due and Completed-today surfaces: organic presets.
- Repeated Library and Today feature rows: stable A/B selection derived from item identity or stable index; never random.
- Next review and simple metadata remain typographic rather than gaining decorative cards.
- Borders stay 1px and neutral. No gradients, blobs, giant KPI cards, pills everywhere, decorative shadows, or ornamental icons.

## Responsive and accessibility specification

| Width | Presentation |
|---|---|
| `< 640px` | Touch-first single column, compact vertical spacing, full-width detail, IME-safe Review actions |
| `640–959px` | Comfortable single column with restrained max width; shell may use rail from 760px |
| `≥ 960px` | Today primary/context columns; Library master-detail; denser but calm spacing |

- Important state survives transitions across 640px, 760px, and 960px.
- Interactive touch targets are at least 44px on narrow layouts.
- Focus order follows visual order; focus movement is explicit when detail opens/closes.
- Focus indicators remain visible without oversized textarea rings.
- Headings and status changes have useful semantics; restored/error/completion messages use polite live regions.
- Text maintains body contrast of at least 4.5:1 and remains usable with increased text scaling.
- No essential action depends on hover.

## Journey storyboard

| Step | User does | Intended feeling | Supporting design |
|---|---|---|---|
| 1 | Encounters language and starts Capture | Safe to leave and research | Debounced local draft, cold-start restoration |
| 2 | Requests a meaning | Assisted, not trapped | Explicit inline lookup plus permanent manual path |
| 3 | Returns later | Continuity | Restored status and Capture destination recovery |
| 4 | Opens Today | Oriented | Truthful loading, due action, recent captures, completion evidence |
| 5 | Reviews and produces language | Focused | Hidden primary nav, compact mobile layout, safe pause |
| 6 | Completes the queue | Finished rather than emptied | Persisted completed-today summary and next review |
| 7 | Opens Library history | Progress is tangible | Actual prior production text and scheduling history |

## NOT in scope

- AI-generated definitions, AI sense ranking, custom ML, or a custom dictionary database.
- Global lexemes, word families, collocations, pronunciation, per-sense mastery, or inferred mastery scores.
- New learning modules, gamification, analytics, social features, or authentication UI.
- General offline database/sync engine or persisted Review sessions across process death.
- Navigation or state-management framework changes.
- Hosted Supabase mutation without separate explicit approval.

## Implementation tasks

- [ ] **T1 (P1, human: ~1 day / Codex: ~1h)** — Capture — Add local draft restoration, explicit discard, restored status, and regression tests.
- [ ] **T2 (P1, human: ~1 day / Codex: ~1h)** — Capture — Add explicit inline dictionary lookup with grouped POS/senses and editable selection.
- [ ] **T3 (P1, human: ~1.5 days / Codex: ~1.5h)** — Today — Implement truthful load/refresh states and adaptive continuity home.
- [ ] **T4 (P1, human: ~1.5 days / Codex: ~1.5h)** — Library — Implement adaptive item detail and chronological review history.
- [ ] **T5 (P1, human: ~1 day / Codex: ~1h)** — Review — Add focus mode, pause/resume preservation, compact Android selection menu, and mobile spacing polish.
- [ ] **T6 (P2, human: ~0.5 day / Codex: ~30m)** — Design system — Add `DESIGN.md`, semantic radii, stable organic variants, and component usage updates.
- [ ] **T7 (P1, human: ~1 day / Codex: ~1h)** — Adaptive QA — Cover narrow, medium, wide, keyboard, touch, text scaling, refresh, and breakpoint state preservation.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|---|---|---|---:|---|---|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | Not run | Not required for this bounded founder-friction pass |
| Codex Review | `/codex review` | Independent second opinion | 0 | Not run | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 0 | Required next | Draft persistence, provider boundary, schema, and queries remain to resolve |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | Clear | 7/10 → 10/10; 10 decisions resolved |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | Not run | Not applicable |

**VERDICT:** DESIGN CLEARED; engineering review required before implementation.

NO UNRESOLVED DECISIONS
