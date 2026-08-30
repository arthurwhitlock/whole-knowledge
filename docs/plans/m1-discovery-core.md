# Whole Knowledge M1 — Discovery Core

Status: CEO- and engineering-reviewed specification

Mode: Scope Reduction

Approved approach: Focused Discovery vertical slice on the existing application seams
Date: 2026-08-30

## 1. M1 product promise

Whole Knowledge M1 turns an encountered English word or manually explained
expression into one understood, personally used learning item without making
Capture feel like data entry.

```text
Enter language
→ discover or explain the intended meaning
→ use it in an original sentence, or explicitly defer production
→ save one retry-safe learning item
→ retrieve it later through the existing Review loop
```

The product reward is the knowledge revealed and used. M1 adds no points,
currency, streak pressure, arbitrary levels, rewards, or mastery theater.

## 2. CEO verdict and premise challenge

The right problem is not “make Capture more game-like.” The right problem is
to turn Capture into a small learning event. M0 already owns durable drafts,
lexical lookup, adaptive navigation, secure persistence, scheduled Review, and
real learning history. M1 should recompose those strengths around intended-sense
selection and first production rather than create a second learning engine.

Doing nothing leaves a real founder-use problem: the current long Capture form
feels administrative, and it has already required a regression fix to reveal an
invalid field above the viewport. A cosmetic relayout would not change the
interaction. A generalized knowledge engine would make unvalidated evidence and
visual metaphors load-bearing. The approved middle path is a complete Discovery
slice.

Engineering review preserved that product promise while reducing the
implementation footprint. M1 evolves the existing Capture controller, draft
repository, learning-item repository, workspace, and Review controller. It does
not introduce a second state-management system, navigation stack, repository
family, or generic wizard framework. Eighteen architecture, code-quality, test,
and performance findings were resolved; none remain open.

Landscape synthesis:

- **Tried and true:** language products reduce lookup friction and feed saved
  words into later review; knowledge tools connect capture to resurfacing.
- **Current product pattern:** tools such as LingQ and Readwise emphasize
  contextual capture and revisit. The existing EnglishDictionaryAPI already
  supplies multiple parts of speech, definitions, examples, and related lexical
  data without AI.
- **Whole Knowledge insight:** the wedge is not faster storage. It is the handoff
  from encounter to intended sense to original use, with a low-friction escape
  when the learner genuinely cannot finish.

Sources consulted:

