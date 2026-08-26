alter table public.review_attempts
  add column review_submission_id uuid not null default gen_random_uuid();

alter table public.review_attempts
  add constraint review_attempts_submission_type_key
  unique (user_id, review_submission_id, attempt_type);

alter table public.review_attempts
  drop constraint review_attempts_retrieval_shape_check;

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

alter table public.learning_items
  drop constraint learning_items_content_check;

alter table public.learning_items
  add constraint learning_items_content_check
  check (
    length(btrim(content)) between 1 and 2000
    and content ~ '[^[:space:]]'
  ) not valid;

drop policy "Users can update their learning items"
  on public.learning_items;

revoke insert, update on public.learning_items from authenticated;
grant insert (user_id, kind, content, meaning, context, source)
  on public.learning_items to authenticated;

drop policy "Users can create their review attempts"
  on public.review_attempts;
drop policy "Users can update their review attempts"
  on public.review_attempts;
drop policy "Users can delete their review attempts"
  on public.review_attempts;

revoke insert, update, delete on public.review_attempts from authenticated;

drop function public.complete_review(uuid, text, text);

create function public.complete_review(
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

revoke execute on function public.complete_review(uuid, integer, uuid, text, text)
  from public, anon;
grant execute on function public.complete_review(uuid, integer, uuid, text, text)
  to authenticated;
