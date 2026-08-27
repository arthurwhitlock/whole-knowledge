begin;

create extension if not exists pgtap with schema extensions;

select plan(66);

select has_table('public', 'learning_items', 'learning_items exists');
select has_table('public', 'review_attempts', 'review_attempts exists');
select has_column(
  'public',
  'learning_items',
  'part_of_speech',
  'learning items can preserve a selected part of speech'
);
select ok(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.learning_items'::regclass
      and conname = 'learning_items_part_of_speech_check'
  ),
  'part of speech has a length and nonblank constraint'
);
select ok(
  not (
    select convalidated
    from pg_catalog.pg_constraint
    where conrelid = 'public.learning_items'::regclass
      and conname = 'learning_items_part_of_speech_check'
  ),
  'part of speech hardening preserves legacy rows'
);
select ok(
  has_column_privilege(
    'authenticated',
    'public.learning_items',
    'part_of_speech',
    'insert'
  ),
  'authenticated capture can set part of speech'
);
select ok(
  to_regclass('public.learning_items_recent_idx') is not null,
  'recent learning items have a bounded read index'
);
select ok(
  to_regclass('public.review_attempts_item_history_idx') is not null,
  'item history has a paginated read index'
);
select ok(
  to_regclass('public.review_attempts_completed_idx') is not null,
  'completed-today reads have a production-attempt index'
);
select ok(
  (
    select relrowsecurity
    from pg_catalog.pg_class
    where oid = 'public.learning_items'::regclass
  ),
  'learning_items has RLS enabled'
);
select ok(
  (
    select relrowsecurity
    from pg_catalog.pg_class
    where oid = 'public.review_attempts'::regclass
  ),
  'review_attempts has RLS enabled'
);
select ok(
  exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.review_attempts'::regclass
      and conname = 'review_attempts_submission_type_key'
  ),
  'review submissions have a database uniqueness guard'
);
select ok(
  not (
    select convalidated
    from pg_catalog.pg_constraint
    where conrelid = 'public.review_attempts'::regclass
      and conname = 'review_attempts_shape_check'
  ),
  'the stricter attempt shape preserves permissible legacy rows'
);
select ok(
  not (
    select convalidated
    from pg_catalog.pg_constraint
    where conrelid = 'public.learning_items'::regclass
      and conname = 'learning_items_content_check'
  ),
  'the stricter content check preserves permissible legacy rows'
);
select ok(
  (
    select prosecdef
    from pg_catalog.pg_proc
    where oid = 'public.complete_review(uuid,integer,uuid,text,text)'::regprocedure
  ),
  'complete_review uses SECURITY DEFINER'
);
select is(
  (
    select proconfig
    from pg_catalog.pg_proc
    where oid = 'public.complete_review(uuid,integer,uuid,text,text)'::regprocedure
  ),
  array['search_path=""']::text[],
  'complete_review has an empty search_path'
);
select is(
  (
    select pg_catalog.pg_get_userbyid(proowner)
    from pg_catalog.pg_proc
    where oid = 'public.complete_review(uuid,integer,uuid,text,text)'::regprocedure
  ),
  'postgres',
  'complete_review is owned by the trusted migration role'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.complete_review(uuid,integer,uuid,text,text)',
    'execute'
  ),
  'anonymous callers cannot execute complete_review'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.complete_review(uuid,integer,uuid,text,text)',
    'execute'
  ),
  'authenticated callers can execute complete_review'
);

insert into auth.users (id, aud, role, email, created_at, updated_at)
values
  (
    '10000000-0000-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'review-user-one@example.test',
    now(),
    now()
  ),
  (
    '20000000-0000-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'review-user-two@example.test',
    now(),
    now()
  );

insert into public.learning_items (id, user_id, kind, content)
values
  (
    '11000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000001',
    'expression',
    'prendre son temps'
  ),
  (
    '22000000-0000-4000-8000-000000000002',
    '20000000-0000-4000-8000-000000000002',
    'vocabulary',
    'doch'
  );

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000001',
  true
);

