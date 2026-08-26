# Whole Knowledge Architecture

## Direction and dependency rule

Whole Knowledge uses small vertical slices with dependencies pointing inward:

```text
UI
→ application/domain
→ repository contracts
← infrastructure adapters
  → Supabase Flutter SDK
```

Presentation code must not import `supabase_flutter`, use `Supabase.instance`,
issue database queries, or interpret Supabase auth events. Widgets depend on
application-facing contracts. The application composition root initializes
infrastructure and injects `AuthSessionRepository`, `LearningItemRepository`,
and `ReviewRepository` contracts into the workspace. Supabase adapters alone
map database rows and invoke the transactional review function.

## Supabase responsibilities

Supabase is the intended remote system for:

- authentication and server-backed user identity;
- PostgreSQL user data and cross-device synchronization;
- realtime synchronization where a concrete use case justifies it; and
- file storage later if recordings or attachments require it.

It does not own presentation state, learning-loop policy, or future offline
conflict policy. The current backend surface is intentionally limited to:

- `learning_items`, the unified expression and vocabulary collection;
- `review_attempts`, the append-only retrieval and production history; and
- `complete_review`, an atomic database function that records both attempts,
  increments counters, and advances the next review time.

No storage bucket, Edge Function, realtime channel, or broader product schema
is part of this slice.

## Bootstrap and configuration

The app reads two compile-time defines on every platform:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Copy the committed template to its ignored local path, fill in the client-safe
values, and pass the JSON file to Flutter:

```bash
cp config/supabase.example.json config/supabase.local.json
flutter run -d linux \
  --dart-define-from-file=config/supabase.local.json
```

The same file works with Android builds and runs.
`config/supabase.local.json` is ignored, while
`config/supabase.example.json` is safe to commit. Missing, partial, or invalid
configuration does not prevent the app shell from starting. Complete
configuration is passed to the isolated Supabase bootstrap before `runApp`.
Initialization failures are contained and reported without logging config
values.

Dart defines are compiled into client binaries; they are configuration, not a
secret store. The project URL and Supabase publishable key are designed for
client use. Never place a secret key, legacy `service_role` key, database
password, or other privileged credential in a define, source file, committed
configuration file, or client application.

## Authentication and sessions

`supabase_flutter` restores and persists the current session during startup.
The bootstrap reuses a valid session, explicitly refreshes an expired session,
or calls `signInAnonymously` only when no session exists before exposing
repositories to the UI. A failed refresh is surfaced instead of silently
creating a new anonymous identity and making the existing data appear lost.
Application code sees only `AuthSessionRepository` and the domain
`AuthSession`; tokens do not cross into presentation code.

Anonymous identity is device-local and transitional, not a permanent account
design. Signing out, clearing local application data, or moving to another
device before account linking can make that identity and its data inaccessible.
A future email or Google sign-in flow must link the existing anonymous user
rather than create a disconnected account, so captured data retains the same
`user_id`.
Login, linking, logout, recovery, and onboarding UI are outside this slice.
Before broader auth ships, test callback URLs on both platforms and review
whether platform-backed secure token storage is required beyond the SDK default,
especially on Linux. Hosted and local projects must explicitly allow anonymous
sign-ins; abuse controls such as CAPTCHA should be evaluated before public use.

## Row Level Security

Both product tables enable Row Level Security. Learning-item select, capture,
and delete policies require `auth.uid() = user_id`; the capture grant is limited
to user-authored columns so clients cannot set IDs, timestamps, scheduling
state, or counters. Review attempts are client-readable but append-only: direct
insert, update, and delete privileges and policies are removed. A composite
foreign key also prevents an attempt from naming an item owned by another user.

`complete_review` is the only client-accessible review write path. It is
`security definer` because authenticated clients deliberately lack permission
to mutate protected item fields and attempt history. The function uses an empty
search path, fully qualified relations, an explicit non-null `auth.uid()` check,
and an owner predicate on every read and update. A client-generated UUID plus a
database uniqueness constraint makes identical retries idempotent, while an
expected review count rejects stale concurrent submissions. Response/rating
validation happens before mutation, and PostgreSQL rolls back the entire
function on any exception. Client checks remain usability aids, never
authorization.

The hardened attempt-shape and learning-content checks are installed
`NOT VALID`: they apply to every new row without rejecting nullable production
attempts or whitespace-only content that the already-deployed base schema
permitted. Historical rows can be audited and the constraints validated in a
later migration without deleting or inventing user data.

Privileged operations and secret keys belong only in trusted server-side code.
RLS policies and their positive and negative tests are part of each future
schema change, not a later hardening pass.

## Database migrations

The initial learning loop and its security hardening are defined by ordered
migrations under `supabase/migrations/`. All later database changes must be new
migrations, reviewed before `supabase db push`; avoid dashboard-only schema
changes. Keep seed/demo data separate and never commit production data or
credentials. A new clone must run `supabase link --project-ref PROJECT_REF`
before remote commands. The current repository is linked to the Frankfurt
project. Running `supabase start`, resets, and local database tests requires a
Docker-compatible container runtime.

Database policy tests live under `supabase/tests/database/` and cover positive
and negative ownership, spoofing, protected-field grants, attempt immutability,
RPC rollback/replay behavior, scheduling, and cascading deletion. Run them
against the local disposable stack with `supabase test db`; never point test
fixtures at a linked hosted project. Concurrency is additionally protected by
the expected counter predicate and unique submission constraint. The local
integration test under `test/integration/` exercises the production
repositories against two independent anonymous sessions and competing real RPC
requests.

The V0 scheduling rule is duplicated deliberately at two boundaries: pure Dart
logic makes it visible and unit-testable, while the transaction function is the
authoritative persistence path. `again`, `hard`, `good`, and `easy` schedule 10
minutes, 1 day, 3 days, and 7 days after completion. Any future scheduling
change must update and test both representations in one migration/change set.

## Linux and Android

- Both platforms use the same configuration keys, repository contracts, and
  Supabase capabilities.
- Android declares internet access in the main manifest so release builds can
  reach Supabase; debug-only permission is insufficient.
- The Supabase Flutter SDK supplies session persistence for Linux and Android;
  anonymous-session reuse is verified through the same bootstrap on both.
- Deep-link intent filters, Linux callback handling, and OAuth redirect URLs
  will be configured only when an auth flow is selected.
- Local Supabase may use an HTTP URL during development. Android emulators need
  a host address reachable from the emulator rather than desktop `localhost`.

## Future offline and local-cache strategy

Repository contracts are the seam for a future local cache and synchronization
engine. No cache package or offline database is selected in this foundation.
Before adding one, define which actions must work offline, ownership of pending
writes, conflict resolution, deletion semantics, sync cursors, and recovery
after partial failure. Supabase remains the remote adapter rather than becoming
the domain model or presentation API.
