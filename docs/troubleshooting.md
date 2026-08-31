# Discovery troubleshooting and rollout

This runbook covers M1 Discovery without exposing learner-authored content.
Run database checks only against the disposable local Supabase stack unless a
separate hosted deployment has been explicitly approved.

## Privacy-safe evidence

Record only the typed failure code, operation and phase, broad HTTP status
group, duration/retry/generation counts, opaque item or submission identifiers,
and reconciliation result. Never record captured language, meanings, learner
sentences, context, source URLs, provider response bodies, auth tokens,
publishable keys, database passwords, or configuration values.

## Dictionary outage or rate limit

Confirm the UI reports Library and dictionary state independently and that
`Enter meaning manually` remains usable. A 404 maps to entry-not-found, 429 to
rate-limited, the single ten-second request/body deadline to timed-out, and an
over-one-MiB response to response-too-large. Retry may start a new lookup;
identical concurrent requests are coalesced, but no result is cached beyond the
active Discovery session.

## Library check failure

A Library failure must not erase dictionary results or authored meaning. It
does gate `complete_discovery`, because duplicate-surface intent cannot be
decided safely. Retry the Library check in place. If the restored auth session
is unavailable, recover that session rather than silently creating a different
anonymous identity.

## Migration mismatch

Against local Supabase, run:

```bash
supabase status
supabase migration list --local
supabase db reset --local
supabase test db
supabase db lint --local
```

The M1 client requires the generated `surface_match_key`, its active owner/key
index, Discovery columns, `last_reviewed_at`, and both transactional RPCs. Do
not use `supabase db push`, repair hosted migration history, or apply dashboard
SQL as a troubleshooting shortcut.

## Unknown mutation outcome

An attempted submission checkpoint means the server may already have committed.
Keep the frozen payload and retry the same submission UUID. An identical replay
must return `replayed` with the one stored item; it must not create another item
or advance scheduling. Clear the local checkpoint only after `created` or
`replayed` is confirmed.

## Submission conflict

A reused submission UUID with different normalized payload is not retryable.
Do not generate a replacement UUID automatically and do not overwrite the
checkpoint. Preserve the draft, capture the opaque submission ID and typed
conflict code, and inspect client draft/revision handling without copying the
learner's fields into logs.

## Legacy grant cutover and rollback

The M1 Flutter client contains no direct `learning_items` create API. The
additive M1 migration deliberately retains the older narrow insert grant during
hosted validation.

Cutover requires separate approval and this order:

1. Verify a clean local reset, pgTAP, repository concurrency, Flutter tests,
   Linux journey, Android journey, builds, review, and QA.
2. Apply reviewed additive Migration 1 to the approved hosted project.
3. Deploy compatible Linux and Android clients.
4. Live-smoke production-completed, production-deferred, idempotent replay,
   and re-encounter paths.
5. Create and review a forward Migration 2 that revokes the narrow legacy
   insert grant.
6. Apply it only with explicit approval, repeat smoke checks, and monitor typed
   metadata-only failures.

Before step 5, rollback means reverting the client while the legacy grant still
works. After revocation, if the client must revert, first apply a reviewed
forward migration restoring only the prior user-authored-column insert grant,
then revert the client. Do not use a destructive down migration or rewrite
historical data.
