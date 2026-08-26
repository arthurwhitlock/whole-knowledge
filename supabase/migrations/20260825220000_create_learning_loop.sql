create table public.learning_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null,
  content text not null,
  meaning text,
  context text,
  source text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  next_review_at timestamptz not null default now(),
  review_count integer not null default 0,
  production_count integer not null default 0,
  status text not null default 'active',
  constraint learning_items_kind_check
    check (kind in ('expression', 'vocabulary')),
  constraint learning_items_content_check
    check (length(btrim(content)) between 1 and 2000),
  constraint learning_items_meaning_check
    check (meaning is null or length(meaning) <= 4000),
  constraint learning_items_context_check
    check (context is null or length(context) <= 4000),
  constraint learning_items_source_check
    check (source is null or length(source) <= 1000),
  constraint learning_items_review_count_check check (review_count >= 0),
  constraint learning_items_production_count_check
    check (production_count >= 0),
  constraint learning_items_status_check check (status in ('active', 'archived')),
  constraint learning_items_id_user_id_key unique (id, user_id)
);

create table public.review_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  learning_item_id uuid not null,
  attempt_type text not null,
  rating text,
  response_text text,
  created_at timestamptz not null default now(),
  constraint review_attempts_learning_item_owner_fkey
    foreign key (learning_item_id, user_id)
    references public.learning_items (id, user_id)
    on delete cascade,
  constraint review_attempts_attempt_type_check
    check (attempt_type in ('retrieval', 'production')),
  constraint review_attempts_rating_check
    check (rating is null or rating in ('again', 'hard', 'good', 'easy')),
  constraint review_attempts_response_text_check
    check (response_text is null or length(response_text) <= 10000),
  constraint review_attempts_retrieval_shape_check
    check (
      attempt_type = 'production'
      or (rating is null and response_text is null)
    )
);

create index learning_items_user_id_idx
  on public.learning_items (user_id);
create index learning_items_due_idx
  on public.learning_items (user_id, next_review_at)
  where status = 'active';
create index review_attempts_user_id_idx
  on public.review_attempts (user_id);
create index review_attempts_learning_item_id_idx
  on public.review_attempts (learning_item_id);

alter table public.learning_items enable row level security;
alter table public.review_attempts enable row level security;

create policy "Users can read their learning items"
  on public.learning_items for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can create their learning items"
  on public.learning_items for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update their learning items"
  on public.learning_items for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete their learning items"
  on public.learning_items for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can read their review attempts"
  on public.review_attempts for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can create their review attempts"
  on public.review_attempts for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update their review attempts"
  on public.review_attempts for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete their review attempts"
  on public.review_attempts for delete
  to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.learning_items to authenticated;
grant select, insert, update, delete on public.review_attempts to authenticated;

create or replace function public.complete_review(
  p_learning_item_id uuid,
  p_response_text text,
  p_rating text
)
returns public.learning_items
language plpgsql
security invoker
set search_path = ''
as $$
declare
  reviewed_at timestamptz := now();
  interval_until_next_review interval;
  reviewed_item public.learning_items%rowtype;
begin
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

  update public.learning_items
  set
    next_review_at = reviewed_at + interval_until_next_review,
    review_count = review_count + 1,
    production_count = production_count + 1,
    updated_at = reviewed_at
  where id = p_learning_item_id
    and user_id = (select auth.uid())
    and status = 'active'
  returning * into reviewed_item;

  if not found then
    raise exception 'Learning item is unavailable';
  end if;

  insert into public.review_attempts (
    user_id,
    learning_item_id,
    attempt_type,
    rating,
    response_text,
    created_at
  )
  values
    (
      (select auth.uid()),
      p_learning_item_id,
      'retrieval',
      null,
      null,
      reviewed_at
    ),
    (
      (select auth.uid()),
      p_learning_item_id,
      'production',
      p_rating,
      nullif(btrim(p_response_text), ''),
      reviewed_at
    );

  return reviewed_item;
end;
$$;

revoke execute on function public.complete_review(uuid, text, text)
  from public, anon;
grant execute on function public.complete_review(uuid, text, text)
  to authenticated;
