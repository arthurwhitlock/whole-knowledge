alter table public.learning_items
  add column part_of_speech text;

alter table public.learning_items
  add constraint learning_items_part_of_speech_check
  check (
    part_of_speech is null
    or (
      length(btrim(part_of_speech)) between 1 and 80
      and part_of_speech ~ '[^[:space:]]'
    )
  ) not valid;

grant insert (part_of_speech) on public.learning_items to authenticated;

create index learning_items_recent_idx
  on public.learning_items (user_id, created_at desc, id)
  where status = 'active';

create index review_attempts_item_history_idx
  on public.review_attempts (user_id, learning_item_id, created_at desc, id);

create index review_attempts_completed_idx
  on public.review_attempts (user_id, created_at desc, learning_item_id)
  where attempt_type = 'production';
