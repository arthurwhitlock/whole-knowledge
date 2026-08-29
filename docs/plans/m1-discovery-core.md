# Whole Knowledge M1 — Discovery Core

Status: CEO-reviewed specification  
Mode: Scope Reduction  
Approved approach: Focused Discovery vertical slice  
Date: 2026-08-29

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

Initial surface:

```text
Capture

What did you encounter?

[ improbable                                  ]

English discovery                       Discover →
Enter meaning manually
```

Rules:

- No meaning, POS, context, source, filters, statistics, or recent list appears
  initially.
- Empty or whitespace-only submission shows one inline live-region error and
  retains focus.
- Enter/submit and the button invoke the same coalesced transition.
- A restored durable draft returns to its last valid phase with a restrained
  `Draft restored` status.
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
unlikely to happen or be true
Last reviewed 4 days ago

Test myself
Show meaning
Learn another sense
```

When several items match, the learner first chooses the known sense. Then:

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
→ save and enter Review
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

First review: 30 Aug, 14:20

Done                                      Capture another
```

Deferred production says `Ready to practice now` instead. The state is
announced as a semantic live region. Motion is a reduced-motion-safe fade and
small reveal; there is no confetti, bounce, reward iconography, or automatic
redirect. `Done` goes to Today. `Capture another` resets to Entry only after the
successful transaction is reconciled.

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
| `CaptureSessionController` and durable file draft | Refactor into explicit Discovery state; retain repository and lifecycle behavior |
| Provider-neutral `LexicalProvider` | Extend to POS groups and optional examples |
| Bounded EnglishDictionaryAPI adapter | Reuse timeout, body cap, request coalescing, attribution, and manual fallback |
| Flat `learning_items` with nullable POS | Retain one item per learned sense; add capture-origin production and idempotency fields |
| Append-only `review_attempts` and `complete_review` | Reuse unchanged for Test myself; do not mix first production into scheduled attempts |
| RLS and protected scheduling fields | Preserve; add one hardened Discovery transaction |
| Today overview and real history | Refresh after save; do not add a duplicate M1 daily surface |
| Quiet-luxury tokens, motion, and accessibility rules | Apply to progressive disclosure and completion |

Current style references:

- native navigation and stable screen identity in `learning_workspace.dart`;
- stale-generation protection in the Today and Library loading flows;
- provider and repository isolation from widgets;
- centralized colors, spacing, radii, typography, and motion.

Anti-patterns to avoid:

- extending the current 585-line Capture form into a thousand-line phase
  controller;
- flattening and globally truncating lexical senses;
- adding widget-level Supabase or HTTP behavior;
- inventing a generic wizard, graph, analytics platform, or dictionary cache.

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
│ DiscoverySessionController (one immutable state machine)             │
│ ├── CaptureDraftRepository                                           │
│ ├── LexicalProvider                                                  │
│ ├── LearningItemRepository.findActiveBySurfaceForm                   │
│ ├── LearningItemRepository.completeDiscovery                         │
│ └── existing ReviewSessionController for Test myself                 │
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

## 20. Discovery state machine

```text
RESTORING
  ├── valid draft ───────────────────────────────────────┐
  ├── missing draft → ENTRY                              │
  └── failed read → ENTRY + visible warning             │
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
  ├── success/replay reconciliation → DISCOVERED
  ├── validation → prior phase + field error
  ├── payload conflict → reconciliation error
  └── unavailable → prior phase + retry same submission ID

DISCOVERED ── Done → Today
           └─ Capture another → ENTRY
```

Invalid transitions are ignored or rejected by the controller. Widgets cannot
construct combinations such as re-encounter plus new-item saving. Term/type
changes increment the request generation and invalidate derived completion.

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

M1 keeps the flat learning-item model. One spelling may have several items when
the learner explicitly chooses several senses.

Additive database needs:

- nullable capture-origin first-production text on `learning_items`;
- a client-generated Discovery submission UUID with uniqueness scoped to owner;
- a normalized exact-match query and matching index, without a uniqueness
  constraint on content;
