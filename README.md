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

To enable the backend foundation locally, provide the client-safe project URL
and publishable key at build time:

```bash
flutter run -d linux \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

The shell still starts when these values are absent. Never pass a Supabase
secret or `service_role` key to the client.

## Development

Develop and verify Linux desktop and Android as one cross-platform product.

```bash
dart format .
flutter analyze
flutter test
flutter build linux
```