- [EnglishDictionaryAPI](https://englishdictionaryapi.com/)
- [LingQ](https://www.lingq.com/en/)
- [Readwise](https://readwise.io/)
- [Dictionary information-load guidance](https://scielo.org.za/scielo.php?pid=S2224-00392021000100004&script=sci_arttext)

## 3. Smallest coherent M1 scope

M1 ships exactly these product capabilities:

1. Capture remains the middle mobile navigation destination and receives
   restrained visual prominence. Desktop keeps a prominent native rail
   destination.
2. The initial Capture surface contains one language input and one Discover
   action.
3. Single-token input suggests Vocabulary; multi-token input suggests
   Expression. The suggestion is always visible and overridable.
4. English Vocabulary runs automatic lexical discovery, then requires intended
   sense selection or a manual meaning.
5. Expression uses a distinct manual meaning flow with no POS-heavy dictionary
   interface.
6. First production is the primary completion path. A secondary Save and finish
   later action defers only production, never meaning.
7. Exact normalized re-encounters show all already learned senses and default to
   Show meaning or Test myself instead of creating another item.
8. A successful save ends on an in-place Discovered confirmation.

M1 does not include Today’s Captures, Library organization, Meaning Match,
knowledge visualization, multilingual intelligence, deep exploration, or
monetization. Accepted follow-ups live in `TODOS.md`.

## 4. Mobile Capture entry and navigation role

Mobile keeps Capture as the middle native `NavigationDestination`, not a modal
or floating action. Its icon sits in a restrained 44–48px accent-subtle field
with a 1px accent border. Selection strengthens fill and foreground without
growing, floating, bouncing, or losing the text label. Native focus, semantics,
touch targets, selection, keyboard handling, and restoration remain intact.

Desktop uses the same destination and capability through the native
`NavigationRail`. A narrow accent marker and stronger icon/label treatment
provide prominence; the mobile center shape is not copied literally.

### Shared phase composition

Capture remains one centered, phase-replacing document on every supported
width. It uses 16px horizontal padding below 640px, 24px above it, and the
existing 720px form maximum. Desktop does not split Capture into side-by-side
context and task panes, and no persistent wizard rail or step counter is added.

```text
Capture destination
└── focused document · max 720px
    ├── orientation       Capture + Back after Entry
    ├── subject           encountered language + visible type override
    ├── active task       one phase heading and one concise prompt
    ├── working content   choices, input, or learned-sense rows
    ├── supporting detail Add encounter details disclosure, when relevant
    ├── recovery/status   adjacent to the content it affects
    └── actions           one primary action + restrained secondary escape
```

The first three scan targets in each phase are fixed:

| Phase | First | Second | Third |
|---|---|---|---|
| Entry | `What did you encounter?` | Language input with visible type suggestion | `Discover` |
| Vocabulary Discovery | Encountered term and Vocabulary override | POS-grouped intended-sense choices plus manual meaning | Continue to production |
| Expression Meaning | Encountered expression and Expression override | `What does it mean here?` and the meaning input | Continue to production |
| Re-encounter | Encountered term and `Already in your knowledge` | All exact learned-sense rows | List-level `Learn another sense`, plus selected-item `Test myself` and `Show meaning` |
| Production | Term, selected meaning, and POS when present | Original-sentence prompt and editor | `Complete discovery`, then `Save and finish later` |
| Discovered | `Discovered` outcome | Saved term, meaning, production, and truthful review timing | `Done`, then `Capture another` |

Entry has no in-flow Back action. Later authored phases show a quiet top-leading
Back action that returns to the preceding editable phase without discarding the
draft. Saving and reconciliation temporarily disable Back because the frozen
submission must not change. Discovered replaces Back with its two terminal
actions. Phase transitions replace only the active document body, retain the
shell and subject position, and move focus to the first meaningful control.

Initial surface:

```text
Capture

What did you encounter?

[ improbable                                  ]

Vocabulary suggested                        Use Expression
                                             Discover →
Enter meaning manually
```

Rules:

- No meaning, POS, context, source, filters, statistics, or recent list appears
  initially.
- The type line sits directly beneath the language input. Automatic inference
  renders `Vocabulary suggested` plus `Use Expression`, or `Expression
  suggested` plus `Use Vocabulary discovery`. After a manual override, remove
  the word `suggested`, retain the chosen type, and show the direct reverse
  action. Do not add a segmented selector, dropdown, or overflow menu.
- The type status is named semantically and the change action includes both its
  destination and consequence. It is reachable immediately after the language
  input in focus order.
- `Enter meaning manually` keeps the current type, skips only the dictionary
  lookup, and still performs the exact Library check before new-item creation.
- Empty or whitespace-only submission shows one inline live-region error and
  retains focus.
- Enter/submit and the button invoke the same coalesced transition.
- A restored durable draft returns to the furthest phase supported by authored
  persisted fields with a restrained `Draft restored` status. Lookup-only state
  returns to Entry with the term preserved and requires Discover again.
- Optional encounter context and source remain available only behind a later
  `Add encounter details` disclosure. Existing capabilities are preserved but
  do not compete with Discovery.

## 5. Type detection

Detection is a suggestion, not classification authority:

- one trimmed lexical token → likely Vocabulary;
- multiple whitespace-separated tokens → likely Expression;
- punctuation, apostrophes, and hyphens do not independently force Expression;
- the user may switch type before or during the flow;
- changing type invalidates derived lookup and match state while preserving
  authored text for deliberate reconfirmation.

M1 makes one honest language claim: automatic lexical Discovery is English.
Expressions and non-English language remain capturable through manual meaning
and production. M1 does not infer language or add language identity.

## 6. New Vocabulary Discovery flow

```text
ENTRY
  → normalize input
  → run Library match and English lookup in parallel
      ├── existing items found → RE-ENCOUNTER
      └── no match + lookup result → DISCOVER
  → show all POS groups
  → select or manually enter intended meaning
  → optionally add encounter details
  → FIRST PRODUCTION
  → COMPLETE DISCOVERY or SAVE AND FINISH LATER
  → DISCOVERED CONFIRMATION
```

The provider result is application-owned and provider-neutral:

```text
LexicalLookup
└── partOfSpeechGroups[]
    ├── label
    └── senses[]
        ├── definition
        └── example?
```

Raw responses, provider identifiers, unselected meanings, and dictionary bodies
are not persisted.

## 7. Sense overload strategy

M1 never applies a global first-12 cutoff and never claims unsupported frequency
ranking.

- Show every returned POS heading.
- Initially show the first two provider-ordered senses within each POS.
- Show one concise provider example when present.
- `Show N more` expands each POS independently.
- Keep manual meaning visible when dictionary granularity does not fit the
  encounter.
- Selecting a sense copies its definition and POS into editable fields.
- Changing the selected sense after production preserves the sentence but marks
  it unconfirmed. Editing it or selecting `This sentence still fits` is required
  before completion.

Visual treatment:

- POS groups are typographic sections, not cards. Each has one concise label,
  its visible senses, and a left-aligned `Show N more` ghost action when needed.
- Senses are full-width editorial selection rows separated by neutral 1px
  dividers. Rows have at least a 44px interaction target but no permanent outer
  border, shadow, icon badge, or individually rounded container.
- The definition is 16px body text. One provider example, when available, sits
  beneath it in readable muted body text; it never shrinks into low-contrast
  metadata or competes with the definition.
- Hover may add only the semantic accent-subtle surface. Keyboard focus uses the
  visible semantic focus ring. Selection uses accent-subtle fill plus the same
  narrow accent marker already established for selected Library rows; focus and
  selection remain distinguishable and semantic.
- Expansion occurs within its POS group without collapsing other groups or
  moving the current selection. Long results gain whitespace and section
  rhythm, not repeated card chrome.
- Selecting a provider row keeps that row visibly selected and creates one
  stable `Selected meaning` region after all POS groups. The region shows POS
  and the copied definition as ordinary content, followed by a visible `Edit
  meaning` ghost action; it is not another card. Continue to Production becomes
  the primary action only when this selected value is valid.
- `Edit meaning` reveals visibly labeled, prefilled meaning and POS controls
  inside that region and moves focus to the meaning editor. Saving an edit
  returns to the compact summary without changing the selected provider row;
  the authored values, rather than the raw provider text, are what the learner
  reviews and ultimately persists.
- Selecting a different provider row switches immediately only while the current
  meaning still equals its copied definition. If the learner edited it, the
  proposed row exposes an inline `Replace your edited meaning with this sense?`
  confirmation with `Keep editing` and `Replace`; the original row remains
  selected until Replace is activated. Keep editing returns focus to the editor.
  Replace copies the new sense, and any existing production stays visible but
  becomes unconfirmed under the rule above. No modal, transient Undo, or silent
  meaning/sense mismatch is permitted.
- `Enter meaning manually` appears exactly once after the final POS group as a
  persistent ghost action, never once per group. Activating it reveals a
  visibly labeled editor in place and moves focus to that editor. A zero-result
  or failed lookup opens the same editor automatically beneath the recovery
  status rather than requiring another activation.
- Typing a manual meaning clears the visual provider-sense selection and marks
  the manual value as the intended meaning. If the learner later selects a
  provider sense, the authored manual value remains in the active draft and is
  restored if manual meaning is chosen again; switching paths never destroys
  learner-authored text.

This keeps the complete entry available while making intended-sense selection,
not dictionary browsing, the task.

## 8. First Production flow

After Vocabulary sense selection or Expression meaning entry:

```text
improbable                                                adjective
unlikely to happen or be true

Use “improbable” in your own sentence.

[ It seemed improbable that the train would arrive early. ]

Complete discovery
Save and finish later
```

Rules:

- Meaning is always required before save.
- The primary action requires a nonblank learner-authored sentence within the
  established production length bound.
- M1 does not use AI grading, require an exact surface spelling, or claim the
  sentence is correct. It records what the learner produced.
- `Save and finish later` is visible but secondary. It skips production only.
- Completed first production is stored as capture-origin authored content. It
  does not create a scheduled-review attempt and does not increment review or
  production counters.
- Completed first production sets the first retrieval for 24 hours later.
- Deferred production leaves the new item due immediately.

## 9. Re-encounter flow

Matching normalizes case, surrounding whitespace, and repeated internal
whitespace only. It does not stem, lemmatize, translate, or compare semantic
similarity.

All active exact surface-form matches are returned. Multiple learned senses are
valid; surface spelling is never globally unique.

```text
improbable

Already in your knowledge

ADJECTIVE
Captured from The Left Hand of Darkness
Last reviewed 4 days ago

Test myself
Show meaning
Learn another sense
```

Learned senses use the same editorial-row grammar as Discovery without implying
that provider results and owned items are interchangeable. A sole active match
is selected automatically. With multiple matches, no row is preselected; the
learner chooses one cue row before any item-specific action appears. Before
reveal, a row shows POS, available captured context or source, capture date, and
last-review fact—but never the saved meaning or first production. Selection uses
accent-subtle fill, the narrow accent marker, semantic selected state, and
retains those cues. Sparse legacy items use a neutral `Captured <date>` cue;
they never invent or expose a meaning preview merely to differentiate rows.

One shared action group follows the match list instead of repeating controls
inside every row. Before selection it contains only the surface-level tertiary
action `Learn another sense`. After selection it contains:

1. `Test myself` is the primary action.
2. `Show meaning` is the secondary outline action.
3. `Learn another sense` is the tertiary ghost action.

Changing the selected row updates that one action group in place and writes no
evidence. Keyboard focus moves from a selected row forward into the action group
through ordinary traversal; selection itself does not unexpectedly move focus.
`Learn another sense` never requires choosing an unrelated existing item because
its allow-existing intent applies to the surface form, not to one learned sense.

`Show meaning` expands one inline detail region after the shared action group.
It moves focus to a `Meaning` heading and shows the selected saved meaning,
captured context/source, and first production when present. It writes no attempt,
counter, or schedule change. The control becomes `Hide meaning`; hiding returns
focus to that control. Selecting another learned sense collapses the prior
detail, restores the unrevealed action label, and exposes no new evidence.
Choosing `Test myself` before reveal therefore starts a clean retrieval. Choosing
it after reveal remains allowed but accurately follows a learner-requested
reference action rather than pretending the answer was not seen.

When several items match, `Learn another sense` remains available immediately.
After the learner chooses a known sense, the item-specific actions become
available:

- **Test myself** launches the existing full Review flow for that item even when
  it is not currently due. A successful rated Review writes the existing
  retrieval and production attempts and reschedules normally.
- **Show meaning** reveals item detail. It writes no attempt, counter, evidence,
  or schedule change.
- **Learn another sense** explicitly resumes lexical Discovery. Cached
  active-session lookup results may be reused.
- Entering or searching for a known word is not evidence.
- Legacy duplicate items are shown truthfully; M1 does not add a cleanup or merge
  workflow.

If the Library match call fails but lexical lookup succeeds, Discovery may
continue. Final new-item creation remains gated until the Library check succeeds;
the learner’s draft and lookup result remain intact.

## 10. Expression flow

Expression is not Vocabulary with POS controls removed. Its flow is:

```text
phrase
→ What does it mean here?                     required manual meaning
→ Add encounter details                       optional disclosure
→ Use the expression in your own sentence     primary production
→ complete or explicitly finish later
→ save and enter Discovered confirmation
```

M1 performs no English dictionary lookup, POS selection, usage-pattern
generation, or AI inference for expressions. The meaning remains editable and
the same re-encounter rules apply. This keeps Vocabulary and Expression distinct
without creating separate persistence or Review products.

## 11. Save completion

Successful save remains inside Capture and reveals a calm completion state:

```text
Discovered

improbable                                                adjective
unlikely to happen or be true

“It seemed improbable that the train would arrive early.”

First review tomorrow at 14:20

Done                                      Capture another
```

The timing copy renders the persisted `next_review_at` returned by the completed
transaction; the client does not synthesize a fresh 24-hour promise. Use
locale-aware relative calendar language first (`later today`, `tomorrow`, or the
short local date when farther away) followed by the exact local time. Its
semantic label includes the full local date, time, and time zone so precision is
available without making the visual copy bureaucratic. Refresh the relative
label when the app resumes or the local calendar day changes while this state is
open.

Deferred production says `Ready to practice now` instead and exposes the exact
schedule only through the saved item's ordinary detail. The state is
announced as a semantic live region. Motion is a reduced-motion-safe fade and
small reveal; there is no confetti, bounce, reward iconography, or automatic
redirect. `Done` is the primary button and goes to Today. `Capture another` is
the secondary outline action and resets to Entry only after the successful
transaction is reconciled. Below 640px or when text scaling requires it, the
actions stack full-width in that order. Focus enters on the `Discovered` heading
so the learner can read the saved content and timing before reaching either
action; no timer, default focus activation, or automatic navigation rushes the
confirmation.

## 12. Today’s Captures recommendation

The surface is not in M1. Its reinforcing purpose is covered first by the
in-place Discovered confirmation and Today’s existing recent-capture section.
The accepted P2 follow-up is conditional on founder use showing a missing daily
recap.

If later built, a visible `Today's captures · N` affordance opens it. Tap is the
primary accessible interaction. Vertical swipe is not accepted until use proves
it helpful rather than conflicting with scrolling.

## 13. Knowledge-pool recommendation

No knowledge pool, constellation, node graph, or partial-circle mastery scale
ships in M1. Current evidence cannot justify the apparent precision of
`○ → ◔ → ◑ → ●`. M1 shows facts: intended sense, learner sentence, actual Review
history, counts, and next review.

A P3 exploration is preserved, but it is gated on both a validated evidence
model and an observed comprehension problem. It must compare any visual metaphor
against plain factual history before proposing implementation.

## 14. Evidence and scheduling model

Recognition is not retrieval, and retrieval is not production.

| Event | Evidence | Persisted learning evidence | Scheduling effect |
|---|---|---|---|
| Enter/search term | Encounter only | None | None |
| Select intended sense | Comprehension choice | Selected item content | None |
| Show existing meaning | Reveal only | None | None |
| First original sentence | Capture-origin production | Item-authored first production | First retrieval in 24 hours; counters unchanged |
| Save and finish later | Incomplete production | No production | Item due immediately |
| Test myself: reveal | Retrieval attempt in progress | Completed only through existing transaction | Determined by final rating |
| Test myself: rated production | Retrieval + productive evidence | Existing append-only Review attempts | Existing Again/Hard/Good/Easy schedule |
| Future Meaning Match | Recognition only | Future recognition event | No scheduling effect initially |

M1 does not introduce mastery levels, generalized evidence events, a new SRS,
or inferred competence.

## 15. Meaning Match recommendation

Meaning Match does not ship in M1. The future P3 experiment becomes quietly
available after at least eight eligible unique Vocabulary items, not five.
Eligibility requires active items, usable selected meanings, no duplicate
surface/sense in a round, and sufficiently distinct pairings. Match records
recognition evidence only and does not affect scheduling until real use and
retention results justify a policy change.

## 16. Library recommendation

No Library search, filters, or sorting ship in M1. The observed friction is
preserved as the first P2 follow-up rather than mixed into the Discovery test.
That slice starts with server-backed search across content, meaning, context,
source, and POS; All/Vocabulary/Expressions; and newest/oldest. POS and due-state
filters require later founder evidence.

## 17. Knowledge as reward and future Pro boundary

Immediate M1 knowledge reward:

- multiple honest parts of speech;
- complete progressively disclosed senses;
- provider-supported example for each visible sense when available;
- one selected editable meaning;
- one learner-authored original sentence;
- truthful next-review timing.

No content ingestion, Wikipedia exploration, dialogue generation, conceptual
graph, or Pro implementation ships.

The future boundary is:

> Free helps you learn and use it.
>
> Pro helps you follow it further.

Free retains Capture, definitions, POS, senses, essential examples, first
production, Review, Library, and basic recognition practice. Collocations and
register remain free whenever needed for correct use. Future Pro may add breadth
and depth such as sourced readings, concept trails, richer comparisons,
contextual practice, and cross-item connections. Source quality, licensing,
demand, and cost must be validated first.

## 18. What already exists

| Existing capability | M1 use |
|---|---|
| Native adaptive NavigationBar/NavigationRail | Preserve and restyle Capture prominence |
| Stable IndexedStack destinations | Preserve Capture phase and draft state across navigation |
| `CaptureSessionController` and durable file draft | Evolve in place into sealed immutable Discovery states; migrate the same draft seam to v2 |
| Provider-neutral `LexicalProvider` | Extend to POS groups and optional examples |
| Bounded EnglishDictionaryAPI adapter | Reuse request coalescing, attribution, and manual fallback; make its body cap and timeout genuinely end-to-end |
| Flat `learning_items` with nullable POS | Retain one item per learned sense; add capture-origin production and idempotency fields |
| Append-only `review_attempts` and `complete_review` | Reuse unchanged for Test myself; do not mix first production into scheduled attempts |
| RLS and protected scheduling fields | Preserve; add one hardened Discovery transaction |
| `LearningWorkspace` and Today-owned Review flow | Move Review-session ownership to the workspace so Today and Capture launch the same UI/transaction |
| Today overview and real history | Refresh after save; do not add a duplicate M1 daily surface |
| Quiet-luxury tokens, motion, and accessibility rules | Apply to progressive disclosure and completion |

Current style references:

- native navigation and stable screen identity in `learning_workspace.dart`;
- stale-generation protection in the Today and Library loading flows;
- provider and repository isolation from widgets;
- centralized colors, spacing, radii, typography, and motion.

### M1 component and token mapping

M1 composes the established component vocabulary. It adds no exported
Discovery design system, generic `PhaseScaffold`, stepper, notice family, card
family, or alternate Material form theme. Small private widgets may remove
literal repetition inside Capture, but their API stays specific to the repeated
anatomy proven by these phases.

| M1 element | Existing vocabulary | Required treatment |
|---|---|---|
| Mobile/desktop destination | Native `NavigationBar` / `NavigationRail` | Preserve semantics and restoration; apply `accentSubtle` plus `brandAccent` only to Capture selection/prominence |
| Focused document | `SingleChildScrollView`, centered `ConstrainedBox`, `FocusTraversalGroup` | `formMaxWidth`, 16/24px page padding, background surface; no enclosing decorative card |
| Orientation and subject | `ShadTextTheme` page/feature/label/meta roles | One page title, stable term/type subject, quiet top-leading ghost Back action after Entry |
| Language, meaning, production | Existing `ShadInput` / `ShadTextarea` plus compact editing context menu | Visible labels, semantic required state, existing control radius and input/focus tokens |
| Type suggestion/override | Label/meta typography plus `ShadButton.ghost` | Plain current/suggested status plus one direct reversal action; no segmented selector, dropdown, pill styling, or custom package |
| Sense choice | Semantic button/selected wrapper plus existing ink/focus behavior | Divider-separated editorial row specified in section 7; no `ShadCard` per sense |
| POS group and expansion | Label/meta typography plus `ShadButton.ghost` | Heading owns its senses; `Show N more` stays left-aligned and exposes expanded state semantically |
| Encounter-details disclosure | `ShadButton.ghost`, `AnimatedSize`, `AnimatedSwitcher` | Secondary, visible, and in flow; revealed fields reuse existing controls and structural motion |
| Progress and recovery | Adaptive progress indicator, `Semantics(liveRegion: true)`, text action | Inline named status beside the content it affects; no toast-only error, banner card, or spinner overlay |
| Primary/secondary actions | Regular `ShadButton`, then outline or ghost variant | One primary action per phase; defer remains visible as outline, Back/manual alternatives use ghost |
| Completion | Typography, spacing, dividers, semantic live region | Saved content is the visual anchor; no reward surface, badge, oversized icon, shadow, or gradient |
| Phase transition | Existing `AppMotion` with opacity, 4–8px translation, and bounded size | 220ms standard transition, zero nonessential duration when animations are disabled |

All values come from `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, and
`AppMotion`. New raw color, spacing, radius, duration, or text-style literals in
phase widgets are design-review failures unless they first become justified
semantic tokens used beyond one incidental placement.

Anti-patterns to avoid:

- extending the current 585-line Capture form into a thousand-line phase host;
- flattening and globally truncating lexical senses;
- adding widget-level Supabase or HTTP behavior;
- inventing a generic wizard, Result framework, repository hierarchy, graph,
  analytics platform, or dictionary cache.

## 19. System architecture

```text
Presentation
┌───────────────────────────────────────────────────────────────────────┐
│ LearningWorkspace                                                    │
│ ├── native adaptive navigation                                       │
│ └── CaptureScreen (thin phase host)                                   │
│     ├── Entry                                                        │
│     ├── Vocabulary Discovery                                         │
│     ├── Expression Meaning                                           │
│     ├── Re-encounter                                                 │
│     ├── Production                                                   │
│     └── Discovered confirmation                                      │
└───────────────────────────────────────────────────────────────────────┘
                              │ state + commands
                              ▼
Application/domain
┌───────────────────────────────────────────────────────────────────────┐
│ CaptureSessionController (evolved; one sealed immutable state family)│
│ ├── CaptureDraftRepository                                           │
│ ├── LexicalProvider                                                  │
│ ├── LearningItemRepository.findActiveBySurfaceForm                   │
│ ├── LearningItemRepository.completeDiscovery                         │
│ └── DiscoverySubmission + DiscoveryFailure values                    │
└───────────────────────────────────────────────────────────────────────┘
           │ local file          │ HTTP             │ repository
           ▼                     ▼                  ▼
Infrastructure
┌──────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│ File draft       │  │ EnglishDictionaryAPI │  │ Supabase adapters    │
│ atomic/revisioned│  │ bounded/coalesced    │  │ RLS + RPC mapping    │
└──────────────────┘  └──────────────────────┘  └──────────┬───────────┘
                                                          ▼
Database
┌───────────────────────────────────────────────────────────────────────┐
│ learning_items + review_attempts                                     │
│ complete_discovery (new) + complete_review (existing)                │
└───────────────────────────────────────────────────────────────────────┘
```

No UI imports Supabase, reads provider JSON, owns schedule policy, or performs
normalization queries directly.

`LearningWorkspace` owns one `ReviewSessionController` and its launch origin.
Today supplies its due queue; Capture supplies the single matched item selected
for Test myself. Both origins use the same Review UI and `complete_review`
transaction, then return to their origin after completion or pause.

## 20. Discovery state machine

```text
RESTORING
  ├── authored v2 draft → furthest phase supported by durable fields ─┐
  ├── attempted submission → RECONCILING(frozen payload + same UUID)  │
  ├── v1 / lookup-only draft → ENTRY(term + Discover again)           │
  ├── missing draft → ENTRY                                           │
  └── failed read → ENTRY + visible warning                           │
                                                                      ▼
ENTRY ── Discover ──▶ CHECKING(term, generation)
                         ├── matches → RE_ENCOUNTER
                         ├── Vocabulary lookup → VOCABULARY_SENSES
                         ├── Expression → EXPRESSION_MEANING
                         └── partial failure → usable partial state + recovery

VOCABULARY_SENSES ── select/manual ─┐
EXPRESSION_MEANING ── valid meaning ─┼──▶ PRODUCTION(unconfirmed|confirmed)
RE_ENCOUNTER ── Learn another sense ┘            │
RE_ENCOUNTER ── Test myself → existing REVIEW    ├── complete → SAVING
RE_ENCOUNTER ── Show meaning → REVEALED          └── finish later → SAVING

SAVING
  ├── prepare UUID + frozen payload → flush attempted marker → RPC
  ├── success/replay reconciliation → DISCOVERED
  ├── validation → prior phase + field error
  ├── definitive pre-commit rejection → prior phase + new UUID allowed
  ├── payload conflict → reconciliation error; never mutate frozen payload
  └── unknown outcome → RECONCILING with same UUID and identical payload

DISCOVERED ── Done → Today
           └─ Capture another → ENTRY
```

Each public controller command exhaustively switches over the sealed state
family. Invalid transitions are ignored or rejected by the controller. Widgets
cannot construct combinations such as re-encounter plus new-item saving.
Term/type changes increment the request generation, invalidate derived
completion, and preserve authored text. Provider sense lists are session-only;
restoration never pretends that remote lookup output was persisted.

## 21. Data flow with shadow paths

```text
INPUT ──▶ VALIDATE ──▶ NORMALIZE ──▶ PARALLEL READS ──▶ CHOOSE ──▶ PERSIST
  │           │             │              │               │          │
  ├ nil       ├ blank       ├ empty        ├ lookup error  ├ none     ├ timeout
  ├ empty     ├ too long    ├ same surface ├ match error   ├ stale    ├ conflict
  └ edit      └ bad type    └ no stemming  └ stale result  └ changed  └ replay
  │           │             │              │               │          │
  ▼           ▼             ▼              ▼               ▼          ▼
 no call    field error   exact policy   partial state   cannot save  retry/reconcile
```

Happy path:

```text
input → valid normalized surface → indexed match + bounded lookup
→ intended meaning → optional first production → complete_discovery
→ one item → truthful confirmation
```

Nil and empty inputs never start network work. Upstream errors preserve authored
state. Stale completions are generation-checked. The final mutation is one
transaction keyed by a stable client submission UUID.

## 22. Data and mutation design

M1 keeps the flat learning-item model. One spelling may have several items only
when the learner explicitly chooses Learn another sense.

Additive database needs:

- nullable capture-origin first-production text on `learning_items`;
- a client-generated Discovery submission UUID with uniqueness scoped to owner;
- a stored generated `surface_match_key`, derived with the database copy of the
  canonical normalizer;
- a non-unique owner/key index limited to active rows; content itself is not
  unique because one learner may intentionally learn several senses; shape the
  index as `(user_id, surface_match_key, created_at desc, id) where status =
  'active'` so the match query is covered and deterministically ordered;
- `complete_discovery`, an authenticated idempotent transaction;
- a later hardening migration that revokes legacy direct item insertion.

The pure Dart normalizer and PostgreSQL expression must share data-driven parity
fixtures covering case, surrounding/repeated whitespace, apostrophes, hyphens,
punctuation, and Unicode cases admitted by M1. The database-generated key is
authoritative for stored rows; clients do not write it.

Dart validation supplies immediate field feedback; the RPC repeats all
authoritative constraints before mutation. New M1-only database requirements
are keyed to the Discovery submission marker so valid M0 rows remain readable
and are not retroactively rejected or rewritten.

`complete_discovery`:

1. accepts no owner, counter, timestamp, or schedule parameters;
2. requires a non-null authenticated user;
3. validates kind and all field lengths, requires content and meaning, and
   validates optional production;
4. checks submission replay before duplicate-surface handling and returns the
   existing item for an identical replay;
5. rejects submission-ID reuse with different payload;
6. takes a transaction-level advisory lock derived from authenticated owner and
   surface key, then rechecks active matches inside the lock;
7. returns a typed existing-surface result unless `allowExistingSurface` came
   from the explicit Learn another sense action;
8. sets initial `next_review_at` to now or 24 hours according to production
   presence and leaves review/production counters at zero;
9. uses an empty search path and fully qualified relations;
10. grants execution only to authenticated callers.

`next_review_at` is the sole due-state authority. Domain predicates, Supabase
queries, fakes, and tests must remove the current `review_count == 0` shortcut:
a completed first production remains not due for 24 hours even with zero
reviews, while a deferred item is due immediately because its timestamp is now.

The old `CaptureLearningItem` / direct `create` path is replaced for Capture by
one immutable `DiscoverySubmission` and
`LearningItemRepository.completeDiscovery`. The value contains submission ID,
kind, content, meaning/POS/details, optional production, and the explicit
allow-existing intent. The existing repository boundary remains; no parallel
Discovery repository is introduced.

Repository contracts expose provider- and backend-neutral values. Presentation
receives neither raw PostgREST failures nor database rows.

## 23. Error and rescue registry

All new Capture failures use one `DiscoveryFailure` value with a closed
`DiscoveryFailureCode` enum plus privacy-safe metadata. Adapters map concrete
filesystem, HTTP, and PostgREST causes into that value. Capture presentation
owns one exhaustive code-to-copy/action mapping; no generic Result framework or
exception hierarchy is introduced.

| Method/code path | `DiscoveryFailureCode` | Rescued | Rescue action | User sees |
|---|---|---:|---|---|
| Draft read | `DraftReadFailure` | Yes | Start usable Entry; retain corrupt file for diagnostics | `Could not restore this draft` |
| Draft decode | `DraftFormatInvalid` / `DraftVersionUnsupported` | Yes | Ignore unsafe state; start Entry | Restore warning, no crash |
| Draft write/flush | `DraftWriteFailure` | Yes | Keep visible state; block remote save until secured; Retry | `Could not secure this draft locally` |
| Library match | `LibraryCheckUnavailable` | Yes | Continue lexical work; gate creation; Retry | Inline Library-check error |
| Library match auth | `SessionUnavailable` | Yes | Stop mutation; preserve draft; use existing session recovery | Session unavailable message |
| Lexical lookup | `LexicalEntryNotFound` | Yes | Manual meaning; optional Retry after edit | `No English entry found` |
| Lexical lookup | `LexicalRateLimited` | Yes | Retry later or manual meaning | Rate-limit-specific recovery |
| Lexical lookup | `LexicalTimedOut` | Yes | Retry or manual meaning | Timeout-specific recovery |
| Lexical lookup | `LexicalServiceUnavailable` | Yes | Manual meaning; Retry | Provider unavailable |
| Lexical decode | `LexicalPayloadInvalid` | Yes | Reject result; manual meaning; diagnostic metadata | Unreadable-entry recovery |
| Lexical stream | `LexicalResponseTooLarge` | Yes | Abort stream; manual meaning | Response unavailable |
| Discovery RPC | `DiscoveryValidationRejected` | Yes | Return to named field; preserve draft | Specific validation copy |
| Discovery RPC | `DiscoverySubmissionConflict` | Yes | Stop blind retries; reconcile or generate a new action | Safe conflict message |
| Discovery RPC | `DiscoveryServiceUnavailable` | Yes | Retry same submission UUID | `Could not confirm this discovery` |
| Discovery RPC response loss | `DiscoveryOutcomeUnknown` | Yes | Retry same UUID; server returns committed item | Recovering, then Discovered |
| Test myself item changed/deleted | `ReviewItemUnavailable` | Yes | Refresh match results; preserve Capture draft | Item no longer available |
| Existing Review mutation | Existing typed repository failure | Yes | Preserve response and submission ID; retry/reload | Existing Review recovery |

Existing Review failures retain their current repository type. Widgets never
catch `Object` or display raw exception strings.

## 24. Error flow

```text
External failure
   │
   ▼
Infrastructure adapter identifies concrete cause
   │
   ▼
DiscoveryFailure(code, metadata)
   ├── permanent input/data issue → correct or enter manually
   ├── transient read issue → preserve work + retry
   ├── ambiguous committed write → retry same submission ID
   ├── conflict → reconcile; never blind retry with changed payload
   └── auth issue → preserve work + existing session recovery
   │
   ▼
Stable user copy + privacy-safe structured diagnostic
```

No failure is swallowed. Every failure preserves as much authored work as is
safe, gives a visible outcome, and has one named recovery.

## 25. Failure modes registry

| Code path | Failure mode | Rescued | Test | User sees | Logged |
|---|---|---:|---:|---|---:|
| Entry | Nil/blank/oversized input | Yes | Unit + widget | Inline field error | Metadata |
| Type detection | Incorrect suggestion | Yes | Unit + widget | Visible manual override | No |
| Parallel reads | Double submit | Yes | Unit | One active generation | Metadata |
| Parallel reads | User changes term mid-flight | Yes | Unit + widget | New term state only | Metadata |
| Library check | Provider succeeds, Library fails | Yes | Unit + widget | Discovery continues; save gated | Metadata |
| Provider | Library succeeds, provider fails | Yes | Unit + widget | Manual meaning + Retry | Metadata |
| Provider stream | Single/cumulative body exceeds 1 MiB | Yes | Unit | Abort before retaining excess bytes | Metadata |
| Provider stream | Headers arrive but body stalls | Yes | Unit | End-to-end timeout aborts request | Metadata |
| Sense list | 10–20 senses | Yes | Unit + widget | Two per POS + expansion | No |
| Sense choice | Later POS hidden | Yes | Widget | Every POS heading visible | No |
| Production | Sense changes after sentence | Yes | Unit + widget | Sentence preserved, unconfirmed | Metadata |
| Draft | Process exits before prepared write | Yes | Repository + unit | No RPC; authored state remains | Metadata on failure |
| Draft | Process exits after attempted write | Yes | Repository + integration | Frozen same-ID reconciliation | Metadata |
| Save | Repeated activation | Yes | Unit + integration | One in-flight mutation | Metadata |
| Save | Server commits, response lost | Yes | pgTAP + integration | Retry reconciles one item | Metadata |
| Save | Submission UUID reused with changed payload | Yes | pgTAP + integration | Conflict, no second row | Metadata |
| Save | Two clients create same surface concurrently | Yes | pgTAP + two-client integration | One item + one typed existing result | Metadata |
| Save | Explicit concurrent another-sense intent | Yes | pgTAP + integration | Additional sense allowed after lock | Metadata |
| Scheduling | Production completed | Yes | Unit + pgTAP | First review in 24 hours | No |
| Scheduling | Production deferred | Yes | Unit + pgTAP | Ready to practice now | No |
| Re-encounter | Multiple learned senses | Yes | Repository + widget | All matching senses shown | No |
| Re-encounter | Item disappears before Test myself | Yes | Unit + widget | Refresh/recovery message | Metadata |
| Targeted Review | Complete or pause from Capture | Yes | Widget + integration | Return to Capture; draft preserved | No |
| Security | Caller supplies another owner/protected state | Yes | pgTAP negative | Mutation rejected | Server metadata |
| Rollout | M0 client after grant revocation | Yes by rollout | Smoke + runbook | Avoided by staged cutover | Deploy record |

Critical gaps after planned work: **0**.

## 26. Security model

| Threat | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Cross-user creation/read | Medium | High | Auth-derived owner, RLS, negative two-user tests |
| Protected schedule/counter injection | Medium | Medium | No parameters/grants for protected fields |
| Privileged-function object hijack | Low | High | Empty search path and fully qualified relations |
| Submission replay with changed content | Low | Medium | Owner-scoped uniqueness plus payload mismatch conflict |
| Oversized/blank/untrusted Unicode input | Medium | Medium | Pure Dart field validation plus authoritative SQL/RPC validation and parity fixtures |
| Concurrent same-surface creation | Medium | Medium | Owner/key transaction advisory lock, replay-first ordering, match recheck |
| Legacy direct-insert bypass | Medium during rollout | Medium | Two-phase cutover, then revoke direct insert |
| Personal content in diagnostics | Medium | High | Metadata-only logs; never raw learner/provider content |

Flutter renders text rather than HTML, SQL calls remain parameterized, provider
paths use URI construction, and no new secret is required. The dictionary term
is sent only after the explicit Discover action. M1 adds no file import,
background job, command execution, storage bucket, or AI prompt surface.

## 27. Performance and capacity

- Start the indexed Library match and lexical lookup in parallel after local
  validation.
- Show stable progress within one animation frame; never block the UI thread.
- Coalesce identical in-flight lexical requests.
- Reuse a successful result only within the active Discovery draft.
- Enforce the 1 MiB cap before retaining each response chunk. Track cumulative
  bytes and buffer with `BytesBuilder(copy: false)` before decoding.
- Apply one 10-second deadline across request send and body consumption. Use
  `AbortableRequest` so timeout aborts the underlying request; map both pre-header
  and mid-stream abortion to the same typed timeout failure.
- Add no persistent lexical cache and no shared dictionary table.
- Use one indexed owner/surface match query; no per-result follow-up queries.
  Verify its query plan against a realistic local fixture (at least 10,000 rows)
  and fail the performance check if it falls back to an avoidable full scan.
- Keep complete Discovery as one database round trip.
- Ignore stale generations rather than allowing late results to repaint state.

Founder-scale M1 is not expected to pressure Supabase. The external provider’s
per-IP rate limit is the first 100× scaling constraint; a public multi-user
provider strategy is explicitly future work.

## 28. Observability and privacy

Structured diagnostics include only:

- operation and phase;
- typed failure code and broad HTTP status category;
- duration, retry count, and request generation;
- opaque item and submission identifiers;
- whether idempotent reconciliation succeeded.

Diagnostics never include word/expression text, meanings, learner sentences,
context, source URLs, dictionary response bodies, auth tokens, or configuration
values. No hosted analytics or error vendor is added.

The implementation updates a short troubleshooting runbook covering:

1. dictionary outage/rate limit and manual fallback;
2. Library-check failure and gated creation;
3. local/hosted migration mismatch;
4. unknown mutation outcome and replay reconciliation;
5. submission conflict;
6. legacy-grant cutover and rollback.

## 29. Test plan

```text
CODE PATHS (58/58 specified)                         USER FLOWS
[+] Controller: 28 paths                            [+] Discovery: 7 paths [→E2E]
  ├── every state + public command                    ├── Vocabulary + production
  ├── legal and invalid transitions                   ├── Expression + defer
  ├── stale generations / partial reads               ├── Re-encounter three actions
  ├── upstream invalidation / reconfirmation           └── restart + reconciliation
  └── draft side effects / reconciliation            [+] Targeted Review: 5 paths
[+] Adapters + database: 18 paths                     ├── complete / pause return
  ├── provider status/decode/size/deadline             ├── stale/deleted match recovery
  ├── normalizer parity / indexed match                ├── Show meaning writes nothing
  ├── replay / conflict / validation                   └── Today origin unchanged
  └── concurrency / ownership / scheduling

QUALITY TARGET: ★★★ behavior + edge + error for every path
GAPS AFTER THIS PLAN: 0  |  E2E: deterministic full-app spine  |  EVAL: none
```

Required test suites:

1. **Canonical state/event unit matrix:** every public controller command in
   every relevant state, including valid/invalid transitions, stale generations,
   partial reads, upstream invalidation/reconfirmation, persistence side effects,
   and pending reconciliation.
2. **Draft v1→v2 and crash matrix:** missing/corrupt/unsupported drafts, prepared
   UUID, attempted marker flushed before RPC, local write failure preventing RPC,
   restart with frozen payload, identical replay, definitive rejection rotating
   the UUID, success cleanup, and cleanup failure that never invites a duplicate.
3. **Provider/adapter matrix:** multi-POS examples, 404/429/non-2xx, malformed or
   empty bodies, one oversized chunk, cumulative overflow, stalled header/body,
   request abortion, coalescing, and stale completion.
4. **Database and real two-client suite:** validation/RLS/grants, Dart/SQL
   normalization parity, query plan at 10,000 rows, simultaneous distinct first
   submissions yielding one item plus one typed existing result, explicit another
   sense, replay-before-duplicate ordering, other-owner isolation, and rollback
   releasing the advisory lock.
5. **Targeted Review interaction suite:** launch a non-due matched item, complete
   or pause back to Capture with its draft intact, recover from stale/deleted
   items, prove Show meaning writes no attempt, resume Learn another sense, and
   keep the Today-origin due flow unchanged.
6. **Deterministic full-app spine `[→E2E]`:** add the Flutter SDK
   `integration_test` dependency and run new Vocabulary → intended sense → first
   production → atomic save → not immediately due → re-enter → targeted Review
   on Linux and Android against disposable local Supabase with an injected
   deterministic lexical provider. Test the real external adapter separately.

**Critical regression coverage:** replace the existing assumption that every
zero-review item is due. At the domain, fake, repository, and database/integration
layers, assert that a future `next_review_at` is not due and an immediate/past
timestamp is due regardless of `review_count`.

Required completion commands:

```bash
dart format .
flutter analyze
flutter test
supabase test db
flutter test integration_test/discovery_flow_test.dart -d linux
# Run the same integration journey on the configured Android device/emulator.
flutter build linux
flutter build apk --debug
```

The database suite runs only against the disposable local Supabase stack.
Hosted smoke testing happens only after separately approved deployment.

## 30. Deployment sequence

```text
Local additive migration
  → reset + pgTAP + repository integration
  → reviewed hosted Migration 1 (separate approval)
      first-production fields + replay key + match index + RPC
      legacy direct insert temporarily retained
  → deploy Linux and Android M1 clients
  → smoke: new production / deferred production / replay / re-encounter
  → reviewed hosted Migration 2 (separate approval)
      revoke legacy direct insert
  → repeat smoke checks and monitor structured failures
```

Migrations are forward-only. Frankfurt remains the linked hosted target but is
not modified by this specification. Tokyo remains untouched.

## 31. Rollback flow

```text
Problem found
   │
   ├── before legacy grant revocation
   │      └── revert client → M0 direct insert still works
   │
   ├── after revocation, database behavior is sound
   │      └── keep M1 client; ship forward client fix
   │
   └── after revocation, client must revert
          └── reviewed forward migration restores narrow legacy insert grant
                 → revert client

Additive columns, indexes, and RPC remain in place during rollback.
No destructive down migration or historical-data rewrite is required.
```

## 32. Quiet-luxury and accessibility requirements

- Preserve warm near-black/ivory surfaces, restrained champagne accent, Geist,
  centralized tokens, deterministic radii, and editorial hierarchy.
- Use content and whitespace as the primary hierarchy; no giant cards, pills,
  gradients, shadows, or ornamental icons.
- Motion uses existing 120/160/220/300ms tokens and honors disabled animations.
- Every phase announces its heading; asynchronous errors and completion use
  appropriate live regions.
- Focus moves to the first meaningful control after a phase transition and
  never disappears during animated replacement.
- All actions remain reachable by keyboard, mouse, and touch. Touch targets are
  at least 44px.
- Sense expansion exposes semantic expanded/collapsed state.
- Content reflows at supported text scales with no horizontal scroll.
- Native Back preserves the durable draft; destructive restart/discard remains
  explicit and confirmed.

### Adaptive behavior and input access

Capture keeps the same information order at every width; adaptation changes
spacing and action arrangement, not task sequence or available capability.

| Constraint | Presentation |
|---|---|
| `< 640px` | 16px horizontal padding; one column; action group stacks primary then secondary at full available width; type choices and learned-sense actions wrap without horizontal scrolling |
| `640–759px` | 24px horizontal padding within the centered 720px document; actions may share a row only when both labels fit at the current text scale |
| `760–959px` | Native shell changes to its rail while Capture keeps the same centered document and phase state |
| `>= 960px` | Additional outer space remains quiet margin; Capture does not become a split workspace and the 720px reading measure remains authoritative |
| Constrained height / Android IME | Body remains one scroll view; bottom padding includes the keyboard inset plus regular spacing; focused editor and its adjacent error are revealed first, then the action group can be reached with one continued scroll; no action footer overlays content |
| Text scaling through 200% | Layout decisions use actual constraints rather than device class; labels wrap, action rows stack, POS/example text reflows, and no content or control requires horizontal scrolling |

Focus and semantics:

- Focus order follows the visual document from orientation through subject,
  active task, disclosure, status/recovery, primary action, and secondary action.
- A phase transition places focus on its heading for orientation when there is no
  immediate editable field; Entry, Expression Meaning, and Production instead
  focus their first editor. The screen reader announces one phase change, not
  every animation frame or progress update.
- Entry's single-line editor submits through Enter and the visible Discover
  button. Multiline meaning and production editors keep Enter for line breaks;
  all completion remains reachable by ordinary Tab/Shift+Tab and activation,
  with no hidden shortcut required.
- Sense rows expose button and selected state; Space/Enter activates them.
  `Show N more` exposes expanded/collapsed state and retains logical focus on
  activation. Type status names the current choice and whether it was suggested;
  the adjacent change action names the alternate type.
- Errors are announced once when they appear, remain visible beside the affected
  control, and do not steal focus repeatedly during rebuilds. Progress labels
  announce meaningful state changes only.
- When the IME or text scaling changes constraints, `Scrollable.ensureVisible`
  or equivalent bounded scroll behavior reveals the focused control and inline
  error. Motion uses `AppMotion` and becomes immediate when animations are
  disabled.

### Capture interaction-state presentation

Loading and recovery replace only the affected portion of the focused document.
The subject header and authored content stay stable; Capture never blanks into a
full-screen spinner after startup. Independent Library and dictionary work is
shown independently so one slow or failed service does not hide usable results.

| Feature | Loading | Empty | Error | Success | Partial |
|---|---|---|---|---|---|
| Draft restoration | Workspace startup keeps the native shell stable and shows one restrained adaptive progress indicator | Clean Entry with focused language input | Entry remains usable with `Could not restore this draft` as an inline live region | Resume the furthest authored phase with `Draft restored` beneath orientation | Lookup-only state restores the term at Entry and says Discover is required again |
| Entry parallel reads | Keep term/type orientation visible; show separate `Checking your Library` and `Finding English meanings` rows in the future content positions | No exact match continues to the correct Vocabulary or Expression task | Each failed row keeps an adjacent Retry; Library failure gates creation, while lookup failure exposes manual meaning | Exact matches open Re-encounter; otherwise grouped senses or manual Expression meaning replaces progress in place | A completed result becomes usable immediately while the unresolved row remains visibly pending |
| Vocabulary senses | Preserve already returned POS groups while a retried lookup is pending | `No English entry found` followed by the visible manual-meaning editor | Provider-specific stable copy, Retry, and manual meaning remain together | All POS headings, two senses per group, selection, examples, and per-group expansion | If Library is unresolved, selection and authored work continue but final creation remains gated |
| Expression meaning | No remote lookup; draft-write activity does not replace the editor | Blank editor with visible required label and concise prompt | Field error stays below the editor and receives focus on submission | Valid authored meaning reveals the Production action | Library-pending or failed status remains visible without disabling meaning entry |
| Re-encounter | Keep subject and any returned learned-sense rows while refreshing a stale match | Explain that the item is no longer available, then return to Discovery with the draft intact | Inline retry or session-recovery action adjacent to the failed sense | One or more learned-sense rows plus one shared selected-sense action group | A late exact match interrupts new-item completion with `Already in your knowledge`; authored meaning and production stay in the draft and resume if `Learn another sense` is chosen |
| Production | No remote loading; local draft security status stays adjacent without covering the editor | Empty required editor on the primary path; defer remains visible and secondary | Validation or draft-write failure preserves the sentence, focuses the affected control, and offers Retry | Confirmed original sentence enables `Complete discovery` | A changed meaning preserves the sentence but marks it unconfirmed until edited or explicitly reconfirmed |
| Save and reconciliation | Freeze controls and payload; primary action says `Saving` or `Confirming discovery` with restrained progress | — | Definitive validation returns to the named field; unknown outcome keeps same-ID Retry; payload conflict stops blind retry | Transition once to Discovered after new save or identical replay reconciliation | Library-check gating explains why save is unavailable and places Retry beside that status |
| Discovered | — | — | Cleanup failure never implies save failure or offers duplicate submission | Announced confirmation with saved content, truthful review timing, `Done`, and `Capture another` | Deferred production substitutes `Ready to practice now` and omits an empty quotation block |

When dictionary data appears before the Library result, the learner may select a
sense, enter a manual meaning, add details, and draft production. `Complete
discovery` remains unavailable with the adjacent reason `Check your Library
before saving`. If a late Library result finds an exact match, Capture moves to
Re-encounter before any new-item mutation, explains the match, and preserves all
authored fields. Choosing `Learn another sense` restores those fields and records
the explicit allow-existing intent; the learner never has to retype them.

### Journey storyboard and voice

Discovery uses quiet confidence: curiosity becomes clarity, clarity becomes
personal ownership, and completion feels grounded rather than celebratory. Copy
is concise and factual, never clinical, cute, congratulatory, or corrective.

| Step | Learner does | Intended feeling | Design support |
|---|---|---|---|
| 1. Enter | Brings in language encountered elsewhere | Curious; safe to begin without completing a form | One question, one input, visible type suggestion, durable draft |
| 2. Wait | Lets Whole Knowledge check existing knowledge and English meanings | Oriented; confident that work is happening honestly | Stable document with two named inline progress states and usable partial results |
| 3. Understand | Chooses the intended Vocabulary sense or explains an Expression | Clear rather than tested | Provider order is transparent, every POS remains available, manual meaning is always legitimate |
| 4. Re-encounter | Recognizes that this surface already belongs to one or more learned senses | Recognized, not blocked or scolded | `Already in your knowledge`, truthful sense rows, and three purposeful next actions |
| 5. Produce | Writes an original sentence or deliberately defers | Capable; ownership of the language is beginning | Selected meaning remains visible, prompt is direct, defer is available without becoming dominant |
| 6. Recover | Meets a validation, provider, Library, draft, or save failure | Protected rather than punished | Authored work stays visible; copy names what could not finish and places one recovery action beside it |
| 7. Complete | Sees the saved item and its real review timing | Quietly satisfied; ready to continue or leave | `Discovered`, learner-authored content, truthful timing, no praise theater, `Done` and `Capture another` |
| 8. Return | Encounters the item later through Today or targeted Review | Continuity; the earlier effort mattered | The same language, meaning, production, and factual schedule reappear in the existing learning loop |

Time-horizon design:

- **First 5 seconds:** the learner sees one obvious question, knows Capture is
  the active destination, and can begin without reading instructions.
- **First 5 minutes:** lookup, selection, production, recovery, and completion
  feel like one continuous learning event; no phase resembles account setup or
  data administration.
- **Five-year relationship:** repeated use remains calm because the product does
  not praise routine actions, manufacture urgency, or turn accumulated language
  into a reward economy. Trust comes from preserved work and truthful evidence.

Voice rules:

- Prefer concrete orientation and action: `Finding English meanings`, `Choose
  the meaning you encountered`, `Use it in your own sentence`, `Discovered`.
- Never use `Great job`, `Amazing`, `You mastered`, streak language, exclamation
  marks, or corrective language for choosing manual meaning or deferring.
- Recovery copy describes the system limitation, not learner failure, and names
  the next safe action in the same visual group.
- Keep prompts to one sentence. Explanations appear only when a state would
  otherwise be ambiguous, and they disappear when the ambiguity is resolved.

## 33. Explicitly NOT in M1

- Today’s Captures surface or vertical swipe navigation;
- Library search, filters, or sorting;
- Meaning Match or any other new practice mode;
- knowledge pool, constellation, graph, nodes, or mastery visualization;
- generalized evidence-event architecture or new SRS;
- multilingual detection, language metadata, or additional providers;
- AI coach, LLM definitions, AI sense ranking, or AI sentence grading;
- pronunciation training, speech recognition, CEFR estimation, social features,
  leaderboards, XP, currency, achievements, or streak mechanics;
- deep content exploration, readings, Wikipedia ingestion, or knowledge graph;
- monetization, subscriptions, entitlements, or paywalls;
- custom dictionary database or persistent lexical cache;
- auth UI, offline sync engine, realtime sync, or new state/navigation framework;
- generic Result/error framework, generic wizard/base phase hierarchy, new
  repository family, or persisted provider-sense cache;
- external recruitment or a new research process.

## 34. Dream-state delta

```text
CURRENT M0
durable but form-like capture
manual/optional lookup
immediate Review queue
        │
        ▼
M1 DISCOVERY CORE
one-input entry
intended-sense discovery
first authored use
truthful re-encounter
        │
        ▼
12-MONTH IDEAL
multilingual encounter capture from many contexts
provider-aware lexical and expression understanding
evidence-proven retrieval/production growth
sourced exploration that connects language to knowledge
```

M1 moves directly toward the ideal interaction and data truth while deliberately
not building the future visualization, practice, content, or monetization layers.

## 35. Founder-use success criteria

Evaluate after at least 20 genuine founder captures across at least two weeks,
using both Linux and Android. This is personal-use validation, not formal user
recruitment.

M1 succeeds when:

1. Capture is repeatedly chosen at the moment of encounter rather than postponed
   because the flow feels administrative.
2. At least 80% of provider-supported Vocabulary captures reach an intended
   sense without manual dictionary work.
3. At least 70% of completed discoveries include the optional-to-defer first
   production, indicating that the primary path is valuable rather than merely
   tolerated.
4. Re-entering known surface forms creates zero unintended duplicates in the
   observed sample.
5. Polysemous words expose the intended POS/sense without requiring a global
   unstructured expansion.
6. A completed first production never appears immediately due; a deferred one
   is immediately available in Today.
7. Drafts, retry, process restart, back navigation, and lost-response recovery
   lose no authored text and create no duplicate item.
8. The full flow is keyboard-complete on Linux and touch/IME-complete on Android.
9. Founder notes describe the end state as discovering/learning something, not
   completing a form.

These thresholds are falsifiable signals, not growth metrics or release theater.

## 36. Decisions to validate after M1 ships

- Is 24 hours the right first-retrieval delay after initial production?
- Is `Save and finish later` discoverable without becoming the dominant path?
- Do two initially visible senses per POS balance speed and completeness?
- Does the single-token/multi-token suggestion need more rules?
- Is manual Expression meaning still too form-like?
- Does re-encounter make learners choose Test myself, Show meaning, or Learn
  another sense at the expected moments?
- Does the in-place Discovered state earn its pause, or do users want immediate
  navigation?
- Does the center navigation treatment remain quiet at daily-use frequency?
- Are the existing Today recent captures sufficient, or does the P2 daily
  Capture surface earn implementation?
- Does Library friction become the next highest founder pain after Capture?
- Do real selected meanings produce eight eligible items for Meaning Match
  without manual curation?
- Does a second target language create enough demand to promote multilingual
  identity from P3?

## 37. Major risks

| Risk | Consequence | Mitigation / validation |
|---|---|---|
| Provider ordering surfaces obscure senses first | Discovery still feels like dictionary work | POS signposting, progressive disclosure, manual meaning, founder sample |
| First production feels mandatory despite escape | Capture is postponed | Visible secondary defer path; track voluntary completion through founder notes |
| Defer becomes default | Learning event weakens | Copy/hierarchy favors production; validate 70% target |
| 24-hour delay is poorly calibrated | Review is too early or late | Isolated policy and post-ship validation |
| Expression path remains manual | Vocabulary feels premium while expressions feel administrative | Separate prompt and minimal fields; observe real expression captures |
| State-machine rewrite regresses durable drafts | Authored language is lost | Transition table, file tests, restart journey, checkpointed implementation |
| RPC/grant rollout breaks an old client | Capture unavailable | Two-phase cutover and forward grant-restoration runbook |
| Surface normalization conflates languages | False re-encounter | English-first claim, explicit Learn another sense, promote multilingual slice on demand |
| Discovery scope attracts practice/exploration work | M1 loses causal clarity | Enforce NOT in M1 and `TODOS.md` boundaries |

## 38. Stale diagram audit

- `docs/architecture.md` dependency, Supabase, and Review diagrams remain
  accurate for M0. Implementation must extend them with `complete_discovery`,
  first-production scheduling, and the new match query; it must not overwrite
  the existing Review transaction diagram.
- `DESIGN.md` correctly defines the visual system and native adaptive shell. Its
  current Capture section describes a calm linear form and will become stale
  when M1 lands; implementation must replace that section with the phased
  Discovery hierarchy and completion state.
- `docs/plans/founder-use-friction-pass.md` is a historical M0 plan. Its diagrams
  remain accurate for that shipped slice and should not be rewritten as if they
  described M1.
- No source-code ASCII diagram becomes stale from this specification because no
  application code has changed.

Implementation should place short inline ASCII comments only where the invariant
is otherwise difficult to reconstruct:

- beside the Capture state family/controller: authored state → derived lookup →
  prepared/attempted mutation → reconciliation;
- inside the `complete_discovery` migration: replay check → owner/key lock →
  active-match recheck → validate → insert/return.

The phase widgets and workspace routing are readable from types and should not
duplicate the plan diagrams in source comments.

## 39. Implementation tasks

Synthesized from this review. No task authorizes hosted deployment without the
separate approvals named above.

Dependency and worktree strategy:

| Step | Modules touched | Depends on |
|---|---|---|
| T1 Contracts | `lib/application/capture/`, `lib/domain/learning/` | — |
| T2 Database | `supabase/migrations/`, `supabase/tests/` | T1 contract settled |
| T3 Repository | `lib/application/learning/`, `lib/infrastructure/supabase/`, `test/support/` | T1, T2 |
| T4 Provider | `lib/application/capture/`, `lib/infrastructure/dictionary/` | T1 |
| T5 State/draft | `lib/application/capture/`, draft infrastructure, focused tests | T1, T3, T4 |
| T6 Review host | `lib/presentation/learning/`, `lib/application/review/` | T1, T5 |
| T7 Presentation | `lib/presentation/learning/capture/`, widget tests | T5, T6 |
| T8 Verification | all test layers, `integration_test/` | T2–T7 |
| T9 Docs/rollout | documentation, forward migration | T8 |

```text
T1 contracts
 ├──▶ T2 database ──▶ T3 repository ──┐
 └──▶ T4 provider ────────────────────┼──▶ T5 state/draft ──▶ T6 Review host
                                      │                         │
                                      └─────────────────────────┴──▶ T7 UI
                                                                    │
                                                                    ▼
                                                               T8 verification
                                                                    │
                                                                    ▼
                                                               T9 docs/rollout
```

After T1 lands, T2–T3 may use one database/repository worktree while T4 uses one
provider worktree. T5–T7 intentionally return to a single integration lane
because they share Capture state, workspace ownership, and widget fixtures; the
merge-conflict cost outweighs parallelism. T8 and T9 follow the integrated tree.

- Lane A: T2 → T3 (sequential; shared database/repository contract).
- Lane B: T4 (independent provider adapter after T1).
- Integration lane: merge A + B, then T5 → T6 → T7 → T8 → T9.
- Conflict flag: T1 and T4 both touch `lib/application/capture/`; land T1 before
  creating the provider worktree. No other lanes should edit that module in
  parallel.

- [ ] **T1 (P1, human: ~1.5 days / Codex: ~2.5h)** — Contracts — Define the smallest provider-neutral Discovery contract.
  - Surfaced by: Architecture D2/D7 and Code quality D10/D11/D13.
  - Files: Capture application values, lexical values, `LearningItem` due predicate, focused tests.
  - Includes: immutable `DiscoverySubmission`, `DiscoveryFailure` + closed code enum, pure field validator, canonical Dart surface normalizer, grouped POS/senses/examples.
  - Verify: exhaustive failure mapping, validation boundaries, normalization fixtures, future-zero-review item is not due.
- [ ] **T2 (P1, human: ~2.5 days / Codex: ~4h)** — Database — Add replay-safe schema, indexed matching, scheduling truth, and `complete_discovery`.
  - Surfaced by: Architecture D2/D5/D8 and Test D16.
  - Files: forward migrations and `supabase/tests/database/learning_loop_test.sql`.
  - Includes: first production, owner-scoped submission key, generated surface key, active partial index, replay-first RPC, advisory lock, explicit another-sense intent, grants/RLS.
  - Verify: pgTAP validation/ownership/replay/conflict/scheduling/concurrency, normalizer parity, 10,000-row query plan, rollback releases lock.
- [ ] **T3 (P1, human: ~2 days / Codex: ~3h)** — Repository — Replace Capture direct insert with exact-match and atomic Discovery operations.
  - Surfaced by: Architecture D5/D8 and Code quality D10/D13.
  - Files: learning repository contract, Supabase adapter, row mappers, fakes, repository/integration tests.
  - Includes: `findActiveBySurfaceForm`, `completeDiscovery`, typed existing/replay/failure mapping, sole timestamp due query.
  - Verify: every matching sense, owner isolation, no stemming, identical retry, no `review_count == 0` due shortcut.
- [ ] **T4 (P1, human: ~1.5 days / Codex: ~2.5h)** — Provider — Harden and enrich the existing EnglishDictionaryAPI adapter.
  - Surfaced by: Performance D21/D22 and the existing global sense-cap path.
  - Files: lexical provider contract/adapter and fixtures.
  - Includes: grouped POS output, no global 12-sense truncation, pre-allocation 1 MiB cap, `BytesBuilder`, end-to-end aborting deadline, existing coalescing/attribution.
  - Verify: multi-POS 20-sense payload, one-chunk and cumulative overflow, stalled header/body, 404/429/non-2xx/malformed/empty response.
- [ ] **T5 (P1, human: ~3 days / Codex: ~5h)** — State and drafts — Evolve `CaptureSessionController` into the sealed Discovery state family and migrate draft v1→v2.
  - Surfaced by: Architecture D3/D4/D7 and Test D17/D18.
  - Files: Capture draft/repository/controller/state and focused tests.
  - Includes: generation guards, partial read states, authored-data restoration, prepared/attempted submission checkpoints, frozen reconciliation payload, upstream invalidation/reconfirmation.
  - Verify: canonical 28-path state/event matrix and complete crash/restart matrix.
- [ ] **T6 (P1, human: ~1.5 days / Codex: ~2.5h)** — Review host — Give `LearningWorkspace` shared Review-session ownership and launch origin.
  - Surfaced by: Architecture D6 and Test D19.
  - Files: workspace, Today/Capture coordination, Review interaction tests.
  - Includes: due queue from Today, targeted one-item queue from Capture, return-to-origin behavior, stale/deleted-item recovery.
  - Verify: complete/pause preserves Capture draft, Show meaning writes nothing, Today flow remains unchanged.
- [ ] **T7 (P1, human: ~3 days / Codex: ~6h)** — Presentation — Split Capture into focused phase widgets without a new UI framework.
  - Surfaced by: Code quality D10/D12 and the CEO-approved phase flow.
  - Files: thin `capture_screen.dart` plus `presentation/learning/capture/` Entry, Senses/Meaning, Re-encounter, Production, Discovered, and shared widgets.
  - Includes: exhaustive state rendering and failure copy/actions, adaptive layout, semantics, focus, keyboard/touch/IME, reduced motion.
  - Verify: every phase and partial/error state, independent POS expansion, 20-sense flow, narrow/wide/text-scale coverage.
- [ ] **T8 (P1, human: ~2.5 days / Codex: ~5h)** — Verification — Add the full layered suite and run both first-class targets.
  - Surfaced by: Test D15–D19 and the mandatory due-state regression.
  - Files: unit/widget/adapter/database/two-client suites plus `integration_test/discovery_flow_test.dart` and SDK dev dependency.
  - Verify: all commands in section 29, deterministic Linux and Android Discovery spine, critical due-state regression.
- [ ] **T9 (P1, human: ~1 day / Codex: ~2h)** — Reliability/docs/rollout — Add privacy-safe diagnostics and update durable documentation; deploy only under separate approval.
  - Surfaced by: Error/rescue, observability, deployment, and stale-diagram reviews.
  - Files: failure boundaries, troubleshooting runbook, `DESIGN.md`, `docs/architecture.md`, `README.md`, later grant-hardening migration.
  - Verify: every registry row has stable recovery/copy/test, diagrams are current, and both approved live smoke journeys pass before direct insert is revoked.

## 40. Deferred work

Accepted follow-ups are recorded in `TODOS.md`:

1. P2 Library search and organization.
2. P2 conditional Today’s Captures surface.
3. P3 Meaning Match recognition experiment.
4. P3 knowledge-pool visual exploration, evidence-gated.
5. P3 multilingual identity and provider routing.
6. P3 deeper knowledge exploration and future Pro boundary.

The engineering review found no additional deferred-work candidate worth adding
to `TODOS.md`; the six CEO-approved follow-ups remain unchanged. No unresolved
product or architecture decisions remain in this specification.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|---|---|---|---:|---|---|
| CEO Review | `/plan-ceo-review` | Scope and strategy | 1 | CLEAR | Scope-reduced M1 approved; 0 critical gaps |
| Codex Review | `/codex review` | Independent diff opinion | 0 | — | Not run |
| Eng Review | `/plan-eng-review` | Architecture and tests (required) | 3 | CLEAR (PLAN) | 18 issues resolved; 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 2 | CLEAR (FULL, pre-M1) | Latest pass scored 10/10 for the M0 visual system; it predates this M1 plan |
| DX Review | `/plan-devex-review` | Developer-experience gaps | 0 | — | Not applicable to this user-facing slice |
| Outside Voice | automatic plan challenge | Independent plan opinion | 0 | SKIPPED | Running under Codex, so nested Codex was skipped; sub-agent fallback was not authorized |

### Completion summary

- Step 0: scope reduced to the existing Capture, repository, workspace, Review,
  and Supabase seams while preserving the full M1 product loop.
- Architecture: 7 findings resolved.
- Code quality: 4 findings resolved.
- Tests: coverage diagram produced; 5 gaps became required suites; 58/58
  behavioral paths are specified.
- Performance: 2 findings resolved; no N+1 or persistent-cache requirement.
- NOT in scope and What already exists: written.
- `TODOS.md`: 0 new candidates; 6 CEO-approved follow-ups retained.
- Failure modes: 0 critical gaps after the plan.
- Parallelization: 2 post-contract lanes can run concurrently, followed by 1
  sequential Capture integration lane; the conflict boundary is explicit.
- Lake Score: 19/19 substantive recommendations chose the complete in-scope
  option. All 18 findings are resolved; the extra recommendation is the
  accepted scope-reduction decision.

Retrospective: recent fixes in the same area addressed Capture in-flight edits,
post-create cleanup, Review transition boundaries, adaptive state retention, and
due refresh. M1 deliberately touches those seams, so the state/event, crash,
targeted-Review, and full-app regression suites are release requirements.

The Design Review entry is fresh by age but stale for M1 scope: it does not
validate the newly specified phased Capture interaction. Application
implementation has not started; this review changed only this plan and local
gstack review artifacts.

**VERDICT:** CEO + ENG CLEARED — M1 is ready for a dedicated plan-design review
or, after an explicit implementation request, execution from T1.

NO UNRESOLVED DECISIONS
