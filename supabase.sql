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

-- =====================================================================
-- CADASTRO DE USUÁRIOS (nome e estado de quem cria conta)
-- =====================================================================
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text,
  state       text,
  created_at  timestamptz not null default now()
);
alter table public.profiles enable row level security;

drop policy if exists "ver o proprio perfil" on public.profiles;
create policy "ver o proprio perfil" on public.profiles
  for select to authenticated using (auth.uid() = id);

-- Cria o perfil automaticamente quando alguém se cadastra
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, state)
  values (new.id, new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'state')
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
-- ACESSOS (1 registro por aparelho por dia, sem dados pessoais)
-- =====================================================================
create table if not exists public.visits (
  id          bigint generated always as identity primary key,
  device_id   text not null,
  created_at  timestamptz not null default now()
);
create index if not exists visits_created_idx on public.visits (created_at);
alter table public.visits enable row level security;

drop policy if exists "qualquer um registra acesso" on public.visits;
create policy "qualquer um registra acesso" on public.visits
  for insert to anon, authenticated with check (true);

-- =====================================================================
-- PAINEL DO DONO — só o e-mail abaixo consegue ver os números
-- =====================================================================
create or replace function public.admin_stats()
returns json language plpgsql security definer set search_path = public as $$
declare result json;
begin
  if coalesce(auth.jwt()->>'email','') <> 'sandropqd55464@gmail.com' then
    raise exception 'acesso negado';
  end if;

  select json_build_object(
    'usuarios_total',     (select count(*) from auth.users),
    'usuarios_7d',        (select count(*) from auth.users where created_at > now() - interval '7 days'),
    'usuarios_hoje',      (select count(*) from auth.users where created_at::date = current_date),
    'acessos_hoje',       (select count(distinct device_id) from visits where created_at::date = current_date),
    'media_diaria_30d',   (select round(coalesce(avg(n),0)) from (
                              select count(distinct device_id) n from visits
                              where created_at > now() - interval '30 days'
                              group by created_at::date) d),
    'aparelhos_30d',      (select count(distinct device_id) from visits where created_at > now() - interval '30 days'),
    'plays_7d',           (select count(*) from plays where created_at > now() - interval '7 days'),
    'por_dia', (select coalesce(json_agg(x order by dia),'[]') from (
                  select created_at::date as dia, count(distinct device_id) as acessos
                  from visits where created_at > now() - interval '30 days'
                  group by 1) x),
    'top_radios', (select coalesce(json_agg(x),'[]') from (
                  select station_name as nome, count(*) as plays from plays
                  where created_at > now() - interval '7 days'
                  group by station_name order by plays desc limit 10) x),
    'por_estado', (select coalesce(json_agg(x),'[]') from (
                  select coalesce(state,'Não informado') as estado, count(*) as total
                  from profiles group by 1 order by total desc) x),
    'ultimos', (select coalesce(json_agg(x),'[]') from (
                  select p.name as nome, u.email, p.state as estado, u.created_at as quando
                  from auth.users u left join profiles p on p.id = u.id
                  order by u.created_at desc limit 50) x)
  ) into result;
  return result;
end $$;

revoke all on function public.admin_stats() from public, anon;
grant execute on function public.admin_stats() to authenticated;
