create function public.normalize_surface_match(p_value text)
returns text
language sql
immutable
strict
parallel safe
set search_path = ''
return regexp_replace(
  regexp_replace(
    regexp_replace(
      regexp_replace(
        lower(btrim(p_value)),
        $pattern$[‘’ʼ＇]$pattern$,
        '''',
        'g'
      ),
      $pattern$[‐‑‒–—−﹣－]$pattern$,
      '-',
      'g'
    ),
    $pattern$[[:space:]]*([-'])[[:space:]]*$pattern$,
    E'\\1',
    'g'
  ),
  $pattern$^[[:space:].,!?:;"“”()\[\]{}]+|[[:space:].,!?:;"“”()\[\]{}]+$$pattern$,
  '',
  'g'
);

revoke execute on function public.normalize_surface_match(text)
  from public, anon;
grant execute on function public.normalize_surface_match(text)
  to authenticated;

alter table public.learning_items
  add column first_production text,
  add column last_reviewed_at timestamptz,
  add column discovery_submission_id uuid,
  add column discovery_allow_existing_surface boolean,
  add column surface_match_key text generated always as (
    public.normalize_surface_match(content)
  ) stored;

alter table public.learning_items
  add constraint learning_items_first_production_check
  check (
    first_production is null
    or (
      length(btrim(first_production)) between 1 and 10000
      and first_production ~ '[^[:space:]]'
    )
  ) not valid,
  add constraint learning_items_discovery_shape_check
  check (
    discovery_submission_id is null
    or (
      meaning is not null
      and length(btrim(meaning)) between 1 and 4000
      and meaning ~ '[^[:space:]]'
      and discovery_allow_existing_surface is not null
    )
  ) not valid;

create unique index learning_items_discovery_submission_idx
  on public.learning_items (user_id, discovery_submission_id)
  where discovery_submission_id is not null;

create index learning_items_surface_match_idx
  on public.learning_items (
    user_id,
    surface_match_key,
    created_at desc,
    id
  )
  where status = 'active';

create function public.complete_discovery(
  p_submission_id uuid,
  p_kind text,
  p_content text,
  p_part_of_speech text,
  p_meaning text,
  p_context text,
  p_source text,
  p_first_production text,
  p_allow_existing_surface boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  discovered_at timestamptz := now();
  normalized_content text;
  normalized_part_of_speech text;
  normalized_meaning text;
  normalized_context text;
  normalized_source text;
  normalized_production text;
  match_key text;
  existing_item public.learning_items%rowtype;
  discovered_item public.learning_items%rowtype;
begin
  if caller_id is null then
    raise exception 'An authenticated session is required';
  end if;
  if p_submission_id is null then
    raise exception 'Discovery submission ID is required';
  end if;
  if p_allow_existing_surface is null then
    raise exception 'Allow-existing intent is required';
  end if;

  normalized_content := btrim(p_content);
  normalized_part_of_speech := nullif(lower(btrim(p_part_of_speech)), '');
  normalized_meaning := btrim(p_meaning);
  normalized_context := nullif(btrim(p_context), '');
  normalized_source := nullif(btrim(p_source), '');
  normalized_production := nullif(btrim(p_first_production), '');

  if p_kind not in ('expression', 'vocabulary') then
    raise exception 'Unsupported learning item kind';
  end if;
  if normalized_content is null
    or length(normalized_content) not between 1 and 2000
    or normalized_content !~ '[^[:space:]]' then
    raise exception 'Captured language must be between 1 and 2000 characters';
  end if;
  if normalized_meaning is null
    or length(normalized_meaning) not between 1 and 4000
    or normalized_meaning !~ '[^[:space:]]' then
    raise exception 'Meaning must be between 1 and 4000 characters';
  end if;
  if normalized_part_of_speech is not null
    and length(normalized_part_of_speech) > 80 then
    raise exception 'Part of speech must be at most 80 characters';
  end if;
  if normalized_context is not null and length(normalized_context) > 4000 then
    raise exception 'Context must be at most 4000 characters';
  end if;
  if normalized_source is not null and length(normalized_source) > 1000 then
    raise exception 'Source must be at most 1000 characters';
  end if;
  if normalized_production is not null
    and length(normalized_production) > 10000 then
    raise exception 'First production must be at most 10000 characters';
  end if;

  select item.*
  into existing_item
  from public.learning_items as item
  where item.user_id = caller_id
    and item.discovery_submission_id = p_submission_id;

  if found then
    if existing_item.kind is distinct from p_kind
      or existing_item.content is distinct from normalized_content
      or existing_item.part_of_speech is distinct from normalized_part_of_speech
      or existing_item.meaning is distinct from normalized_meaning
      or existing_item.context is distinct from normalized_context
      or existing_item.source is distinct from normalized_source
      or existing_item.first_production is distinct from normalized_production
      or existing_item.discovery_allow_existing_surface
        is distinct from p_allow_existing_surface then
      raise exception 'Discovery submission ID was already used for different data';
    end if;
    return jsonb_build_object(
      'outcome', 'replayed',
      'item', to_jsonb(existing_item)
    );
  end if;

  match_key := public.normalize_surface_match(normalized_content);
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(caller_id::text || ':' || match_key, 0)
  );

  select item.*
  into existing_item
  from public.learning_items as item
  where item.user_id = caller_id
    and item.surface_match_key = match_key
    and item.status = 'active'
  order by item.created_at desc, item.id
  limit 1;

  if found and not p_allow_existing_surface then
    return jsonb_build_object(
      'outcome', 'existing_surface',
      'item', to_jsonb(existing_item)
    );
  end if;

  insert into public.learning_items (
    user_id,
    kind,
    content,
    part_of_speech,
    meaning,
    context,
    source,
    first_production,
    discovery_submission_id,
    discovery_allow_existing_surface,
    next_review_at
  )
  values (
    caller_id,
    p_kind,
    normalized_content,
    normalized_part_of_speech,
    normalized_meaning,
    normalized_context,
    normalized_source,
    normalized_production,
    p_submission_id,
    p_allow_existing_surface,
    case
      when normalized_production is null then discovered_at
      else discovered_at + interval '24 hours'
    end
  )
  returning * into discovered_item;

  return jsonb_build_object(
    'outcome', 'created',
    'item', to_jsonb(discovered_item)
  );
end;
$$;

revoke execute on function public.complete_discovery(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean
) from public, anon;
grant execute on function public.complete_discovery(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean
) to authenticated;

create or replace function public.complete_review(
  p_learning_item_id uuid,
  p_expected_review_count integer,
  p_submission_id uuid,
  p_response_text text,
  p_rating text
)
returns public.learning_items
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  reviewed_at timestamptz := now();
  interval_until_next_review interval;
  normalized_response text;
  previous_attempt public.review_attempts%rowtype;
  reviewed_item public.learning_items%rowtype;
begin
  if caller_id is null then
    raise exception 'An authenticated session is required';
  end if;
  if p_submission_id is null then
    raise exception 'Review submission ID is required';
  end if;
  if p_expected_review_count is null or p_expected_review_count < 0 then
    raise exception 'Expected review count is invalid';
  end if;

  normalized_response := regexp_replace(
    p_response_text,
    '^[[:space:]]+|[[:space:]]+$',
    '',
    'g'
  );
  if normalized_response is null
    or length(normalized_response) not between 1 and 10000 then
    raise exception 'Production response must be between 1 and 10000 characters';
  end if;

  interval_until_next_review := case p_rating
    when 'again' then interval '10 minutes'
    when 'hard' then interval '1 day'
    when 'good' then interval '3 days'
    when 'easy' then interval '7 days'
    else null
  end;
  if interval_until_next_review is null then
    raise exception 'Unsupported review rating';
  end if;

  select attempt.*
  into previous_attempt
  from public.review_attempts as attempt
  where attempt.user_id = caller_id
    and attempt.review_submission_id = p_submission_id
    and attempt.attempt_type = 'production';

  if found then
    if previous_attempt.learning_item_id is distinct from p_learning_item_id
      or previous_attempt.rating is distinct from p_rating
      or previous_attempt.response_text is distinct from normalized_response then
      raise exception 'Review submission ID was already used for different data';
    end if;
    select item.*
    into strict reviewed_item
    from public.learning_items as item
    where item.id = p_learning_item_id
      and item.user_id = caller_id;
    return reviewed_item;
  end if;

  update public.learning_items
  set
    next_review_at = reviewed_at + interval_until_next_review,
    review_count = review_count + 1,
    production_count = production_count + 1,
    last_reviewed_at = reviewed_at,
    updated_at = reviewed_at
  where id = p_learning_item_id
    and user_id = caller_id
    and status = 'active'
    and review_count = p_expected_review_count
  returning * into reviewed_item;

  if not found then
    select attempt.*
    into previous_attempt
    from public.review_attempts as attempt
    where attempt.user_id = caller_id
      and attempt.review_submission_id = p_submission_id
      and attempt.attempt_type = 'production';
    if found
      and previous_attempt.learning_item_id is not distinct from p_learning_item_id
      and previous_attempt.rating is not distinct from p_rating
      and previous_attempt.response_text is not distinct from normalized_response then
      select item.*
      into strict reviewed_item
      from public.learning_items as item
      where item.id = p_learning_item_id
        and item.user_id = caller_id;
      return reviewed_item;
    end if;
    raise exception 'Learning item changed or is unavailable';
  end if;

  insert into public.review_attempts (
    user_id,
    learning_item_id,
    review_submission_id,
    attempt_type,
    rating,
    response_text,
    created_at
  )
  values
    (
      caller_id,
      p_learning_item_id,
      p_submission_id,
      'retrieval',
      null,
      null,
      reviewed_at
    ),
    (
      caller_id,
      p_learning_item_id,
      p_submission_id,
      'production',
      p_rating,
      normalized_response,
      reviewed_at
    );

  return reviewed_item;
end;
$$;
