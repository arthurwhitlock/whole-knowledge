begin;

create extension if not exists pgtap with schema extensions;

select plan(42);

select has_function(
  'public',
  'normalize_surface_match',
  array['text'],
  'surface normalization is database-owned'
);
select has_column(
  'public',
  'learning_items',
  'first_production',
  'learning items preserve capture-origin production'
);
select has_column(
  'public',
  'learning_items',
  'last_reviewed_at',
  'learning items project authoritative last-review time'
);
select has_column(
  'public',
  'learning_items',
  'discovery_submission_id',
  'learning items preserve Discovery idempotency keys'
);
select has_column(
  'public',
  'learning_items',
  'discovery_allow_existing_surface',
  'learning items preserve explicit another-sense intent'
);
select has_column(
  'public',
  'learning_items',
  'surface_match_key',
  'learning items generate an exact-surface key'
);
select ok(
  to_regclass('public.learning_items_discovery_submission_idx') is not null,
  'Discovery replay has an owner-scoped unique index'
);
select ok(
  to_regclass('public.learning_items_surface_match_idx') is not null,
  'active exact-surface reads have a covered index'
);
select ok(
  (
    select prosecdef
    from pg_catalog.pg_proc
    where oid = 'public.complete_discovery(uuid,text,text,text,text,text,text,text,boolean)'::regprocedure
  ),
  'complete_discovery uses SECURITY DEFINER'
);
select is(
  (
    select proconfig
    from pg_catalog.pg_proc
    where oid = 'public.complete_discovery(uuid,text,text,text,text,text,text,text,boolean)'::regprocedure
  ),
  array['search_path=""']::text[],
  'complete_discovery has an empty search path'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.complete_discovery(uuid,text,text,text,text,text,text,text,boolean)',
    'execute'
  ),
  'anonymous callers cannot execute complete_discovery'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.complete_discovery(uuid,text,text,text,text,text,text,text,boolean)',
    'execute'
  ),
  'authenticated callers can execute complete_discovery'
);
select is(
  public.normalize_surface_match(' “L’arc!” '),
  'l''arc',
  'curly apostrophes and surrounding punctuation normalize'
);
select is(
  public.normalize_surface_match(' en — route '),
  'en-route',
  'hyphens and adjacent whitespace normalize'
);
select is(
  public.normalize_surface_match(E'discovery  \t concurrency\nfixture'),
  'discovery concurrency fixture',
  'repeated internal whitespace normalizes before locking'
);
select isnt(
  public.normalize_surface_match('records'),
  public.normalize_surface_match('record'),
  'surface matching does not stem'
);

insert into auth.users (id, aud, role, email, created_at, updated_at)
values
  (
    '31000000-0000-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'discovery-user-one@example.test',
    now(),
    now()
  ),
  (
    '32000000-0000-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'discovery-user-two@example.test',
    now(),
    now()
  );

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"31000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '31000000-0000-4000-8000-000000000001',
  true
);

select throws_like(
  $$
    select public.complete_discovery(
      '30000000-0000-4000-8000-000000000000',
      'expression',
      '...',
      null,
      'punctuation only',
      null,
      null,
      null,
      false
    )
  $$,
  '%canonical surface%',
  'punctuation-only content cannot create an empty surface key'
);

