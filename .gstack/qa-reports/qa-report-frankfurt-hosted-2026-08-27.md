# Whole Knowledge Frankfurt hosted QA

Date: 2026-08-27

Backend: `whole-knowledge-eu` (`vubjubgyusjvsvawxzdn`), Frankfurt

Target: Flutter Linux desktop, 1280×720

Tier: Standard

## Verdict

PASS. Health score: **100/100**.

No Critical, High, Medium, or Low product issues were found. No product source
or database objects were changed during QA.

## Hosted preflight

- Local project link matched `vubjubgyusjvsvawxzdn`.
- Runtime configuration URL matched the Frankfurt project ref.
- Hosted migration history contained `20260825220000`, `20260826010000`, and
  `20260827190000` on both local and remote sides.
- Tokyo was not contacted.

## Real application journey

The following journey passed in the visible Linux application against the real
Frankfurt backend:

1. Started with a new isolated anonymous profile and a genuinely empty Today.
2. Entered an unfinished `record` vocabulary draft.
3. Terminated the application process and relaunched it with the same profile.
4. Capture reopened automatically with `Draft restored`, `record`, and the
   selected vocabulary type intact.
5. Ran a live user-triggered dictionary lookup and received multiple noun,
   adjective, and verb senses.
6. Selected the intended noun sense. Editable meaning and `noun` part of speech
   populated with provider attribution.
7. Saved the item to Frankfurt with context and part of speech.
8. Today immediately showed one due item and `record` under Recently captured.
9. Library showed `Vocabulary · noun`; item detail showed meaning, context,
   zero counts, due scheduling, and empty history.
10. Completed retrieval, reveal, production, and a Good self-rating through the
    hosted `complete_review` RPC.
11. Today showed All caught up, `record` under Completed today, and the next
    review exactly three days after completion.
12. Reopened Library immediately. Counts were `1`/`1`, next review was current,
    and both retrieval and production attempts appeared without stale data.
13. Terminated and relaunched the process again. The anonymous identity,
    Today summaries, schedule, part of speech, item detail, response, and review
    history all persisted.

## Explicit verification

- **Initial loading:** no false empty state appeared. Twelve earliest visible
  frames from the final process restart were byte-identical and already showed
  the persisted successful-content state. The full widget regression suite also
  passed its loading-state coverage.
- **Recently captured:** exactly one hosted item, `record`.
- **Completed today:** exactly the newly reviewed `record` item.
- **Next review:** `30/8/2026 · 20:04`, exactly three days after the Good review
  completed at `27/8/2026 · 20:04`.
- **Library freshness:** immediate post-review visit showed updated counts,
  response text, rating, retrieval attempt, production attempt, and schedule.
- **RLS isolation:** a second anonymous identity could not read, update, delete,
  review, or inspect attempts belonging to the owner.
- **Hardened RPC:** simultaneous submissions produced one success and one stale
  review rejection.
- **Idempotency:** replaying the winning submission returned the existing result
  without incrementing counts or adding attempts.
- **Linux runtime:** complete visible journey and two process restarts passed.
- **Android:** no device or emulator was available. The mandatory debug APK
  built successfully.

## Automated verification

- `flutter analyze`: no issues.
- `flutter test`: 64 passed; the environment-gated integration fixture skipped
  in the unconfigured aggregate run as designed.
- Frankfurt integration fixture: 1 passed separately with the Frankfurt URL and
  publishable key.
- `flutter build apk --debug`: succeeded.

## Runtime health

No Flutter exception, Supabase error, or failed application action occurred.
GTK emitted the same workstation ATK socket assertion seen in prior native QA;
it is an environment accessibility-bridge warning and did not reproduce as an
application accessibility or interaction failure.

## Evidence

- `screenshots/hosted-frankfurt-01-initial-today.png`
- `screenshots/hosted-frankfurt-02-draft-before-restart.png`
- `screenshots/hosted-frankfurt-03-draft-restored.png`
- `screenshots/hosted-frankfurt-04-dictionary-senses.png`
- `screenshots/hosted-frankfurt-05-sense-selected.png`
- `screenshots/hosted-frankfurt-06-selected-fields-and-save.png`
- `screenshots/hosted-frankfurt-07-today-after-capture.png`
- `screenshots/hosted-frankfurt-08-library-item.png`
- `screenshots/hosted-frankfurt-09-library-detail-before-review.png`
- `screenshots/hosted-frankfurt-10-production-response.png`
- `screenshots/hosted-frankfurt-11-today-completed.png`
- `screenshots/hosted-frankfurt-12-library-history-fresh.png`
- `screenshots/hosted-frankfurt-13-library-after-restart.png`
- `screenshots/hosted-frankfurt-restart-frame-01.png` through
  `hosted-frankfurt-restart-frame-12.png`

## QA summary

- Issues found: 0
- Fixes applied: 0
- Deferred product issues: 0
- Previous local baseline: 100
- Frankfurt hosted baseline: 100
- PR summary: Hosted QA found 0 issues; health score remains 100.
