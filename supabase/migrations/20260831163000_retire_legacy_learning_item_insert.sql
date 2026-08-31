revoke insert on table public.learning_items from authenticated;
revoke insert (
  user_id,
  kind,
  content,
  meaning,
  context,
  source,
  part_of_speech
) on table public.learning_items from authenticated;