select throws_ok(
  $$
    insert into public.learning_items (
      user_id,
      kind,
      content,
      first_production
    ) values (
      '31000000-0000-4000-8000-000000000001',
      'vocabulary',
      'protected production',
      'A client-forged production.'
    )
  $$
);
select is(
  public.complete_discovery(
    '33000000-0000-4000-8000-000000000003',
    'vocabulary',
    '  Record ',
    'Noun',
    '  a stored account ',
    '  meeting ',
    ' conversation ',
    ' I kept a record. ',
    false
  )->>'outcome',
  'created',
  'a new Discovery returns created'
);
select is(
  (select count(*) from public.learning_items where content = 'Record'),
  1::bigint,
  'new Discovery inserts exactly one item'
);
select is(
  (
    select next_review_at
    from public.learning_items
    where content = 'Record'
  ),
  now() + interval '24 hours',
  'first production schedules the first Review in 24 hours'
);
select is(
  (
    select review_count + production_count
    from public.learning_items
    where content = 'Record'
  ),
  0,
  'capture-origin production does not fabricate Review counters'
);
select results_eq(
  $$
    select part_of_speech, meaning, context, source, first_production
    from public.learning_items
    where content = 'Record'
  $$,
  $$ values (
    'noun'::text,
    'a stored account'::text,
    'meeting'::text,
    'conversation'::text,
    'I kept a record.'::text
  ) $$,
  'Discovery normalizes all authored fields'
);
select is(
  (
    select last_reviewed_at
    from public.learning_items
    where content = 'Record'
  ),
  null::timestamptz,
  'a never-reviewed item has no last-review instant'
);
select is(
  public.complete_discovery(
    '33000000-0000-4000-8000-000000000003',
    'vocabulary',
    'Record',
    'noun',
    'a stored account',
    'meeting',
    'conversation',
    'I kept a record.',
    false
  )->>'outcome',
  'replayed',
  'an identical Discovery replay reconciles'
);
select is(
  (select count(*) from public.learning_items where content = 'Record'),
  1::bigint,
  'an identical replay creates no duplicate'
);
select throws_like(
  $$
    select public.complete_discovery(
      '33000000-0000-4000-8000-000000000003',
      'vocabulary',
      'Record',
      'noun',
      'different meaning',
      'meeting',
      'conversation',
      'I kept a record.',
      false
    )
  $$,
  '%already used for different data%',
  'submission reuse with changed payload is rejected'
);
select is(
  public.complete_discovery(
    '34000000-0000-4000-8000-000000000004',
    'vocabulary',
    '“RECORD!”',
    'verb',
    'to preserve information',
    null,
    null,
    null,
    false
  )->>'outcome',
  'existing_surface',
  'a normalized same-surface submission returns the existing item'
);
select is(
  (select count(*) from public.learning_items where surface_match_key = 'record'),
  1::bigint,
  'existing-surface handling creates no duplicate'
);
select is(
  public.complete_discovery(
    '35000000-0000-4000-8000-000000000005',
    'vocabulary',
    'record',
    'verb',
    'to preserve information',
    null,
    null,
    null,
    true
  )->>'outcome',
  'created',
  'explicit Learn another sense permits an additional item'
);
select is(
  (select count(*) from public.learning_items where surface_match_key = 'record'),
  2::bigint,
  'the explicit additional sense preserves both items'
);
select is(
  public.complete_discovery(
    '36000000-0000-4000-8000-000000000006',
    'expression',
    'on the record',
    null,
    'officially',
    null,
    null,
    null,
    false
  )->>'outcome',
  'created',
  'deferred production still creates a Discovery'
);
select is(
  (
    select next_review_at
    from public.learning_items
    where content = 'on the record'
  ),
  now(),
  'deferred production is due immediately'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"32000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '32000000-0000-4000-8000-000000000002',
  true
);
select is(
  public.complete_discovery(
    '37000000-0000-4000-8000-000000000007',
    'vocabulary',
    'record',
    'noun',
    'a stored account',
    null,
    null,
    null,
    false
  )->>'outcome',
  'created',
  'the same surface is isolated by authenticated owner'
);
select is(
  (select count(*) from public.learning_items),
  1::bigint,
  'RLS exposes only the second owner item'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"31000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '31000000-0000-4000-8000-000000000001',
  true
);
select lives_ok(
  $$
    select public.complete_review(
      (
        select id
        from public.learning_items
        where discovery_submission_id = '33000000-0000-4000-8000-000000000003'
      ),
      0,
      '38000000-0000-4000-8000-000000000008',
      'I kept another record.',
      'good'
    )
  $$,
  'the existing Review transaction accepts a discovered item'
);
select is(
  (
    select last_reviewed_at
    from public.learning_items
    where discovery_submission_id = '33000000-0000-4000-8000-000000000003'
  ),
  now(),
  'complete_review writes authoritative last-review time'
);
select lives_ok(
  $$
    select public.complete_review(
      (
        select id
        from public.learning_items
        where discovery_submission_id = '33000000-0000-4000-8000-000000000003'
      ),
      0,
      '38000000-0000-4000-8000-000000000008',
      'I kept another record.',
      'good'
    )
  $$,
  'an identical Review replay remains idempotent'
);
select is(
  (
    select last_reviewed_at
    from public.learning_items
    where discovery_submission_id = '33000000-0000-4000-8000-000000000003'
  ),
  now(),
  'Review replay does not advance last-review time'
);
select throws_ok(
  $$
    update public.learning_items
    set last_reviewed_at = now() - interval '1 year'
    where discovery_submission_id = '33000000-0000-4000-8000-000000000003'
  $$
);

set local role authenticated;
select set_config('request.jwt.claims', '{}', true);
select set_config('request.jwt.claim.sub', '', true);
select throws_like(
  $$
    select public.complete_discovery(
      '39000000-0000-4000-8000-000000000009',
      'vocabulary',
      'anonymous',
      'adjective',
      'unknown',
      null,
      null,
      null,
      false
    )
  $$,
  '%authenticated session is required%',
  'a missing authenticated identity is rejected'
);

reset role;

insert into public.learning_items (user_id, kind, content)
select
  '31000000-0000-4000-8000-000000000001',
  'vocabulary',
  'performance surface ' || series
from generate_series(1, 10000) as series;
analyze public.learning_items;

create function pg_temp.discovery_surface_plan()
returns setof text
language plpgsql
as $$
begin
  return query execute $plan$
    explain (costs off)
    select *
    from public.learning_items
    where user_id = '31000000-0000-4000-8000-000000000001'
      and surface_match_key = 'performance surface 9999'
      and status = 'active'
    order by created_at desc, id
  $plan$;
end;
$$;

select matches(
  (select string_agg(plan_line, E'\n') from pg_temp.discovery_surface_plan() as plan_line),
  'learning_items_surface_match_idx',
  'exact-surface lookup uses its covered index at 10000 rows'
);

select * from finish();
rollback;
