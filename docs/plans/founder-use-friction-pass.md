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

## Engineering architecture

The complete founder-friction scope is accepted. Breadth is divided into narrow boundaries rather than a new framework:

```text
Presentation
├── LearningWorkspace
│   ├── TodayLoadController ───────────┐
│   ├── CaptureSessionController ──────┼── application/domain contracts
│   └── ReviewSessionController ───────┘
│
Application/domain
├── CaptureDraftRepository
├── LexicalProvider
├── LearningItemRepository (targeted reads + existing writes)
├── ReviewRepository (existing write + bounded reads)
├── LoadTodayOverview
└── provider-neutral draft, lexical, overview, and page values
│
Infrastructure
├── FileCaptureDraftRepository ── path_provider + dart:io
├── EnglishDictionaryApiProvider ── package:http
├── SupabaseLearningItemRepository
└── SupabaseReviewRepository
```

Controllers are small plain-Dart transition owners. They are not a state-management framework, service locator, or workspace-global store. Widgets continue to own focus nodes, text-editing adapters, scroll controllers, and rendering.

## Capture draft persistence

Use the official `path_provider` application-support directory on Android and Linux. Store one versioned JSON document named for the Capture draft. Do not use `shared_preferences`: its official documentation warns that asynchronous persistence is not guaranteed immediately and should not hold critical data.

```text
field edit / kind change / sense selection
  → CaptureSessionController revision N
  → reset 400ms debounce
  → enqueue write after all earlier writes
  → encode versioned JSON
  → write sibling temp file with flush: true
  → rename temp over canonical draft
  → mark revision N persisted

lifecycle inactive/paused/detached
  → cancel debounce
  → flush latest revision immediately
```

Draft schema:

```json
{
  "version": 1,
  "kind": "vocabulary",
  "content": "record",
  "meaning": "stored information",
  "context": "...",
  "source": "...",
  "partOfSpeech": "noun"
}
```

Rules:

- Missing file means no draft.
- Corrupt JSON, unknown versions, invalid field types, or oversized fields fail soft and surface a restrained local-storage status; they never crash startup.
- Writes are serialized and revision-checked so an older debounce cannot overwrite newer input.
- Successful remote Save transitions once into local-clear retry. A clear failure never re-submits the remote create; the user can retry only the clear operation.
- Failed remote Save keeps the persisted and in-memory draft.
- Explicit Discard clears local storage before resetting the visible form. If clear fails, the form remains and reports the failure.
- Cold start waits for the local draft read before choosing Today versus Capture, preventing a flash of the wrong destination.
- A meaningful draft has any nonblank authored field or selected POS. Kind alone is not meaningful.

## Dictionary provider

Select EnglishDictionaryAPI (`https://englishdictionaryapi.com/api/v1/words/{word}`) for this iteration.

- Live verification on 2026-08-27 returned HTTP 200 for `record`, three POS groups, 16 senses, and 999 of 1000 hourly requests remaining.
- The service documents an English Wiktionary dump dated 2026-06-01 and CC BY-SA 4.0 data licensing.
- No account or API key is required, so no secret is embedded in the client.
- The UI labels the action as English lookup. Other languages retain the complete manual workflow.
- Results show `Definitions from Wiktionary contributors · CC BY-SA 4.0` with a license/source link. Add the same attribution to `THIRD_PARTY_NOTICES.md`.

Network flow:

```text
Find English meaning
  → trim and validate query (nonblank, bounded length)
  → coalesce identical in-flight query
  → injected http.Client.send()
      ├── 10 second timeout
      ├── HTTP 404 → no results
      ├── non-2xx → recoverable provider failure
      └── stream > 1 MiB → abort as recoverable provider failure
  → strict JSON shape/field-length validation
  → normalize common POS aliases; preserve safe unknown labels
  → provider-neutral LexicalLookupResult
  → inline grouped sense selection
```

No response, provider identifier, or lookup cache is persisted. Selecting a sense copies its definition and normalized POS into the Capture draft; Meaning remains editable.

## Database change