select lives_ok(
  $$
    insert into public.learning_items (user_id, kind, content)
    values
      (
        '10000000-0000-4000-8000-000000000001',
        'vocabulary',
        'pourtant'
      ),
      (
        '10000000-0000-4000-8000-000000000001',
        'expression',
        'hard interval fixture'
      ),
      (
        '10000000-0000-4000-8000-000000000001',
        'expression',
        'easy interval fixture'
      ),
      (
        '10000000-0000-4000-8000-000000000001',
        'expression',
        'rollback fixture'
      )
  $$,
  'an authenticated user can capture an owned item'
);

select throws_ok(
  $$
    insert into public.learning_items (user_id, kind, content)
    values (
      '20000000-0000-4000-8000-000000000002',
      'vocabulary',
      'spoofed owner'
    )
  $$
);
select throws_ok(
  $$
    insert into public.learning_items (
      user_id,
      kind,
      content,
      part_of_speech
    )
    values (
      '10000000-0000-4000-8000-000000000001',
      'vocabulary',
      'invalid part of speech',
      E'\t\n'
    )
  $$
);
select throws_ok(
  $$
    insert into public.learning_items (user_id, kind, content)
    values (
      '10000000-0000-4000-8000-000000000001',
      'vocabulary',
      E'\t\n\r'
    )
  $$
);

select is(
  (select count(*) from public.learning_items),
  5::bigint,
  'SELECT exposes only the caller owned items'
);

select throws_ok(
  $$
    update public.learning_items
    set review_count = 999
    where id = '11000000-0000-4000-8000-000000000001'
  $$
);

select throws_ok(
  $$
    update public.learning_items
    set content = 'cross-user mutation'
    where id = '22000000-0000-4000-8000-000000000002'
  $$
);

select throws_ok(
  $$
    insert into public.review_attempts (
      user_id,
      learning_item_id,
      attempt_type,
      rating,
      response_text
    )
    values (
      '10000000-0000-4000-8000-000000000001',
      '11000000-0000-4000-8000-000000000001',
      'production',
      'easy',
      'fabricated history'
    )
  $$
);

select throws_ok(
  $$
    select public.complete_review(
      '22000000-0000-4000-8000-000000000002',
      0,
      '30000000-0000-4000-8000-000000000003',
      'cross-owner attempt',
      'good'
    )
  $$
);

select lives_ok(
  $$
    select public.complete_review(
      '11000000-0000-4000-8000-000000000001',
      0,
      '40000000-0000-4000-8000-000000000004',
      '  Je prends mon temps.  ',
      'good'
    )
  $$,
  'complete_review records an owned review atomically'
);

select is(
  (
    select review_count
    from public.learning_items
    where id = '11000000-0000-4000-8000-000000000001'
  ),
  1,
  'complete_review increments review_count once'
);
select is(
  (
    select production_count
    from public.learning_items
    where id = '11000000-0000-4000-8000-000000000001'
  ),
  1,
  'complete_review increments production_count once'
);
select is(
  (
    select next_review_at
    from public.learning_items
    where id = '11000000-0000-4000-8000-000000000001'
  ),
  now() + interval '3 days',
  'Good schedules exactly three days from the transaction instant'
);
select is(
  (
    select count(*)
    from public.review_attempts
    where learning_item_id = '11000000-0000-4000-8000-000000000001'
  ),
  2::bigint,
  'complete_review creates exactly two attempt rows'
);
select is(
  (
    select response_text
    from public.review_attempts
    where learning_item_id = '11000000-0000-4000-8000-000000000001'
      and attempt_type = 'production'
  ),
  'Je prends mon temps.',
  'the production response is normalized'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-4000-8000-000000000002',
  true
);
select is(
  (select count(*) from public.review_attempts),
  0::bigint,
  'attempt history is isolated from other users'
);
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000001',
  true
);

select throws_ok(
  $$
    update public.review_attempts
    set response_text = 'rewritten history'
    where learning_item_id = '11000000-0000-4000-8000-000000000001'
      and attempt_type = 'production'
  $$
);
select throws_ok(
  $$
    delete from public.review_attempts
    where learning_item_id = '11000000-0000-4000-8000-000000000001'
  $$
);

