-- Fix duplicate-underline bug: rapid taps raced the client's read-then-write
-- toggle logic, so every tap inserted instead of deleting. Move the toggle
-- to an atomic server-side function and prevent duplicates going forward.

-- 1. Deduplicate existing underline rows, keeping the earliest per position.
delete from public.annotations a
where a.type = 'underline'
  and a.id <> (
    select b.id
    from public.annotations b
    where b.type = 'underline'
      and b.user_id = a.user_id
      and b.book_id = a.book_id
      and b.paragraph_index = a.paragraph_index
      and b.sentence_index = a.sentence_index
    order by b.created_at asc, b.id asc
    limit 1
  );

-- 2. Prevent future duplicates at the data layer.
create unique index if not exists annotations_unique_underline
  on public.annotations (user_id, book_id, paragraph_index, sentence_index)
  where type = 'underline';

-- 3. Atomic toggle: delete-if-exists, else insert. Returns the new state
-- (true = now underlined, false = now removed). Runs as the caller via
-- auth.uid(), so RLS-equivalent scoping is enforced inside the function.
create or replace function public.toggle_underline(
  p_book_id uuid,
  p_paragraph_index int,
  p_sentence_index int
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted boolean;
begin
  delete from public.annotations
  where user_id = auth.uid()
    and book_id = p_book_id
    and paragraph_index = p_paragraph_index
    and sentence_index = p_sentence_index
    and type = 'underline';

  v_deleted := found;

  if v_deleted then
    return false;
  end if;

  insert into public.annotations (user_id, book_id, paragraph_index, sentence_index, type)
  values (auth.uid(), p_book_id, p_paragraph_index, p_sentence_index, 'underline')
  on conflict (user_id, book_id, paragraph_index, sentence_index) where type = 'underline'
  do nothing;

  return true;
end;
$$;

grant execute on function public.toggle_underline(uuid, int, int) to authenticated;
