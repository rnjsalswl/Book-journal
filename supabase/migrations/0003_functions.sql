-- RPCs the Flutter app calls for anything that needs to be atomic
-- (XP/level math, toggling a reaction, nudging badge progress).

create or replace function public.increment_profile_xp(p_user_id uuid, p_amount int)
returns public.profiles
language plpgsql
security definer set search_path = public
as $$
declare
  result public.profiles;
begin
  update public.profiles
  set xp = xp + p_amount
  where id = p_user_id;

  -- roll xp over into levels, matches the prototype's "다음 레벨 800XP" pacing
  loop
    select * into result from public.profiles where id = p_user_id;
    exit when result.xp < result.xp_to_next;
    update public.profiles
    set xp = xp - result.xp_to_next,
        level = level + 1,
        xp_to_next = result.xp_to_next + 200
    where id = p_user_id;
  end loop;

  select * into result from public.profiles where id = p_user_id;
  return result;
end;
$$;

create or replace function public.toggle_feed_reaction(p_feed_entry_id uuid, p_emoji text default '♥')
returns boolean -- true if now reacted, false if removed
language plpgsql
security definer set search_path = public
as $$
declare
  existing uuid;
begin
  select id into existing
  from public.feed_reactions
  where feed_entry_id = p_feed_entry_id and user_id = auth.uid();

  if existing is not null then
    delete from public.feed_reactions where id = existing;
    return false;
  else
    insert into public.feed_reactions (feed_entry_id, user_id, emoji)
    values (p_feed_entry_id, auth.uid(), p_emoji);
    return true;
  end if;
end;
$$;

create or replace function public.bump_badge_progress(p_badge_key text, p_delta int default 1)
returns public.user_badges
language plpgsql
security definer set search_path = public
as $$
declare
  target public.badges;
  result public.user_badges;
begin
  select * into target from public.badges where key = p_badge_key;
  if target is null then
    raise exception 'unknown badge key: %', p_badge_key;
  end if;

  insert into public.user_badges (user_id, badge_id, progress)
  values (auth.uid(), target.id, greatest(p_delta, 0))
  on conflict (user_id, badge_id)
  do update set progress = public.user_badges.progress + p_delta;

  update public.user_badges
  set unlocked_at = now()
  where user_id = auth.uid() and badge_id = target.id
    and progress >= target.goal and unlocked_at is null;

  select * into result from public.user_badges where user_id = auth.uid() and badge_id = target.id;
  return result;
end;
$$;

create or replace function public.increment_reading_minutes(p_user_id uuid, p_day date, p_minutes int)
returns void
language sql
security definer set search_path = public
as $$
  insert into public.reading_log (user_id, day, minutes)
  values (p_user_id, p_day, p_minutes)
  on conflict (user_id, day) do update set minutes = public.reading_log.minutes + p_minutes;
$$;