select lives_ok(
  $$
    select public.complete_review(
      '11000000-0000-4000-8000-000000000001',
      0,
      '40000000-0000-4000-8000-000000000004',
      'Je prends mon temps.',
      'good'
    )
  $$,
  'an identical replay succeeds idempotently'
);
select is(
  (
    select review_count
    from public.learning_items
    where id = '11000000-0000-4000-8000-000000000001'
  ),
  1,
  'an identical replay does not increment review_count'
);
select is(
  (
    select production_count
    from public.learning_items
    where id = '11000000-0000-4000-8000-000000000001'
  ),
  1,
  'an identical replay does not increment production_count'
);
select is(
  (
    select count(*)
    from public.review_attempts
    where learning_item_id = '11000000-0000-4000-8000-000000000001'
  ),
  2::bigint,
  'an identical replay does not duplicate attempts'
);

select throws_ok(
  $$
    select public.complete_review(
      '11000000-0000-4000-8000-000000000001',
      1,
      '40000000-0000-4000-8000-000000000004',
      'different payload',
      'good'
    )
  $$
);
select throws_ok(
  $$
    select public.complete_review(
      '11000000-0000-4000-8000-000000000001',
      0,
      'b0000000-0000-4000-8000-00000000000b',
      'stale counter response',
      'hard'
    )
  $$
);
select throws_ok(
  $$
    select public.complete_review(
      '11000000-0000-4000-8000-000000000001',
      1,
      '50000000-0000-4000-8000-000000000005',
      '   ',
      'easy'
    )
  $$
);
select throws_ok(
  $$
    select public.complete_review(
      '11000000-0000-4000-8000-000000000001',
      1,
      '51000000-0000-4000-8000-000000000005',
      E'\t\n\r',
      'easy'
    )
  $$
);
select throws_ok(
  $$
    select public.complete_review(
      '11000000-0000-4000-8000-000000000001',
      1,
      '60000000-0000-4000-8000-000000000006',
      'valid response',
      'unsupported'
    )
  $$
);
select is(
  (
    select review_count
    from public.learning_items
    where id = '11000000-0000-4000-8000-000000000001'
  ),
  1,
  'invalid calls leave review_count unchanged'
);
select is(
  (
    select count(*)
    from public.review_attempts
    where learning_item_id = '11000000-0000-4000-8000-000000000001'
  ),
  2::bigint,
  'invalid calls leave attempt history unchanged'
);

reset role;
insert into public.review_attempts (
  user_id,
  learning_item_id,
  review_submission_id,
  attempt_type,
  rating,
  response_text
)
select
  '10000000-0000-4000-8000-000000000001',
  id,
  'f0000000-0000-4000-8000-00000000000f',
  'retrieval',
  null,
  null
from public.learning_items
where content = 'rollback fixture';
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000001',
  true
);
select throws_like(
  $$
    select public.complete_review(
      (
        select id from public.learning_items
        where content = 'rollback fixture'
      ),
      0,
      'f0000000-0000-4000-8000-00000000000f',
      'This insert must collide.',
      'good'
    )
  $$,
  '%review_attempts_submission_type_key%',
  'the rollback fixture fails after the item update at attempt insertion'
);
select is(
  (
    select review_count from public.learning_items
    where content = 'rollback fixture'
  ),
  0,
  'an attempt insert failure rolls back review_count'
);
select is(
  (
    select production_count from public.learning_items
    where content = 'rollback fixture'
  ),
  0,
  'an attempt insert failure rolls back production_count'
);
select is(
  (
    select next_review_at from public.learning_items
    where content = 'rollback fixture'
  ),
  now(),
  'an attempt insert failure rolls back scheduling'
);
select is(
  (
    select count(*) from public.review_attempts
    where learning_item_id = (
      select id from public.learning_items
      where content = 'rollback fixture'
    )
  ),
  1::bigint,
  'an attempt insert failure leaves history unchanged'
);