- `complete_discovery`, an authenticated idempotent transaction;
- a later hardening migration that revokes legacy direct item insertion.

`complete_discovery`:

1. accepts no owner, counter, timestamp, or schedule parameters;
2. requires a non-null authenticated user;
3. validates kind and all field lengths, requires content and meaning, and
   validates optional production;
4. detects identical replay and returns the existing item;
5. rejects submission-ID reuse with different payload;
6. sets initial scheduling to now or 24 hours according to production presence;
7. leaves review and production counters at zero;
8. uses an empty search path and fully qualified relations;
9. grants execution only to authenticated callers.

Repository contracts expose provider- and backend-neutral values. Presentation
receives neither raw PostgREST failures nor database rows.

## 23. Error and rescue registry

| Method/code path | Named failure | Rescued | Rescue action | User sees |
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

Adapters may catch concrete HTTP, filesystem, and PostgREST exceptions, but must
map them to this closed application taxonomy. Widgets never catch `Object` or
display raw exception strings.

## 24. Error flow

```text
External failure
   │
   ▼
Infrastructure adapter identifies concrete cause
   │
   ▼
Typed application failure
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
| Sense list | 10–20 senses | Yes | Unit + widget | Two per POS + expansion | No |
| Sense choice | Later POS hidden | Yes | Widget | Every POS heading visible | No |
| Production | Sense changes after sentence | Yes | Unit + widget | Sentence preserved, unconfirmed | Metadata |
| Draft | Process exits during phase | Yes | Repository + widget | Draft restores to valid phase | Metadata on failure |
| Save | Repeated activation | Yes | Unit + integration | One in-flight mutation | Metadata |
| Save | Server commits, response lost | Yes | pgTAP + integration | Retry reconciles one item | Metadata |
| Save | Submission UUID reused with changed payload | Yes | pgTAP + integration | Conflict, no second row | Metadata |
| Scheduling | Production completed | Yes | Unit + pgTAP | First review in 24 hours | No |
| Scheduling | Production deferred | Yes | Unit + pgTAP | Ready to practice now | No |
| Re-encounter | Multiple learned senses | Yes | Repository + widget | All matching senses shown | No |
| Re-encounter | Item disappears before Test myself | Yes | Unit + widget | Refresh/recovery message | Metadata |
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
| Oversized/blank/untrusted Unicode input | Medium | Medium | Dart usability checks plus authoritative SQL validation |
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
- Keep the existing 10-second provider timeout and 1 MiB streamed-body cap.
- Add no persistent lexical cache and no shared dictionary table.
- Use one indexed owner/surface match query; no per-result follow-up queries.
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
UNIT
├── every legal and invalid Discovery transition
├── type suggestion and override
├── upstream invalidation and reconfirmation
├── parallel request generation and coalescing
├── scheduling policy
└── typed failure mapping

ADAPTER
├── multi-POS examples
├── 404 / 429 / timeout / non-2xx
├── malformed / empty / oversized provider body
├── normalized match query
└── row mapping for first production and replay metadata

WIDGET
├── every phase: loading / empty / error / success / partial
├── narrow and wide layout
├── keyboard, touch, focus, semantics, text scaling
├── 20-sense progressive disclosure
├── re-encounter choices
├── production defer and reconfirmation
└── reduced-motion completion

DATABASE / INTEGRATION
├── valid complete_discovery with and without production
├── 24-hour versus immediate schedule
├── identical replay and payload conflict
├── cross-user and protected-field negative tests
├── direct-grant cutover tests
└── lost-response retry returns exactly one item

RUNTIME
├── Linux full Discovery journey
├── Android full Discovery journey
├── mobile keyboard/IME and back behavior
└── desktop keyboard/focus and window resizing
```

Required completion commands:

```bash
dart format .
flutter analyze
flutter test
supabase test db
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

## 39. Implementation tasks

Synthesized from this review. No task authorizes hosted deployment without the
separate approvals named above.

- [ ] **T1 (P1, human: ~1 day / Codex: ~2h)** — Domain — Extend provider-neutral lexical and learning-item values.
  - Surfaced by: Architecture and sense-overload review.
  - Files: `lib/application/capture/lexical_provider.dart`, `lib/domain/learning/learning_item.dart`, row mappers, focused tests.
  - Verify: grouped POS/example fixtures, nullable first production, existing-row compatibility.
- [ ] **T2 (P1, human: ~2 days / Codex: ~3h)** — Database — Add replay-safe Discovery schema, exact-match support, and `complete_discovery`.
  - Surfaced by: Architecture, security, and rollout reviews.
  - Files: new forward migrations, `supabase/tests/database/learning_loop_test.sql`.
  - Verify: local reset, pgTAP ownership/grant/validation/replay/conflict/scheduling tests.
- [ ] **T3 (P1, human: ~2 days / Codex: ~3h)** — Repositories — Add normalized re-encounter lookup and typed Discovery mutation mapping.
  - Surfaced by: Re-encounter and error/rescue reviews.
  - Files: learning repository contract, Supabase adapter, fakes, mapper/repository tests.
  - Verify: all matching senses, no stemming, typed failures, identical retry.
- [ ] **T4 (P1, human: ~3 days / Codex: ~5h)** — State — Refactor Capture into one immutable Discovery state machine while retaining durable drafts.
  - Surfaced by: Architecture and interaction review.
  - Files: Capture draft/state/controller and unit tests.
  - Verify: complete transition table, stale generations, partial reads, reconfirmation, restart, retry.
- [ ] **T5 (P1, human: ~3 days / Codex: ~6h)** — Presentation — Build focused Entry, Vocabulary, Expression, Re-encounter, Production, and Discovered phases.
  - Surfaced by: Code quality and Design review.
  - Files: `CaptureScreen` plus focused presentation widgets and widget tests.
  - Verify: narrow/wide states, 20-sense flow, manual fallback, completion, accessibility, reduced motion.
- [ ] **T6 (P1, human: ~1 day / Codex: ~2h)** — Navigation/Review — Style native Capture prominence and route Test myself through existing Review.
  - Surfaced by: Navigation-role and evidence decisions.
  - Files: `learning_workspace.dart`, Today/Review integration tests, theme tokens only if a semantic token is missing.
  - Verify: mobile/desktop navigation semantics, non-due item Review, Show meaning causes no write.
- [ ] **T7 (P1, human: ~1 day / Codex: ~2h)** — Reliability — Add typed failure mapping, metadata diagnostics, and troubleshooting runbook.
  - Surfaced by: Error, security, and observability reviews.
  - Files: provider/adapter/controller boundaries, documentation, failure tests.
  - Verify: every registry row has stable copy, recovery, test, and content-free diagnostics.
- [ ] **T8 (P1, human: ~2 days / Codex: ~4h)** — Verification — Complete layered tests and both target builds.
  - Surfaced by: Test review.
  - Files: unit, widget, infrastructure, database, and local integration suites.
  - Verify: `dart format .`, `flutter analyze`, `flutter test`, `supabase test db`, `flutter build linux`, `flutter build apk --debug`.
- [ ] **T9 (P1, human: ~1 day / Codex: ~2h)** — Rollout/docs — Update durable design/architecture docs and execute the approved two-phase rollout only with separate hosted approval.
  - Surfaced by: Deployment and stale-diagram reviews.
  - Files: `DESIGN.md`, `docs/architecture.md`, `README.md`, forward hardening migration.
  - Verify: diagrams current, both live smoke journeys pass before direct insert is revoked.

## 40. Deferred work

Accepted follow-ups are recorded in `TODOS.md`:

1. P2 Library search and organization.
2. P2 conditional Today’s Captures surface.
3. P3 Meaning Match recognition experiment.
4. P3 knowledge-pool visual exploration, evidence-gated.
5. P3 multilingual identity and provider routing.
6. P3 deeper knowledge exploration and future Pro boundary.

No unresolved product or architecture decisions remain in this specification.