Create one forward-only migration:

```sql
alter table public.learning_items
  add column part_of_speech text;

alter table public.learning_items
  add constraint learning_items_part_of_speech_check
  check (
    part_of_speech is null
    or (
      length(btrim(part_of_speech)) between 1 and 80
      and part_of_speech ~ '[^[:space:]]'
    )
  );

grant insert (part_of_speech) on public.learning_items to authenticated;
```

- Existing rows remain null; no backfill or historical rewrite occurs.
- Update capture normalization, domain models, Supabase insert mapping, and row mapping.
- Keep RLS unchanged and verify ownership, spoof prevention, column grants, and nullable round trips with pgTAP.
- Run local reset, database tests, and real repository integration tests.
- Run `gstack careful` before treating the migration as complete.
- Do not apply the migration to Frankfurt until the user gives separate explicit approval. Never contact Tokyo.

## Targeted read model

`LoadTodayOverview` coordinates application contracts and returns one immutable snapshot:

```text
LoadTodayOverview(local day bounds, now)
  ├── LearningItemRepository.listDue(now)              paged internally
  ├── LearningItemRepository.listRecent(limit: 5)      one bounded query
  ├── LearningItemRepository.findNextReview(after: now) limit 1
  └── ReviewRepository.listBetween(dayStartUtc, dayEndUtc)
        ├── paged internally when > Supabase row limit
        └── unique recent item ids
              → LearningItemRepository.listByIds(ids)  one batched query
  → reviewed count, production count, practiced items, next review
```

- The local calendar day is calculated outside infrastructure and passed as UTC bounds.
- Today initial load and refresh use generation IDs; stale completions are ignored.
- A refresh keeps the previous snapshot interactive and reports refresh failure separately.
- Library `listAll()` loads lazily when Library is first selected, remains cached, and becomes dirty after capture/review mutations.
- Item history uses stable `created_at desc, id desc` ordering and pages 50 attempts at a time. The UI deduplicates by attempt ID when appending a page.
- No widget sees Supabase row maps and no query runs once per displayed item.

## Explicit state machines

```text
TodayLoadState
initialLoading
  ├── success → data(snapshot, refreshing: false)
  └── failure → initialError
data
  ├── refresh → data(previous, refreshing: true)
  ├── refresh success → data(new, refreshing: false)
  └── refresh failure → data(previous, refreshError)
```

```text
ReviewSessionState
idle → active(recall → revealed → production → rating)
active ── Back ──→ paused ── Resume ──→ active
active ── save failure ──→ active(same response + submission id, error)
active ── successful rating ──→ next item or completed
paused ── explicit discard ──→ idle
```

```text
CaptureSessionState
restoring → clean | restored(draft) | restoreWarning
clean/restored → dirty(revision)
dirty → lookupLoading → lookupResults | lookupError
dirty → savingRemote → clearingLocal → saved
savingRemote failure → dirty(same draft, error)
clearingLocal failure → clearRetry(remote already saved)
dirty → discardingLocal → clean | dirty(clear error)
```

These state objects prevent boolean combinations such as initial-loading plus loaded-data, paused plus completed, or remote-saved plus resubmittable.

## Failure modes

