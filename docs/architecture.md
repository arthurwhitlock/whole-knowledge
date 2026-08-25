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
infrastructure; the bootstrap prepares an auth-session repository implementation
for wiring when a feature first needs it. No widget consumes it yet.

## Supabase responsibilities

Supabase is the intended remote system for:

- authentication and server-backed user identity;
- PostgreSQL user data and cross-device synchronization;
- realtime synchronization where a concrete use case justifies it; and
- file storage later if recordings or attachments require it.

It does not own domain rules, presentation state, learning-loop decisions, or
future offline conflict policy. No product schema, storage bucket, Edge
Function, or realtime channel is part of the current foundation.

## Bootstrap and configuration

The app reads two compile-time defines on every platform:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

For example:

```bash
flutter run -d linux \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

The same defines work with Android builds and runs. Missing, partial, or invalid
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
Its default storage currently uses `SharedPreferencesAsync` across supported
platforms. Application code sees only the `AuthSessionRepository` contract and
the domain `AuthSession`; access and refresh tokens do not cross into the
presentation layer.

The foundation exposes the current session and a session-change stream. Login,
registration, logout, account recovery, and onboarding are deliberately not
implemented. When auth UI is added, stream subscriptions must handle errors,
and OAuth or magic-link flows must add and test platform-specific callback URLs.
Before production auth is enabled, review whether platform-backed secure token
storage is required beyond the SDK default, especially on Linux.

## Row Level Security

Every future table exposed through Supabase APIs must enable Row Level Security
before client access. Policies should default to denial and scope rows to the
authenticated user, normally through `auth.uid()`, with explicit policies for
each allowed operation. Client checks are usability aids, never authorization.

Privileged operations and secret keys belong only in trusted server-side code.
RLS policies and their positive and negative tests are part of each future
schema change, not a later hardening pass.

## Database migrations

No application schema is defined yet. When schema work begins, initialize the
Supabase CLI layout and commit ordered SQL migrations under
`supabase/migrations/`. Apply changes through migrations in local, staging, and
production environments; avoid untracked dashboard-only schema changes. Keep
seed/demo data separate from migrations and never commit production data or
credentials.

## Linux and Android

- Both platforms use the same configuration keys, repository contracts, and
  Supabase capabilities.
- Android declares internet access in the main manifest so release builds can
  reach Supabase; debug-only permission is insufficient.
- The Supabase Flutter SDK supplies platform session persistence for Linux and
  Android. Both targets require explicit verification once real authentication
  flows exist.
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
