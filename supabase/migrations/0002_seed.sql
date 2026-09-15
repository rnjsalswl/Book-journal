-- Demo catalog data, mirrors the Claude Design prototype so the app looks
-- the same on a freshly-created Supabase project. Safe to skip in prod.

insert into public.books (id, title, author, category, color, total_pages) values
  ('00000000-0000-0000-0000-000000000001', '모래의 도시', '김윤', 'novel', '#8c491a', 312),
  ('00000000-0000-0000-0000-000000000002', '목요일의 편지', '정하나', 'novel', '#56633f', 306),
  ('00000000-0000-0000-0000-000000000003', '고요한 빛', '한서진', 'essay', '#728157', 210),
  ('00000000-0000-0000-0000-000000000004', '우주보다 작은 것들', '임도윤', 'sf', '#474238', 180),
  ('00000000-0000-0000-0000-000000000005', '달과 우표', '서지오', 'poem', '#c67139', 96),
  ('00000000-0000-0000-0000-000000000006', '밀물 관찰기', '노은재', 'new', '#643312', 240)
on conflict (id) do nothing;

insert into public.badges (key, name, description, color, goal) values
  ('library_wanderer', '서관 산책자', '3층 모든 서가를 둘러봤다', '#c67139', 1),
  ('hundred_underlines', '밑줄 백 개', '밑줄 100개 모으기', '#8fa073', 100),
  ('exchange_diary_4weeks', '교환일기 4주', '모임에서 4주 연속 한 줄 남기기', '#ffc6a5', 4),
  ('night_pass', '야간 열람증', '자정 이후 30분 읽기', '#c0b6a5', 1)
on conflict (key) do nothing;