reset role;
alter table public.review_attempts
  drop constraint review_attempts_shape_check;
insert into public.review_attempts (
  user_id,
  learning_item_id,
  review_submission_id,
  attempt_type,
  rating,
  response_text
)
select
  '10000000-0000-4000-8000-000000000001',
  id,
  'f1000000-0000-4000-8000-00000000000f',
  'production',
  null,
  null
from public.learning_items
where content = 'rollback fixture';
alter table public.review_attempts
  add constraint review_attempts_shape_check
  check (
    (
      attempt_type = 'retrieval'
      and rating is null
      and response_text is null
    )
    or
    (
      attempt_type = 'production'
      and rating is not null
      and response_text is not null
      and length(btrim(response_text)) between 1 and 10000
      and response_text ~ '[^[:space:]]'
    )
  ) not valid;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000001',
  true
);
select throws_like(
  $$
    select public.complete_review(
      (
        select id from public.learning_items
        where content = 'rollback fixture'
      ),
      0,
      'f1000000-0000-4000-8000-00000000000f',
      'A valid new response.',
      'good'
    )
  $$,
  '%already used for different data%',
  'a legacy null production row cannot masquerade as an identical replay'
);

select lives_ok(
  $$
    select public.complete_review(
      (
        select id from public.learning_items
        where content = 'pourtant'
      ),
      0,
      '80000000-0000-4000-8000-000000000008',
      'Encore une fois.',
      'again'
    )
  $$,
  'Again is accepted'
);
select is(
  (
    select next_review_at
    from public.learning_items
    where content = 'pourtant'
  ),
  now() + interval '10 minutes',
  'Again schedules exactly ten minutes from the transaction instant'
);
select lives_ok(
  $$
    select public.complete_review(
      (
        select id from public.learning_items
        where content = 'hard interval fixture'
      ),
      0,
      '90000000-0000-4000-8000-000000000009',
      'A difficult response.',
      'hard'
    )
  $$,
  'Hard is accepted'
);
select is(
  (
    select next_review_at
    from public.learning_items
    where content = 'hard interval fixture'
  ),
  now() + interval '1 day',
  'Hard schedules exactly one day from the transaction instant'
);
select lives_ok(
  $$
    select public.complete_review(
      (
        select id from public.learning_items
        where content = 'easy interval fixture'
      ),
      0,
      'a0000000-0000-4000-8000-00000000000a',
      'An easy response.',
      'easy'
    )
  $$,
  'Easy is accepted'
);
select is(
  (
    select next_review_at
    from public.learning_items
    where content = 'easy interval fixture'
  ),
  now() + interval '7 days',
  'Easy schedules exactly seven days from the transaction instant'
);

select lives_ok(
  $$
    delete from public.learning_items
    where id = '22000000-0000-4000-8000-000000000002'
  $$,
  'deleting another user item is safely filtered by RLS'
);
reset role;
select is(
  (
    select count(*)
    from public.learning_items
    where id = '22000000-0000-4000-8000-000000000002'
  ),
  1::bigint,
  'the other user item was not deleted'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000001',
  true
);
select lives_ok(
  $$
    delete from public.learning_items
    where id = '11000000-0000-4000-8000-000000000001'
  $$,
  'a user can delete an owned learning item'
);
reset role;
select is(
  (
    select count(*)
    from public.review_attempts
    where learning_item_id = '11000000-0000-4000-8000-000000000001'
  ),
  0::bigint,
  'deleting an item cascades its attempt history'
);

set local role authenticated;
select set_config('request.jwt.claims', '{}', true);
select set_config('request.jwt.claim.sub', '', true);
select is(
  (select count(*) from public.learning_items),
  0::bigint,
  'an authenticated role without a user identity sees no rows'
);
select throws_ok(
  $$
    select public.complete_review(
      '22000000-0000-4000-8000-000000000002',
      0,
      '70000000-0000-4000-8000-000000000007',
      'missing identity',
      'again'
    )
  $$
);
reset role;

select * from finish();
rollback;
