-- TocaPlay Livre — banco no Supabase
-- Cole tudo no Supabase → SQL Editor → New query → Run.

-- Favoritas de cada usuário
create table if not exists public.favorites (
  user_id     uuid not null references auth.users(id) on delete cascade,
  station_id  text not null,
  name        text not null,
  stream_url  text not null,
  favicon     text,
  tags        text,
  state       text,
  codec       text,
  bitrate     int,
  created_at  timestamptz not null default now(),
  primary key (user_id, station_id)
);

alter table public.favorites enable row level security;

drop policy if exists "ver as proprias favoritas" on public.favorites;
create policy "ver as proprias favoritas" on public.favorites
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "adicionar as proprias favoritas" on public.favorites;
create policy "adicionar as proprias favoritas" on public.favorites
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "editar as proprias favoritas" on public.favorites;
create policy "editar as proprias favoritas" on public.favorites
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "remover as proprias favoritas" on public.favorites;
create policy "remover as proprias favoritas" on public.favorites
  for delete to authenticated using (auth.uid() = user_id);

-- Estatística: quais rádios mais tocam no seu app (sem dados pessoais)
create table if not exists public.plays (
  id           bigint generated always as identity primary key,
  station_id   text not null,
  station_name text,
  created_at   timestamptz not null default now()
);

alter table public.plays enable row level security;

drop policy if exists "qualquer um registra play" on public.plays;
create policy "qualquer um registra play" on public.plays
  for insert to anon, authenticated with check (true);
-- (ninguém lê pela internet; você vê os dados no painel do Supabase)

-- Ranking das 20 mais tocadas nos últimos 7 dias (rode quando quiser ver):
-- select station_name, count(*) as plays
-- from public.plays where created_at > now() - interval '7 days'
-- group by station_name order by plays desc limit 20;
