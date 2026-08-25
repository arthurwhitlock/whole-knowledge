# Whole Knowledge

Whole Knowledge is a standalone, local-first personal Language OS built with
Flutter. The current project contains only the application shell and its
`shadcn_ui`-based design-system foundation.

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

Supabase is the intended backend for authentication, PostgreSQL user data,
cross-device synchronization, potentially realtime synchronization, and later
storage if recordings or attachments require it. The repository now contains a
fail-soft bootstrap and auth-session boundary, but no product schema or auth UI.
Supabase remains behind application and repository boundaries rather than being
called directly from UI widgets. See [Architecture](docs/architecture.md).

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
changes. Running the full local stack with `supabase start` additionally
requires a Docker-compatible container runtime.

## Development

Develop and verify Linux desktop and Android as one cross-platform product.

```bash
dart format .
flutter analyze
flutter test
flutter build linux
flutter build apk --debug
```
