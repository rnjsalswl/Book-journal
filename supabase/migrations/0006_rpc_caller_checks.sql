-- 0003의 RPC들은 security definer라 RLS를 건너뛴다.
-- 그런데 p_user_id를 호출자가 마음대로 넘길 수 있고 값 범위 검사도 없어서,
-- 로그인한 아무나 남의 XP·독서시간을 올리거나 배지를 한 번에 달성시킬 수 있었다.
-- 여기서는 함수 시그니처는 그대로 두고(앱 코드 변경 없음)
--   1) 호출자가 본인인지 확인하고
--   2) 한 번에 바꿀 수 있는 값의 범위를 제한한다.

create or replace function public.increment_profile_xp(p_user_id uuid, p_amount int)
returns public.profiles
language plpgsql
security definer set search_path = public
as $$
declare
  result public.profiles;
begin
  if auth.uid() is null or p_user_id is distinct from auth.uid() then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  -- 앱에서 주는 XP는 감상문 40이 최대. 여유를 두고 1~100만 허용
  if p_amount is null or p_amount < 1 or p_amount > 100 then
    raise exception 'invalid xp amount: %', p_amount using errcode = '22023';
  end if;

  update public.profiles
  set xp = xp + p_amount
  where id = p_user_id;

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

create or replace function public.increment_reading_minutes(p_user_id uuid, p_day date, p_minutes int)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if auth.uid() is null or p_user_id is distinct from auth.uid() then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  -- 앱은 1분씩 기록. 한 번에 최대 60분
  if p_minutes is null or p_minutes < 1 or p_minutes > 60 then
    raise exception 'invalid minutes: %', p_minutes using errcode = '22023';
  end if;
  -- 시간대 차이를 감안해 어제~내일만 허용 (과거 기록 조작 방지)
  if p_day is null or p_day < current_date - 1 or p_day > current_date + 1 then
    raise exception 'invalid day: %', p_day using errcode = '22023';
  end if;

  insert into public.reading_log (user_id, day, minutes)
  values (p_user_id, p_day, p_minutes)
  on conflict (user_id, day)
  -- 하루는 1440분을 넘을 수 없음
  do update set minutes = least(public.reading_log.minutes + excluded.minutes, 1440);
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
  if auth.uid() is null then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  -- 한 번에 크게 올려서 배지를 바로 따는 걸 막음
  if p_delta is null or p_delta < 1 or p_delta > 10 then
    raise exception 'invalid delta: %', p_delta using errcode = '22023';
  end if;

  select * into target from public.badges where key = p_badge_key;
  if target is null then
    raise exception 'unknown badge key: %', p_badge_key;
  end if;

  insert into public.user_badges (user_id, badge_id, progress)
  values (auth.uid(), target.id, p_delta)
  on conflict (user_id, badge_id)
  do update set progress = least(public.user_badges.progress + p_delta, target.goal);

  update public.user_badges
  set unlocked_at = now()
  where user_id = auth.uid() and badge_id = target.id
    and progress >= target.goal and unlocked_at is null;

  select * into result from public.user_badges where user_id = auth.uid() and badge_id = target.id;
  return result;
end;
$$;

-- 로그인하지 않은 요청(anon)은 이 함수들을 아예 못 부르게
revoke execute on function public.increment_profile_xp(uuid, int) from public, anon;
revoke execute on function public.increment_reading_minutes(uuid, date, int) from public, anon;
revoke execute on function public.bump_badge_progress(text, int) from public, anon;
revoke execute on function public.toggle_feed_reaction(uuid, text) from public, anon;
grant execute on function public.increment_profile_xp(uuid, int) to authenticated;
grant execute on function public.increment_reading_minutes(uuid, date, int) to authenticated;
grant execute on function public.bump_badge_progress(text, int) to authenticated;
grant execute on function public.toggle_feed_reaction(uuid, text) to authenticated;