| Code path | Realistic failure | Handling | Test | User-visible result |
|---|---|---|---|---|
| Draft load | Truncated JSON after external interruption | Ignore invalid document, retain file for diagnostics, start usable form | Unit | Restrained restore warning; no crash |
| Draft save | Older debounced write finishes last | Serialized revision queue | Unit | Latest text remains after reconstruction |
| Draft clear | Remote item saved but file removal fails | Enter clear-retry state; never repeat remote create | Unit + widget | Saved status with Retry cleanup; input not silently duplicated |
| Lookup | Timeout, 429, 500, disconnect | Bounded request and recoverable error | Unit + widget | Manual field and Retry remain available |
| Lookup | Malformed or >1 MiB response | Reject before domain mapping | Unit | Manual-safe provider error |
| Today load | Empty result arrives after a newer content result | Generation guard ignores stale completion | Unit + widget | No false empty flash |
| Today refresh | Network failure with cached snapshot | Preserve snapshot and expose refresh status | Unit + widget | Existing content remains interactive |
| Day summary | Local midnight crosses UTC date | Explicit local-day-to-UTC bounds | Unit | Counts match the user's calendar day |
| Library history | More than one Supabase page or page overlap | 50-row pages, stable ordering, ID dedupe | Repository + widget | Load more without duplicates |
| Detail load | Selected item changes while history request is in flight | Selection generation guard | Widget | Old history never appears under new item |
| Review pause | Background refresh supplies a new due queue | Paused state rejects queue replacement | Unit + widget | Response and progress remain intact |
| Context menu | Android exposes PROCESS_TEXT applications | Filter to essential button types on narrow Android only | Unit/widget where possible + runtime | Compact Cut/Copy/Paste/Select all toolbar |
| Migration | Client can set protected scheduling fields or another owner | Existing RLS plus column grant tests | pgTAP + integration | Unauthorized mutation fails |

No identified failure is silent without both handling and a planned test.

## Test coverage plan

```text
CODE PATHS                                      USER FLOWS
[NEW] Capture draft                             [NEW] Leave Capture → process death → restore
  ├── missing/valid/corrupt/version               ├── restored status and destination
  ├── serialized debounce + lifecycle flush       ├── Save clears / failure preserves
  └── clear retry without duplicate remote save   └── explicit Discard clears
[NEW] Lexical provider                          [NEW] Find meaning
  ├── multi-POS/sense mapping                     ├── choose sense → editable meaning/POS
  ├── 404/timeout/non-2xx                          └── failure → manual save remains usable
  └── malformed/oversized body
[NEW] Today overview                            [NEW] Today continuity
  ├── initial/data/error                           ├── no empty before load
  ├── stale refresh generation                     ├── refresh preserves content
  └── local-day aggregation                        └── waiting/completed/first-use states
[NEW] Library history                           [NEW] Open item detail
  ├── page/order/dedupe                            ├── mobile full detail
  └── selection generation                         └── desktop master-detail + load more
[EXTEND] Review session                         [EXTEND] Focused production
  ├── active/paused/resumed                        ├── nav hidden + safe Back/Resume
  └── immutable failure retry data                 └── compact mobile edit menu
```

Planned files and assertions:

- `test/infrastructure/local/file_capture_draft_repository_test.dart`: missing, round-trip, corrupt, unknown version, flush/write/clear failures, serialized latest-write behavior.
- `test/infrastructure/dictionary/english_dictionary_api_provider_test.dart`: live-shape fixture mapping, multi-POS/senses, aliases, unknown safe POS, 404, timeout, non-2xx, invalid JSON, invalid fields, 1 MiB cap.
- `test/application/learning/capture_session_controller_test.dart`: restore threshold, debounce, lifecycle flush, failed save preservation, successful clear, clear retry, discard.
- `test/application/learning/today_load_controller_test.dart`: initial/data/error, stale completion, refresh preservation, refresh failure.
- `test/application/learning/load_today_overview_test.dart`: reviewed/production counts, practiced order/dedupe, timezone bounds, next review.
- `test/application/learning/review_session_controller_test.dart`: all stage transitions, pause/resume, queue update rejection, save retry identity, explicit discard.
- `test/infrastructure/supabase/supabase_row_mappers_test.dart`: nullable and populated POS plus attempt ordering data.
- `test/infrastructure/supabase/supabase_learning_item_repository_test.dart`: targeted queries, bounded limits, batched IDs, POS insert mapping.
- `test/infrastructure/supabase/supabase_review_repository_test.dart`: time-window pagination and item-history pagination/order.
- `test/app_test.dart` or focused presentation tests: every user-visible requirement listed in the original brief at narrow, medium, and wide widths.
- `supabase/tests/database/learning_loop_test.sql`: column, constraint, grants, RLS, null compatibility, POS round trip, protected columns.
- `test/integration/local_supabase_review_concurrency_test.dart`: retain existing review concurrency and extend real capture/read behavior where relevant.

