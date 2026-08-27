# Whole Knowledge native QA report

Date: 2026-08-27

Target: Flutter Linux desktop, local Supabase only

Viewports: 1280×720 wide and 390×844 narrow
Journey: Capture → Today → Library → Review → Today → Library

## Verdict

PASS after one QA fix. Health score: **100/100**.

The complete founder-use loop works against the local Supabase stack. No
Critical or Major issues remain. The Android package was built separately;
there was no Android device or emulator available for runtime QA.

## Coverage

- Verified the initial Today empty state and wide context rail.
- Captured a vocabulary item with meaning, part of speech, and context.
- Verified Today due, recently captured, completed-today, and next-review
  summaries use persisted data.
- Verified Library lazy load, wide master-detail, narrow full-width detail,
  empty history, counters, and persisted review history.
- Completed retrieval, reveal, production, self-rating, and transactional
  review submission.
- Verified focus mode hides primary navigation.
- Verified immediate pause before response entry.
- Verified response-entry pause confirmation and in-session response restore.
- Verified narrow Today, Capture, Library detail, and bottom navigation.
- Verified an unfinished capture draft survives app restart, routes back to
  Capture, shows `Draft restored`, and requires confirmation before discard.
- Verified live user-triggered English lookup, multiple parts of speech and
  senses, attribution, and editable sense selection.

## Finding fixed during QA

### QA-001 — Library detail remained stale after a review

Severity: Major before fix; resolved.

Reproduction:

1. Open an item in Library.
2. Return to Today and complete its review.
3. Reopen Library.
4. The selected detail still showed zero counts and no history.

Cause: the lazily retained Library subtree was not invalidated when a review
completed. The item list and selected history therefore retained their
pre-review snapshot.

Fix: completing a review now invalidates the Library generation while keeping
Library lazy. The next visit reloads the bounded item page and selected history.
A focused widget regression test covers the full revisit path.

Evidence before fix:

- `screenshots/16-library-history-wide.png`
- `screenshots/16b-library-history-after-reselect.png`

Evidence after fix:

- `screenshots/17-library-history-refreshed.png`

## Key visual evidence

- Wide Today with due item: `screenshots/05-today-with-due-item.png`
- Wide Library detail: `screenshots/07-library-detail-wide.png`
- Review focus mode: `screenshots/08-review-retrieval-focus.png`
- Response pause confirmation: `screenshots/12-review-response-pause-confirmation.png`
- Restored production response: `screenshots/13-review-response-restored.png`
- Completed Today state: `screenshots/15-today-completed.png`
- Narrow Library history: `screenshots/18-library-detail-narrow.png`
- Narrow Today: `screenshots/19-today-narrow.png`
- Narrow Capture: `screenshots/20-capture-narrow.png`
- Cold-restored draft: `screenshots/21-capture-draft-restored-narrow.png`
- Explicit discard confirmation: `screenshots/23-capture-discard-confirmation.png`
- Live lookup senses: `screenshots/25-capture-live-lookup.png`
- Selected live sense and attribution: `screenshots/26-capture-live-sense-selected.png`

## Environment note

The Linux process emitted one GTK/ATK bridge assertion during startup. It was
an environment accessibility-socket warning, not a Flutter application error;
no functional or visual accessibility failure reproduced in the app.
