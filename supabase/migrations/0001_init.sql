-- Pixel Book Journal — initial schema
-- Run against a fresh Supabase project (SQL editor or `supabase db push`).

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '이름 없는 독자',
  level int not null default 1,
  xp int not null default 0,
  xp_to_next int not null default 200,
  floor_access int not null default 1,
  avatar_seed text not null default 'player',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles are readable by any authenticated user"
  on public.profiles for select
  using (auth.role() = 'authenticated');

create policy "profiles are editable by their owner"
  on public.profiles for update
  using (auth.uid() = id);

-- create a profile row automatically whenever a new auth user signs up
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', '이름 없는 독자'));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------------
-- groups ("수요일의 책상" style exchange-diary circles) + membership
-- ---------------------------------------------------------------------------
create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  current_book_id uuid,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

create table public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

alter table public.groups enable row level security;
alter table public.group_members enable row level security;

create function public.is_group_member(target_group uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.group_members
    where group_id = target_group and user_id = auth.uid()
  );
$$;

create function public.shares_group_with(other_user uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.group_members gm1
    join public.group_members gm2 on gm1.group_id = gm2.group_id
    where gm1.user_id = auth.uid() and gm2.user_id = other_user
  );
$$;

create policy "members can read their groups"
  on public.groups for select
  using (public.is_group_member(id));

create policy "members can create groups"
  on public.groups for insert
  with check (created_by = auth.uid());

create policy "members can read their membership rows"
  on public.group_members for select
  using (public.is_group_member(group_id));

create policy "users can join groups (insert own membership)"
  on public.group_members for insert
  with check (user_id = auth.uid());

create policy "users can leave groups (delete own membership)"
  on public.group_members for delete
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- books (shared catalog)
-- ---------------------------------------------------------------------------
create table public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text not null,
  category text not null, -- novel | essay | sf | poem | new
  color text not null default '#8c491a',
  total_pages int not null default 200,
  created_at timestamptz not null default now()
);

alter table public.books enable row level security;

create policy "books are readable by any authenticated user"
  on public.books for select
  using (auth.role() = 'authenticated');

alter table public.groups
  add constraint groups_current_book_fk foreign key (current_book_id) references public.books (id);

-- ---------------------------------------------------------------------------
-- shelf_entries (per-user reading progress)
-- ---------------------------------------------------------------------------
create table public.shelf_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  book_id uuid not null references public.books (id) on delete cascade,
  status text not null default 'new', -- new | reading | done
  current_page int not null default 0,
  pct int not null default 0,
  shared_group_id uuid references public.groups (id),
  started_at timestamptz,
  finished_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (user_id, book_id)
);

alter table public.shelf_entries enable row level security;

create policy "users read own shelf or shared-group shelf entries"
  on public.shelf_entries for select
  using (
    user_id = auth.uid()
    or (shared_group_id is not null and public.is_group_member(shared_group_id))
  );

create policy "users manage their own shelf entries"
  on public.shelf_entries for insert
  with check (user_id = auth.uid());

create policy "users update their own shelf entries"
  on public.shelf_entries for update
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- annotations (underline / bubble / postit) + replies
-- ---------------------------------------------------------------------------
create table public.annotations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  book_id uuid not null references public.books (id) on delete cascade,
  paragraph_index int not null,
  sentence_index int not null,
  type text not null, -- underline | bubble | postit
  text text,
  emoji text,
  created_at timestamptz not null default now()
);

