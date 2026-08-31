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
`ReviewRepository`, `CaptureDraftRepository`, and `LexicalProvider` contracts
into the workspace. Supabase adapters alone map database rows and invoke the
transactional Discovery and Review functions. Local files and external lexical HTTP are
separate infrastructure adapters; neither leaks into widgets or domain policy.

## Supabase responsibilities

Supabase is the intended remote system for:

- authentication and server-backed user identity;
- PostgreSQL user data and cross-device synchronization;
- realtime synchronization where a concrete use case justifies it; and
- file storage later if recordings or attachments require it.

It does not own presentation state, learning-loop policy, or future offline
conflict policy. The current backend surface is intentionally limited to:

- `learning_items`, the unified expression and vocabulary collection;
- `review_attempts`, the append-only retrieval and production history;
- `complete_discovery`, the idempotent same-surface-aware creation boundary; and
- `complete_review`, an atomic database function that records both attempts,
  increments counters, and advances the next review time.

No storage bucket, Edge Function, realtime channel, or broader product schema
is part of this slice.

`learning_items.part_of_speech` is nullable free text with normalized common
aliases at capture time and a nonblank 80-character database bound. It is not a
fixed enum, so provider vocabulary and manually entered values remain durable.

## Local capture drafts and lexical lookup

Capture drafts are device-local working state, not synchronized product data.
`CaptureDraftV2` stores authored fields, the manual meaning buffer, first
production, revision-based confirmation stamps, and the prepared/attempted
submission checkpoint. It does not persist provider payloads, progress,
matches, or other derivable state. The adapter stores versioned JSON in the
platform application-support directory, writes through a temporary file with a
flushed atomic rename, rejects stale revision writes, and serializes writes.
Meaningful drafts are restored before startup routing, debounced after edits,
flushed on lifecycle transitions, and cleared only after a confirmed or
idempotently replayed remote create or explicit discard.

English meaning lookup is user-triggered and optional. The current adapter uses
the no-key EnglishDictionaryAPI endpoint, enforces a ten-second timeout and
one-MiB streamed response limit, and coalesces duplicate in-flight terms. It
persists only the chosen editable definition and normalized part of speech—not
provider identifiers or raw responses. Other languages and every provider
failure retain the manual meaning path.

One sealed Discovery phase family owns the workflow state. Its narrow immutable
phase values distinguish independent Library and lexical outcomes, meaning
choice, re-encounter selection/reveal, submission, reconciliation, and final
confirmation. The adaptive Capture UI renders that family as one centered,
focused document. Library and lexical reads start together and report progress
independently. Re-encounter launches the workspace-owned Review controller
instead of creating a second Review surface.

## Read models and pagination

Today is loaded through a bounded application read model: up to 100 due items,
five recent captures, five items completed in the current local day, and the
next scheduled review. Refresh generations reject stale responses while the UI
keeps the last successful overview visible. Library reads 50 items per page;
item detail reads 50 existing review attempts per page. Repository adapters use
set-based joins and targeted indexes, so neither screen performs per-row
follow-up queries.

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

Both product tables enable Row Level Security. Learning-item select, legacy
capture, and delete policies require `auth.uid() = user_id`. M1 creation uses
`complete_discovery`, which accepts no owner or protected state and derives
ownership only from `auth.uid()`. The temporary legacy capture grant remains
limited to user-authored columns so an older client cannot set IDs, timestamps,
scheduling state, or counters. Review attempts are client-readable but
append-only: direct insert, update, and delete privileges and policies are removed. A composite
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

`complete_discovery` is likewise a `security definer` transaction with an empty
search path. It validates all authored fields, checks identical submission
replay before duplicate handling, and takes an owner/surface advisory lock
before rechecking active rows. The stored generated `surface_match_key` is
indexed by owner and active status but deliberately non-unique: an additional
sense is created only when the explicit allow-existing intent is present. A
completed first production schedules 24 hours ahead; a deferral schedules now.
The client cannot supply owner, schedule, counters, timestamps, or review time.

The hardened attempt-shape, learning-content, and part-of-speech checks are installed
`NOT VALID`: they apply to every new row without rejecting nullable production
attempts or whitespace-only content that the already-deployed base schema
permitted. Historical rows can be audited and the constraints validated in a
later migration without deleting or inventing user data.

Privileged operations and secret keys belong only in trusted server-side code.
RLS policies and their positive and negative tests are part of each future
schema change, not a later hardening pass.

## Database migrations

The initial learning loop, its security hardening, and read-model support are defined by ordered
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
fixtures at a linked hosted project. Review concurrency is protected by the
expected counter predicate and unique submission constraint. Discovery
concurrency is protected by an owner-scoped submission uniqueness constraint
and the same-surface advisory lock. Local integration tests under
`test/integration/` exercise production repositories against independent
anonymous sessions and competing real RPC requests. The surface query plan is
also checked against a 10,000-row local fixture.

The post-Review V0 scheduling rule is duplicated deliberately at two boundaries: pure Dart
logic makes it visible and unit-testable, while the transaction function is the
authoritative persistence path. `again`, `hard`, `good`, and `easy` schedule 10
minutes, 1 day, 3 days, and 7 days after completion. Any future scheduling
change must update and test both representations in one migration/change set.
Discovery adds a separate authoritative initial schedule of now when production
is deferred or 24 hours when it is completed. Across both paths,
`next_review_at` is the sole due-state authority; review count is never a due
shortcut.

## Diagnostics and staged rollout

Discovery failures cross infrastructure as a closed typed code with constrained
metadata. The diagnostic contract can expose operation, phase, broad HTTP
status group, backend code, duration, retry/generation counts, opaque item or
submission IDs, and reconciliation outcome. It has no fields capable of
carrying captured language, meaning, production, context, source URL, provider
body, token, or configuration. The default sink is a no-op; M1 adds no hosted
analytics vendor.

The Flutter direct-create API has been removed. The additive migration retains
the narrow legacy database insert grant until a separately approved hosted
migration and Linux/Android live smoke pass. Only then may a reviewed forward
migration revoke it. Rollback is forward-only: before revocation, revert the
client; after revocation, restore the narrow legacy grant in a reviewed forward
migration before reverting the client. Operational steps live in
[Discovery troubleshooting and rollout](troubleshooting.md).

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
