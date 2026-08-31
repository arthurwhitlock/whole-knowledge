# Whole Knowledge

Whole Knowledge is a standalone personal Language OS built with Flutter. The
founder-use slice supports transactional Discovery, optional English meaning
lookup, exact-surface re-encounter, a real Today home, adaptive Library history,
and the complete retrieval, production, self-rating, and rescheduling loop. Its interface uses
the existing `shadcn_ui`-based design-system foundation.

## Current direction

Whole Knowledge is primarily a personal side project. The immediate goal is to
build a system that is genuinely useful to its creator on desktop and mobile,
then improve it through direct use and rapid iteration:

```text
Build
→ Use personally
→ Observe friction
→ Simplify
→ Improve
→ Repeat
```

Founder usage is the primary feedback loop. Formal recruitment and contextual
observation are **deferred — not blocking current product development**. The
existing [demand evidence](docs/designs/demand-evidence.md), [observation
protocol](docs/designs/contextual-observation-protocol.md), and
[research kit](docs/research/) remain preserved for reference and may be
resumed deliberately later.

The current core-loop hypothesis is:

```text
Encounter / Capture
→ Understand
→ Retrieve
→ Produce
→ Correct
→ Reuse
↺
```

The narrower product thesis—that serious learners struggle to turn personally
encountered language and their own mistakes into language they can retrieve,
produce, correct, and reuse—guides implementation but is not a gate requiring
another research phase. The handoffs between these activities remain a key
design hypothesis. “Language OS” is the long-term vision; implementation should
still favor small vertical slices and working learning loops over breadth.

## Platforms and data direction

Linux desktop and Android are both first-class targets. Whole Knowledge should
provide the same product, data, and capabilities on both, with adaptive
presentation for narrow and wide layouts, window resizing, keyboard and mouse,
and touch.

Supabase provides anonymous V0 identity and PostgreSQL persistence for learning
items and review attempts. Supabase remains behind application and repository
boundaries rather than being called directly from UI widgets. See
[Architecture](docs/architecture.md) for the schema, RLS rules, schedule, and
account-transition strategy.

To enable the hosted backend locally, copy the safe template and replace its
placeholders with the client-safe project URL and publishable key from the
Supabase dashboard or CLI:

```bash
cp config/supabase.example.json config/supabase.local.json
flutter run -d linux \
  --dart-define-from-file=config/supabase.local.json
```

`config/supabase.local.json` is ignored by Git. The shell still starts when the
file or values are absent. Never place a Supabase secret, database password, or
`service_role` key in this file or the client application.

## Discovery and the first learning loop

The current vertical slice deliberately stays small:

```text
Capture one word or expression
→ Check the Library and English meanings independently
→ Choose or author the intended meaning
→ Produce a first sentence, or explicitly defer it
→ Confirm one transactional Discovery
→ Re-encounter the same surface through the existing Review
→ Retrieve its meaning
→ Reveal the captured notes
→ Produce a written response
→ Self-rate Again / Hard / Good / Easy
→ Schedule the next review
```

Items with a completed first production receive their first Review in 24 hours.
Items whose first production was deferred are due immediately. Thereafter the
V0 intervals are 10 minutes, 1 day, 3 days, and 7 days respectively.
`next_review_at` alone determines due state. Ratings are self-assessments; no
automatic grading is performed.

`CaptureDraftV2` stores only authored and recovery truth on the device. It keeps
editable meaning, details, first production, confirmation revisions, and an
idempotent submission checkpoint until the server outcome is known. Provider
results, progress, and other derivable state are not persisted. English lookup
is optional and fills editable fields; manual meaning entry remains available
for every language and failure state. Dictionary responses are bounded and
coalesced only while identical requests are in flight; there is no persistent
lexical cache.

## Supabase CLI

The repository is initialized for the Supabase CLI in `supabase/`. Install the
current stable CLI, authenticate, and link a new clone before using remote
commands:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase migration list
```

Create all future database changes as version-controlled migrations with
`supabase migration new DESCRIPTION`. Do not make dashboard-only schema
changes. Apply reviewed changes to the linked project with `supabase db push`.
Running the full local stack with `supabase start` additionally requires a
Docker-compatible container runtime. Anonymous sign-ins must be enabled for
both hosted and local development projects.

Run migration and RLS/RPC policy tests only against that disposable local
stack:

```bash
supabase start
supabase db reset --local
supabase test db
supabase db lint --local
```

Do not run database test fixtures against a linked hosted project.

The additive M1 migration intentionally leaves the legacy direct-insert grant
in place for a two-phase client rollout. The Flutter client no longer uses that
path. Revoking the database grant is a later forward migration, performed only
after an approved hosted migration, Linux/Android client rollout, and live
Discovery smoke tests. See [Discovery troubleshooting and rollout](docs/troubleshooting.md).

## Development

Develop and verify Linux desktop and Android as one cross-platform product.

```bash
dart format .
flutter analyze
flutter test
supabase test db
flutter test integration_test/discovery_flow_test.dart -d linux
flutter build linux
flutter build apk --debug
```