create table public.annotation_replies (
  id uuid primary key default gen_random_uuid(),
  annotation_id uuid not null references public.annotations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

alter table public.annotations enable row level security;
alter table public.annotation_replies enable row level security;

create policy "annotations visible to owner or reading-group peers"
  on public.annotations for select
  using (user_id = auth.uid() or public.shares_group_with(user_id));

create policy "users create their own annotations"
  on public.annotations for insert
  with check (user_id = auth.uid());

create policy "users update or delete their own annotations"
  on public.annotations for update
  using (user_id = auth.uid());

create policy "users delete their own annotations"
  on public.annotations for delete
  using (user_id = auth.uid());

create policy "replies visible if parent annotation is visible"
  on public.annotation_replies for select
  using (
    exists (
      select 1 from public.annotations a
      where a.id = annotation_id
        and (a.user_id = auth.uid() or public.shares_group_with(a.user_id))
    )
  );

create policy "users create their own replies"
  on public.annotation_replies for insert
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- feed_entries ("수요일의 책상" exchange diary) + reactions
-- ---------------------------------------------------------------------------
create table public.feed_entries (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  book_id uuid references public.books (id),
  kind text not null, -- 밑줄 | 말풍선 | 포스트잇 | 한 줄
  source_ref text,
  text text not null,
  created_at timestamptz not null default now()
);

create table public.feed_reactions (
  id uuid primary key default gen_random_uuid(),
  feed_entry_id uuid not null references public.feed_entries (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  emoji text not null default '♥',
  created_at timestamptz not null default now(),
  unique (feed_entry_id, user_id)
);

alter table public.feed_entries enable row level security;
alter table public.feed_reactions enable row level security;

create policy "group members read feed entries"
  on public.feed_entries for select
  using (public.is_group_member(group_id));

create policy "group members post feed entries"
  on public.feed_entries for insert
  with check (user_id = auth.uid() and public.is_group_member(group_id));

create policy "group members read reactions"
  on public.feed_reactions for select
  using (
    exists (
      select 1 from public.feed_entries f
      where f.id = feed_entry_id and public.is_group_member(f.group_id)
    )
  );

create policy "group members react"
  on public.feed_reactions for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.feed_entries f
      where f.id = feed_entry_id and public.is_group_member(f.group_id)
    )
  );

-- ---------------------------------------------------------------------------
-- reviews (감상문)
-- ---------------------------------------------------------------------------
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  book_id uuid not null references public.books (id) on delete cascade,
  stars int not null check (stars between 1 and 5),
  moods text[] not null default '{}',
  quote text,
  text text not null,
  scope text not null default 'private', -- private | group | public
  group_id uuid references public.groups (id),
  xp_awarded int not null default 40,
  created_at timestamptz not null default now()
);

alter table public.reviews enable row level security;

create policy "reviews visible per scope"
  on public.reviews for select
  using (
    user_id = auth.uid()
    or scope = 'public'
    or (scope = 'group' and group_id is not null and public.is_group_member(group_id))
  );

create policy "users create their own reviews"
  on public.reviews for insert
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- badges (achievements catalog) + per-user progress
-- ---------------------------------------------------------------------------
create table public.badges (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  name text not null,
  description text not null,
  color text not null default '#c67139',
  goal int not null default 1
);

create table public.user_badges (
  user_id uuid not null references public.profiles (id) on delete cascade,
  badge_id uuid not null references public.badges (id) on delete cascade,
  progress int not null default 0,
  unlocked_at timestamptz,
  primary key (user_id, badge_id)
);

alter table public.badges enable row level security;
alter table public.user_badges enable row level security;

create policy "badges are readable by any authenticated user"
  on public.badges for select
  using (auth.role() = 'authenticated');

create policy "users read their own badge progress"
  on public.user_badges for select
  using (user_id = auth.uid());

create policy "users update their own badge progress"
  on public.user_badges for update
  using (user_id = auth.uid());

create policy "users insert their own badge progress"
  on public.user_badges for insert
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- reading_log (daily minutes, backs the profile heatmap)
-- ---------------------------------------------------------------------------
create table public.reading_log (
  user_id uuid not null references public.profiles (id) on delete cascade,
  day date not null,
  minutes int not null default 0,
  primary key (user_id, day)
);

alter table public.reading_log enable row level security;

create policy "users manage their own reading log"
  on public.reading_log for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- quests (librarian-assigned reading quests)
-- ---------------------------------------------------------------------------
create table public.quests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  book_id uuid references public.books (id),
  status text not null default 'active', -- active | done
  given_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.quests enable row level security;

create policy "users manage their own quests"
  on public.quests for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