Critical end-to-end QA journey:

```text
Capture draft → cold restart restore → lookup/select/edit → save
→ Today recent + due → focused Review/pause/resume/complete
→ Today completed summary → Library item detail/history
```

## Implementation order

Sequential implementation, no worktree parallelization. The three logical commits share domain models, repository interfaces, `AppDependencies`, `LearningWorkspace`, and the main widget test harness. Parallel worktrees would create more merge risk than time saved.

```text
1. Capture reliability and lookup
   domain/contracts → file + HTTP adapters → Capture controller/UI → tests
2. Today and Library continuity
   targeted repository reads → overview/load state → adaptive surfaces → tests
3. Review and visual polish
   review state → shell focus behavior → context menu → tokens/DESIGN.md → tests
4. Migration/local database validation → full builds → gstack review/careful/QA
```

## Implementation tasks

- [ ] **T1 (P1, human: ~1 day / Codex: ~1h)** — Capture — Add versioned atomic draft storage and `CaptureSessionController`.
  - Surfaced by: Architecture review — preferences storage does not promise critical-write durability.
  - Verify: repository and controller unit tests plus cold-start widget restoration.
- [ ] **T2 (P1, human: ~1 day / Codex: ~1h)** — Dictionary — Add the bounded EnglishDictionaryAPI adapter and inline grouped selection.
  - Surfaced by: Architecture/performance reviews — provider neutrality, licensing, timeout, and response cap.
  - Verify: HTTP adapter unit tests and manual-safe widget failure tests.
- [ ] **T3 (P1, human: ~0.5 day / Codex: ~30m)** — Schema — Add nullable `part_of_speech` through a local-only forward migration.
  - Surfaced by: Architecture review — selected POS must sync without provider IDs.
  - Verify: mapper, pgTAP, local reset, and real repository integration tests.
- [ ] **T4 (P1, human: ~1.5 days / Codex: ~1.5h)** — Today — Add targeted queries, immutable overview, explicit load states, and adaptive continuity UI.
  - Surfaced by: Architecture/code-quality reviews — full-account reload and invalid boolean states.
  - Verify: aggregation/controller/repository tests and initial/refresh widget regressions.
- [ ] **T5 (P1, human: ~1.5 days / Codex: ~1.5h)** — Library — Add lazy Library loading, adaptive item detail, and paged review history.
  - Surfaced by: Architecture/performance reviews — dead rows and potentially unbounded history.
  - Verify: pagination/order tests plus narrow/wide detail widget flows.
- [ ] **T6 (P1, human: ~1 day / Codex: ~1h)** — Review — Add explicit session state, focus mode, pause/resume, and Android essential-action toolbar.
  - Surfaced by: Code-quality review — independent booleans cannot safely encode pause and refresh.
  - Verify: transition unit tests, adaptive navigation tests, and Android runtime QA.
- [ ] **T7 (P2, human: ~0.5 day / Codex: ~30m)** — Design system — Add `DESIGN.md`, semantic radii, stable organic variants, and component usage updates.
  - Surfaced by: Design-system review — rules need executable tokens and durable documentation.
  - Verify: token tests where useful and visual QA at all three widths.
- [ ] **T8 (P1, human: ~1 day / Codex: ~1h)** — Verification — Run the full layered suite, builds, boundary/config checks, gstack review, careful, and QA.
  - Surfaced by: Test review — every new boundary needs error-path evidence.
  - Verify: commands and journey listed in this plan.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|---|---|---|---:|---|---|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | Not run | Not required for this bounded founder-friction pass |
| Codex Review | `/codex review` | Independent second opinion | 0 | Not run | Outside voice skipped; implementation diff receives requested `/review` |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | Clear | 6 issues resolved, 0 critical gaps, full test matrix defined |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | Clear | 7/10 → 10/10; 10 decisions resolved |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | Not run | Not applicable |

**VERDICT:** DESIGN + ENG CLEARED — ready to implement.

NO UNRESOLVED DECISIONS
