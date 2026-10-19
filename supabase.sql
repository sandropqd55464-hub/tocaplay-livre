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

-- Cidade e estado aproximados de cada acesso (só isso; o endereço de internet não é guardado)
alter table public.visits add column if not exists city text;
alter table public.visits add column if not exists region text;
alter table public.visits add column if not exists region_code text;
alter table public.visits add column if not exists country text;

-- =====================================================================
-- ACESSO POR ÁREA (1 registro por aparelho, por área, por dia)
-- =====================================================================
create table if not exists public.area_visits (
  id          bigint generated always as identity primary key,
  device_id   text not null,
  area        text not null,
  created_at  timestamptz not null default now()
);
create index if not exists area_visits_created_idx on public.area_visits (created_at);
alter table public.area_visits enable row level security;

drop policy if exists "qualquer um registra area" on public.area_visits;
create policy "qualquer um registra area" on public.area_visits
  for insert to anon, authenticated with check (true);

-- =====================================================================
-- INSTALAÇÕES DO APP (1 registro por aparelho que instalou)
-- =====================================================================
create table if not exists public.installs (
  id          bigint generated always as identity primary key,
  device_id   text not null,
  platform    text,
  created_at  timestamptz not null default now()
);
create index if not exists installs_created_idx on public.installs (created_at);
alter table public.installs enable row level security;

drop policy if exists "qualquer um registra instalacao" on public.installs;
create policy "qualquer um registra instalacao" on public.installs
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
    'inscritos_rapidos',  (select count(*) from auth.users where coalesce(is_anonymous,false)),
    'com_email',          (select count(*) from auth.users where not coalesce(is_anonymous,false)),
    'instalacoes_total',  (select count(distinct device_id) from installs),
    'instalacoes_7d',     (select count(distinct device_id) from installs where created_at > now() - interval '7 days'),
    'instalacoes_por_tipo', (select coalesce(json_agg(x),'[]') from (
                  select coalesce(platform,'Outro') as tipo, count(distinct device_id) as total
                  from installs group by 1 order by total desc) x),
    'acessos_hoje',       (select count(distinct device_id) from visits where created_at::date = current_date),
    'media_diaria_30d',   (select round(coalesce(avg(n),0)) from (
                              select count(distinct device_id) n from visits
                              where created_at > now() - interval '30 days'
                              group by created_at::date) d),
    'aparelhos_30d',      (select count(distinct device_id) from visits where created_at > now() - interval '30 days'),
    'plays_7d',           (select count(*) from plays where created_at > now() - interval '7 days'),
    'visitantes_total',   (select count(distinct device_id) from visits),
    'visitantes_7d',      (select count(distinct device_id) from visits where created_at > now() - interval '7 days'),
    'por_area', (select coalesce(json_agg(x order by pessoas desc),'[]') from (
                  select area, count(distinct device_id) as pessoas from area_visits
                  where created_at > now() - interval '30 days' group by area) x),
    'area_dia', (select coalesce(json_agg(x),'[]') from (
                  select created_at::date as dia, area, count(distinct device_id) as n from area_visits
                  where created_at > now() - interval '30 days' group by 1,2) x),
    'top_tv', (select coalesce(json_agg(x),'[]') from (
                  select station_name as nome, count(*) as plays from plays
                  where created_at > now() - interval '30 days' and station_id like 'tv:%'
                  group by station_name order by plays desc limit 10) x),
    'top_pod', (select coalesce(json_agg(x),'[]') from (
                  select station_name as nome, count(*) as plays from plays
                  where created_at > now() - interval '30 days' and station_id like 'pod:%'
                  group by station_name order by plays desc limit 10) x),
    'visit_estado', (select coalesce(json_agg(x order by pessoas desc),'[]') from (
                  select region as estado, max(region_code) as uf, count(distinct device_id) as pessoas
                  from visits where created_at > now() - interval '30 days' and country='BR' and region is not null group by 1) x),
    'visit_sem_local', (select count(distinct device_id) from visits
                  where created_at > now() - interval '30 days' and region is null and country is null),
    'visit_cidade', (select coalesce(json_agg(x),'[]') from (
                  select city as cidade, max(region_code) as uf, count(distinct device_id) as pessoas from visits
                  where created_at > now() - interval '30 days' and city is not null and country='BR' group by city order by pessoas desc limit 15) x),
    'visit_exterior', (select count(distinct device_id) from visits
                  where created_at > now() - interval '30 days' and country is not null and country <> 'BR'),
    'por_dia', (select coalesce(json_agg(x order by dia),'[]') from (
                  select created_at::date as dia, count(distinct device_id) as acessos
                  from visits where created_at > now() - interval '30 days'
                  group by 1) x),
    'top_radios', (select coalesce(json_agg(x),'[]') from (
                  select station_name as nome, count(*) as plays from plays
                  where created_at > now() - interval '7 days'
                    and station_id not like 'tv:%' and station_id not like 'pod:%' and station_id not like 'area:%'
                  group by station_name order by plays desc limit 10) x),
    'por_estado', (select coalesce(json_agg(x),'[]') from (
                  select coalesce(state,'Não informado') as estado, count(*) as total
                  from profiles group by 1 order by total desc) x),
    'ultimos', (select coalesce(json_agg(x),'[]') from (
                  select p.name as nome, u.email, p.state as estado, u.created_at as quando,
                         case when coalesce(u.is_anonymous,false) then 'Inscrição rápida' else 'E-mail' end as tipo
                  from auth.users u left join profiles p on p.id = u.id
                  order by u.created_at desc limit 50) x)
  ) into result;
  return result;
end $$;

revoke all on function public.admin_stats() from public, anon;
grant execute on function public.admin_stats() to authenticated;


-- ===== Navegação TocaPlay (Etapa 1): curtidas, comentários, compartilhamentos e denúncias =====
-- Tudo passa por funções seguras; as tabelas ficam fechadas para acesso direto.
create table if not exists nav_likes (vid text not null, device_id text not null, ch text, created_at timestamptz default now(), primary key (vid, device_id));
create table if not exists nav_events (id bigserial primary key, vid text not null, device_id text, ch text, kind text not null check (kind in ('view','share')), created_at timestamptz default now());
create table if not exists nav_comments (id bigserial primary key, vid text not null, device_id text, user_id uuid default auth.uid(), ch text,
  name text not null check (char_length(name) between 1 and 40), body text not null check (char_length(body) between 2 and 500),
  status text not null default 'ok' check (status in ('ok','fila','removido')), motivo text, created_at timestamptz default now());
create table if not exists nav_reports (id bigserial primary key, target text not null, device_id text not null, reason text, created_at timestamptz default now(), unique (target, device_id));
create table if not exists nav_hidden (target text primary key, status text not null default 'fila' check (status in ('fila','removido','ok')), created_at timestamptz default now());
create index if not exists nav_events_vid on nav_events(vid, kind);
create index if not exists nav_events_time on nav_events(created_at);
create index if not exists nav_comments_vid on nav_comments(vid, status);
alter table nav_likes enable row level security;
alter table nav_events enable row level security;
alter table nav_comments enable row level security;
alter table nav_reports enable row level security;
alter table nav_hidden enable row level security;

-- filtro automático: palavrões, ofensas e links (golpes) vão para a fila de revisão
create or replace function public.nav_suspeito(t text) returns text language sql immutable as $$
  select case
    when t ~* '(^|[^a-zà-ú])(porra|caralh\w*|buceta|put[ao]s?|putaria|merda|fod[aeiu]\w*|fdp|viad[oa]\w*|arrombad\w*|vagabund\w*|piranha|cacete|otari[oa]s?|corn[oa]s?|punhet\w*|xoxota|bostas?|vsf|vtnc|pqp|krl|desgra[cç]ad\w*)($|[^a-zà-ú])' then 'palavrão ou ofensa'
    when t ~* '(https?://|www\.|\.com($|[^a-z])|\.br($|[^a-z]))' then 'link'
    else null end
$$;

create or replace function public.nav_info(p_vid text, p_dev text) returns json
language sql security definer set search_path = public as $$
  select json_build_object(
    'hidden',   exists(select 1 from nav_hidden where target = 'v:'||p_vid and status <> 'ok'),
    'likes',    (select count(*) from nav_likes where vid = p_vid),
    'liked',    exists(select 1 from nav_likes where vid = p_vid and device_id = p_dev),
    'views',    (select count(*) from nav_events where vid = p_vid and kind = 'view'),
    'shares',   (select count(*) from nav_events where vid = p_vid and kind = 'share'),
    'comments', (select coalesce(json_agg(x order by x.created_at desc),'[]') from (
                   select c.id, c.name, c.body, c.created_at from nav_comments c
                   where c.vid = p_vid and c.status = 'ok' order by c.created_at desc limit 50) x)
  );
$$;

create or replace function public.nav_like(p_vid text, p_dev text, p_ch text) returns json
language plpgsql security definer set search_path = public as $$
begin
  if exists(select 1 from nav_likes where vid = p_vid and device_id = p_dev) then
    delete from nav_likes where vid = p_vid and device_id = p_dev;
  else
    insert into nav_likes(vid, device_id, ch) values (left(p_vid,64), left(p_dev,64), left(p_ch,80));
  end if;
  return json_build_object('likes', (select count(*) from nav_likes where vid = p_vid),
                           'liked', exists(select 1 from nav_likes where vid = p_vid and device_id = p_dev));
end $$;

create or replace function public.nav_event(p_vid text, p_dev text, p_kind text, p_ch text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_kind not in ('view','share') then return; end if;
  -- 1 visualização por aparelho, por vídeo, por dia
  if p_kind = 'view' and exists(select 1 from nav_events where vid = p_vid and device_id = p_dev and kind = 'view' and created_at > now() - interval '1 day') then return; end if;
  insert into nav_events(vid, device_id, kind, ch) values (left(p_vid,64), left(p_dev,64), p_kind, left(p_ch,80));
end $$;

create or replace function public.nav_comment(p_vid text, p_dev text, p_name text, p_body text, p_ch text) returns json
language plpgsql security definer set search_path = public as $$
declare v_motivo text; v_status text := 'ok';
begin
  -- limite: 5 comentários a cada 10 minutos por aparelho
  if (select count(*) from nav_comments where device_id = p_dev and created_at > now() - interval '10 minutes') >= 5 then
    return json_build_object('status','limite');
  end if;
  -- quem já teve comentário removido perde a aprovação automática
  if exists(select 1 from nav_comments where device_id = p_dev and status = 'removido') then
    v_motivo := 'aparelho com remoção anterior';
  end if;
  v_motivo := coalesce(nav_suspeito(p_name || ' ' || p_body), v_motivo);
  if v_motivo is not null then v_status := 'fila'; end if;
  insert into nav_comments(vid, device_id, ch, name, body, status, motivo)
  values (left(p_vid,64), left(p_dev,64), left(p_ch,80), left(trim(p_name),40), left(trim(p_body),500), v_status, v_motivo);
  return json_build_object('status', v_status);
end $$;

create or replace function public.nav_report(p_target text, p_dev text, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into nav_reports(target, device_id, reason) values (left(p_target,80), left(p_dev,64), left(p_reason,40))
    on conflict (target, device_id) do nothing;
  -- 3 denúncias de aparelhos diferentes: sai do ar na hora e vai para a fila do painel ADM
  if (select count(*) from nav_reports where target = p_target) >= 3 then
    if p_target like 'c:%' then
      update nav_comments set status = 'fila', motivo = '3 denúncias' where id = substr(p_target,3)::bigint and status = 'ok';
    else
      insert into nav_hidden(target) values (p_target)
        on conflict (target) do update set status = 'fila', created_at = now() where nav_hidden.status = 'ok';
    end if;
  end if;
end $$;

-- "Em alta" da aba Geral: últimos 7 dias; compartilhar vale mais que curtir, que vale mais que assistir
create or replace function public.nav_trending() returns json
language sql security definer set search_path = public as $$
  select coalesce(json_agg(x order by x.score desc),'[]') from (
    select vid, max(ch) as ch, sum(p) as score from (
      select vid, ch, 4 as p from nav_events where kind = 'share' and created_at > now() - interval '7 days'
      union all select vid, ch, 1 from nav_events where kind = 'view' and created_at > now() - interval '7 days'
      union all select vid, ch, 3 from nav_likes where created_at > now() - interval '7 days'
    ) t where not exists(select 1 from nav_hidden h where h.target = 'v:'||t.vid and h.status <> 'ok')
    group by vid order by score desc limit 30) x;
$$;

-- Painel ADM: fila de suspeitos e números da Navegação
create or replace function public.admin_nav_fila() returns json
language plpgsql security definer set search_path = public as $$
begin
  if coalesce(auth.jwt()->>'email','') <> 'sandropqd55464@gmail.com' then raise exception 'acesso negado'; end if;
  return json_build_object(
    'comentarios', (select coalesce(json_agg(x),'[]') from (
        select id, vid, ch, name, body, motivo, created_at from nav_comments where status = 'fila' order by created_at desc limit 100) x),
    'videos', (select coalesce(json_agg(x),'[]') from (
        select h.target, h.created_at, (select count(*) from nav_reports r where r.target = h.target) as denuncias
        from nav_hidden h where h.status = 'fila' order by h.created_at desc limit 100) x),
    'totais', json_build_object(
        'curtidas_7d',    (select count(*) from nav_likes where created_at > now() - interval '7 days'),
        'views_7d',       (select count(*) from nav_events where kind = 'view' and created_at > now() - interval '7 days'),
        'shares_7d',      (select count(*) from nav_events where kind = 'share' and created_at > now() - interval '7 days'),
        'comentarios_7d', (select count(*) from nav_comments where created_at > now() - interval '7 days')));
end $$;

create or replace function public.admin_nav_decidir(p_tipo text, p_id text, p_aprovar boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if coalesce(auth.jwt()->>'email','') <> 'sandropqd55464@gmail.com' then raise exception 'acesso negado'; end if;
  if p_tipo = 'comentario' then
    update nav_comments set status = case when p_aprovar then 'ok' else 'removido' end where id = p_id::bigint;
    if p_aprovar then delete from nav_reports where target = 'c:'||p_id; end if;
  else
    update nav_hidden set status = case when p_aprovar then 'ok' else 'removido' end where target = p_id;
    if p_aprovar then delete from nav_reports where target = p_id; end if;
  end if;
end $$;

revoke all on function public.nav_info(text,text), public.nav_like(text,text,text), public.nav_event(text,text,text,text),
  public.nav_comment(text,text,text,text,text), public.nav_report(text,text,text), public.nav_trending() from public;
grant execute on function public.nav_info(text,text), public.nav_like(text,text,text), public.nav_event(text,text,text,text),
  public.nav_comment(text,text,text,text,text), public.nav_report(text,text,text), public.nav_trending() to anon, authenticated;
revoke all on function public.admin_nav_fila(), public.admin_nav_decidir(text,text,boolean) from public, anon;
grant execute on function public.admin_nav_fila(), public.admin_nav_decidir(text,text,boolean) to authenticated;


-- ===== Navegação: filtro forte (versão 28) =====
-- Bloqueia na hora: palavrão, ofensa, conteúdo sexual/obsceno, pornografia, ameaça e discurso de ódio.
-- Funciona mesmo com truques: acentos, letras repetidas (porrraaa), números no lugar de letras (p0rr4) e letras separadas (p.o.r.r.a).
create or replace function public.nav_normaliza(t text) returns text language sql immutable as $$
  select regexp_replace(regexp_replace(
           translate(lower(coalesce(t,'')), 'áàâãäéèêëíìîïóòôõöúùûüç0134578@$!|', 'aaaaaeeeeiiiiooooouuuucoieastbaasii'),
         '[^a-z ]+', ' ', 'g'), '([a-z])\1+', '\1', 'g')
$$;

create or replace function public.nav_proibido(t text) returns boolean language sql immutable as $$
  with n as (select ' ' || regexp_replace(nav_normaliza(t), '\s+', ' ', 'g') || ' ' as s)
  select
    -- palavras inteiras (forma já sem acento e sem letra repetida)
    s ~ ' (pora|poras|caralh[a-z]*|buceta[a-z]*|buseta[a-z]*|puta|putas|puto|putos|putaria[a-z]*|merda[a-z]*|fod[aeio][a-z]*|fdp|vsf|vtnc|pqp|krl|tnc|cu|cus|cuzao|cuzinho|arombad[a-z]*|vagabund[a-z]*|cacete|otari[ao]s?|corn[ao]s?|punhet[a-z]*|xoxot[a-z]*|xerec[a-z]*|xota|bosta[a-z]*|desgracad[a-z]*|viad[ao][a-z]*|traveco[a-z]*|retardad[ao]s?|mongoloide[a-z]*|piroca[a-z]*|pica|picas|siririca[a-z]*|boquete[a-z]*|gozad[ao]s?|gozei|tesao|tesud[ao]s?|safad[ao]s?|sexo|sexual|porn[a-z]*|nudes?|pelad[ao]s? na cam|estupr[a-z]*|pedofil[a-z]*|zoofil[a-z]*|incest[a-z]*|xvideos|pornhub|onlyfans|privacy|sacanagem|bucetinh[a-z]*|transar|trepar|chupa (meu|minha)|vai se f[a-z]*|filh[ao] da puta|vou te matar|te matar|se mata|morre logo|vou te pegar) '
    -- mesmas palavras fortes escritas com letras separadas (p o r r a)
    or replace(s, ' ', '') ~ '(caralh|buceta|buseta|putaria|punhet|xoxot|xerec|piroca|siririca|boquete|pornografia|pornhub|xvideos|onlyfans|estupr|pedofil|zoofil|filhodaputa|filhadaputa|vaisefoder|arombad|desgracad)'
  from n
$$;

create or replace function public.nav_comment(p_vid text, p_dev text, p_name text, p_body text, p_ch text) returns json
language plpgsql security definer set search_path = public as $$
declare v_motivo text; v_status text := 'ok';
begin
  -- limite: 5 comentários a cada 10 minutos por aparelho
  if (select count(*) from nav_comments where device_id = p_dev and created_at > now() - interval '10 minutes') >= 5 then
    return json_build_object('status','limite');
  end if;
  -- bloqueio na hora: não é publicado (fica guardado só como registro, e o aparelho perde a aprovação automática)
  if nav_proibido(p_name || ' ' || p_body) then
    insert into nav_comments(vid, device_id, ch, name, body, status, motivo)
    values (left(p_vid,64), left(p_dev,64), left(p_ch,80), left(trim(p_name),40), left(trim(p_body),500), 'removido', 'bloqueado pelo filtro');
    return json_build_object('status','bloqueado');
  end if;
  -- quem já teve comentário removido ou bloqueado passa pela revisão
  if exists(select 1 from nav_comments where device_id = p_dev and status = 'removido') then
    v_motivo := 'aparelho com bloqueio anterior';
  end if;
  -- link (possível golpe) vai para a revisão
  if p_body ~* '(https?://|www\.|\.com($|[^a-z])|\.br($|[^a-z])|wa\.me|bit\.ly)' then v_motivo := 'link'; end if;
  if v_motivo is not null then v_status := 'fila'; end if;
  insert into nav_comments(vid, device_id, ch, name, body, status, motivo)
  values (left(p_vid,64), left(p_dev,64), left(p_ch,80), left(trim(p_name),40), left(trim(p_body),500), v_status, v_motivo);
  return json_build_object('status', v_status);
end $$;


-- ===== Navegação TocaPlay, Etapa 2: Criadores (versão 29) =====
-- Canal do usuário e posts por link (YouTube, TikTok, Instagram). Aprovação automática com filtro.
create table if not exists creators (user_id uuid primary key references auth.users on delete cascade, name text, avatar text, created_at timestamptz default now());
create table if not exists creator_posts (id bigserial primary key, user_id uuid not null references auth.users on delete cascade,
  platform text not null check (platform in ('youtube','tiktok','instagram')), ref text not null, url text not null,
  title text not null check (char_length(title) between 2 and 120), cat text,
  status text not null default 'ok' check (status in ('ok','fila','removido')), motivo text,
  terms_at timestamptz not null default now(), created_at timestamptz default now(), unique (platform, ref));
create index if not exists creator_posts_user on creator_posts(user_id, created_at desc);
create index if not exists creator_posts_status on creator_posts(status, created_at desc);
alter table creators enable row level security;
alter table creator_posts enable row level security;

-- Publicar por link. Só conta de verdade (Google ou e-mail), com os termos aceitos.
create or replace function public.creator_post(p_url text, p_title text, p_cat text, p_terms boolean) returns json
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_meta jsonb; v_platform text; v_ref text; v_status text := 'ok'; v_motivo text; v_id bigint; v_m text[];
begin
  if v_uid is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then return json_build_object('status','login'); end if;
  if not coalesce(p_terms,false) then return json_build_object('status','termos'); end if;
  if (select count(*) from creator_posts where user_id = v_uid and created_at > now() - interval '1 day') >= 10 then
    return json_build_object('status','limite');
  end if;
  v_m := regexp_match(p_url, '(?:youtu\.be/|youtube\.com/(?:watch\?(?:.*&)?v=|shorts/|live/|embed/))([A-Za-z0-9_-]{11})');
  if v_m is not null then v_platform := 'youtube'; v_ref := v_m[1]; end if;
  if v_ref is null then v_m := regexp_match(p_url, 'tiktok\.com/@[A-Za-z0-9._-]+/video/([0-9]{8,25})');
    if v_m is not null then v_platform := 'tiktok'; v_ref := v_m[1]; end if; end if;
  if v_ref is null then v_m := regexp_match(p_url, 'instagram\.com/(?:reels?|p)/([A-Za-z0-9_-]{5,40})');
    if v_m is not null then v_platform := 'instagram'; v_ref := v_m[1]; end if; end if;
  if v_ref is null then return json_build_object('status','link'); end if;
  if exists(select 1 from creator_posts where platform = v_platform and ref = v_ref) then return json_build_object('status','repetido'); end if;
  if nav_proibido(p_title) then return json_build_object('status','bloqueado'); end if;
  -- quem já teve post removido passa pela revisão
  if exists(select 1 from creator_posts where user_id = v_uid and status = 'removido') then v_status := 'fila'; v_motivo := 'conta com remoção anterior'; end if;
  v_meta := (auth.jwt()->'user_metadata');
  insert into creators(user_id, name, avatar)
    values (v_uid, left(coalesce(v_meta->>'name', v_meta->>'full_name', split_part(auth.jwt()->>'email','@',1), 'Criador'),60), left(coalesce(v_meta->>'avatar_url', v_meta->>'picture'),500))
    on conflict (user_id) do update set name = excluded.name, avatar = coalesce(excluded.avatar, creators.avatar);
  insert into creator_posts(user_id, platform, ref, url, title, cat, status, motivo)
    values (v_uid, v_platform, v_ref, left(p_url,500), left(trim(p_title),120), left(p_cat,40), v_status, v_motivo) returning id into v_id;
  return json_build_object('status', v_status, 'id', v_id);
end $$;

-- Posts públicos para a Navegação (os mais novos primeiro), sem os retirados por denúncia
create or replace function public.creator_feed(p_limit int default 60) returns json
language sql security definer set search_path = public as $$
  select coalesce(json_agg(x),'[]') from (
    select p.id, p.platform, p.ref, p.title, p.cat, p.created_at, c.name, c.avatar
    from creator_posts p join creators c on c.user_id = p.user_id
    where p.status = 'ok' and not exists(select 1 from nav_hidden h where h.target = 'v:p:'||p.id and h.status <> 'ok')
    order by p.created_at desc limit least(coalesce(p_limit,60),200)) x;
$$;

create or replace function public.creator_get(p_id bigint) returns json
language sql security definer set search_path = public as $$
  select row_to_json(x) from (
    select p.id, p.platform, p.ref, p.title, p.cat, p.created_at, c.name, c.avatar
    from creator_posts p join creators c on c.user_id = p.user_id where p.id = p_id and p.status = 'ok') x;
$$;

-- Meu canal: meus posts com o desempenho de cada um
create or replace function public.creator_my() returns json
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then return null; end if;
  return json_build_object(
    'creator', (select row_to_json(c) from creators c where c.user_id = v_uid),
    'posts', (select coalesce(json_agg(x order by x.created_at desc),'[]') from (
      select p.id, p.platform, p.ref, p.title, p.cat, p.status, p.created_at,
        (select count(*) from nav_events e where e.vid = 'p:'||p.id and e.kind = 'view') as views,
        (select count(*) from nav_likes l where l.vid = 'p:'||p.id) as likes,
        (select count(*) from nav_events e where e.vid = 'p:'||p.id and e.kind = 'share') as shares,
        (select count(*) from nav_comments m where m.vid = 'p:'||p.id and m.status = 'ok') as comments
      from creator_posts p where p.user_id = v_uid and p.status <> 'removido') x));
end $$;

create or replace function public.creator_delete(p_id bigint) returns void
language sql security definer set search_path = public as $$
  delete from creator_posts where id = p_id and user_id = auth.uid();
$$;

-- Painel ADM: a fila agora inclui posts de criadores
create or replace function public.admin_nav_fila() returns json
language plpgsql security definer set search_path = public as $$
begin
  if coalesce(auth.jwt()->>'email','') <> 'sandropqd55464@gmail.com' then raise exception 'acesso negado'; end if;
  return json_build_object(
    'comentarios', (select coalesce(json_agg(x),'[]') from (
        select id, vid, ch, name, body, motivo, created_at from nav_comments where status = 'fila' order by created_at desc limit 100) x),
    'videos', (select coalesce(json_agg(x),'[]') from (
        select h.target, h.created_at, (select count(*) from nav_reports r where r.target = h.target) as denuncias
        from nav_hidden h where h.status = 'fila' order by h.created_at desc limit 100) x),
    'posts', (select coalesce(json_agg(x),'[]') from (
        select p.id, p.platform, p.url, p.title, p.motivo, p.created_at, c.name from creator_posts p join creators c on c.user_id = p.user_id
        where p.status = 'fila' order by p.created_at desc limit 100) x),
    'totais', json_build_object(
        'curtidas_7d',    (select count(*) from nav_likes where created_at > now() - interval '7 days'),
        'views_7d',       (select count(*) from nav_events where kind = 'view' and created_at > now() - interval '7 days'),
        'shares_7d',      (select count(*) from nav_events where kind = 'share' and created_at > now() - interval '7 days'),
        'comentarios_7d', (select count(*) from nav_comments where created_at > now() - interval '7 days'),
        'criadores',      (select count(*) from creators),
        'posts_7d',       (select count(*) from creator_posts where created_at > now() - interval '7 days')));
end $$;

create or replace function public.admin_nav_decidir(p_tipo text, p_id text, p_aprovar boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if coalesce(auth.jwt()->>'email','') <> 'sandropqd55464@gmail.com' then raise exception 'acesso negado'; end if;
  if p_tipo = 'comentario' then
    update nav_comments set status = case when p_aprovar then 'ok' else 'removido' end where id = p_id::bigint;
    if p_aprovar then delete from nav_reports where target = 'c:'||p_id; end if;
  elsif p_tipo = 'post' then
    update creator_posts set status = case when p_aprovar then 'ok' else 'removido' end where id = p_id::bigint;
  else
    update nav_hidden set status = case when p_aprovar then 'ok' else 'removido' end where target = p_id;
    if p_aprovar then delete from nav_reports where target = p_id; end if;
  end if;
end $$;

revoke all on function public.creator_post(text,text,text,boolean), public.creator_my(), public.creator_delete(bigint) from public, anon;
grant execute on function public.creator_post(text,text,text,boolean), public.creator_my(), public.creator_delete(bigint) to authenticated;
revoke all on function public.creator_feed(int), public.creator_get(bigint) from public;
grant execute on function public.creator_feed(int), public.creator_get(bigint) to anon, authenticated;


-- ===== Navegação TocaPlay, Etapa 3: enviar vídeo e foto do aparelho (versão 31) =====
-- Arquivos ficam no Supabase Storage (pasta "posts"), no plano grátis (1 GB). Cada pessoa só mexe na própria pasta.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('posts', 'posts', true, 20971520, array['video/mp4','video/webm','video/quicktime','image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "posts_insert_own" on storage.objects;
create policy "posts_insert_own" on storage.objects for insert to authenticated
  with check (bucket_id = 'posts' and (storage.foldername(name))[1] = auth.uid()::text
              and coalesce((auth.jwt()->>'is_anonymous')::boolean, false) = false);
drop policy if exists "posts_delete_own" on storage.objects;
create policy "posts_delete_own" on storage.objects for delete to authenticated
  using (bucket_id = 'posts' and (storage.foldername(name))[1] = auth.uid()::text);

alter table creator_posts drop constraint if exists creator_posts_platform_check;
alter table creator_posts add constraint creator_posts_platform_check check (platform in ('youtube','tiktok','instagram','upload'));
alter table creator_posts add column if not exists kind text default 'video';
alter table creator_posts add column if not exists thumb text;
alter table creator_posts add column if not exists bytes bigint default 0;
alter table creator_posts add column if not exists wm boolean default false;

create or replace function public.creator_upload(p_path text, p_thumb text, p_kind text, p_title text, p_cat text, p_terms boolean, p_bytes bigint, p_wm boolean)
returns json language plpgsql security definer set search_path = public, storage as $$
declare v_uid uuid := auth.uid(); v_meta jsonb; v_status text := 'ok'; v_motivo text; v_id bigint;
begin
  if v_uid is null or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then return json_build_object('status','login'); end if;
  if not coalesce(p_terms,false) then return json_build_object('status','termos'); end if;
  if p_kind not in ('video','foto') then return json_build_object('status','arquivo'); end if;
  if split_part(p_path,'/',1) <> v_uid::text or (p_thumb is not null and split_part(p_thumb,'/',1) <> v_uid::text) then return json_build_object('status','arquivo'); end if;
  if not exists(select 1 from storage.objects where bucket_id = 'posts' and name = p_path) then return json_build_object('status','arquivo'); end if;
  if (select count(*) from creator_posts where user_id = v_uid and platform = 'upload' and created_at > now() - interval '1 day') >= 5 then
    return json_build_object('status','limite');
  end if;
  if (select coalesce(sum(bytes),0) from creator_posts where platform = 'upload') > 950000000 then return json_build_object('status','cheio'); end if;
  if nav_proibido(p_title) then return json_build_object('status','bloqueado'); end if;
  if exists(select 1 from creator_posts where user_id = v_uid and status = 'removido') then v_status := 'fila'; v_motivo := 'conta com remoção anterior'; end if;
  v_meta := (auth.jwt()->'user_metadata');
  insert into creators(user_id, name, avatar)
    values (v_uid, left(coalesce(v_meta->>'name', v_meta->>'full_name', split_part(auth.jwt()->>'email','@',1), 'Criador'),60), left(coalesce(v_meta->>'avatar_url', v_meta->>'picture'),500))
    on conflict (user_id) do update set name = excluded.name, avatar = coalesce(excluded.avatar, creators.avatar);
  insert into creator_posts(user_id, platform, ref, url, title, cat, status, motivo, kind, thumb, bytes, wm)
    values (v_uid, 'upload', p_path, p_path, left(trim(p_title),120), left(p_cat,40), v_status, v_motivo, p_kind, p_thumb, greatest(coalesce(p_bytes,0),0), coalesce(p_wm,false))
    returning id into v_id;
  return json_build_object('status', v_status, 'id', v_id);
end $$;

create or replace function public.creator_feed(p_limit int default 60) returns json
language sql security definer set search_path = public as $$
  select coalesce(json_agg(x),'[]') from (
    select p.id, p.platform, p.ref, p.title, p.cat, p.created_at, p.kind, p.thumb, p.wm, c.name, c.avatar
    from creator_posts p join creators c on c.user_id = p.user_id
    where p.status = 'ok' and not exists(select 1 from nav_hidden h where h.target = 'v:p:'||p.id and h.status <> 'ok')
    order by p.created_at desc limit least(coalesce(p_limit,60),200)) x;
$$;

create or replace function public.creator_get(p_id bigint) returns json
language sql security definer set search_path = public as $$
  select row_to_json(x) from (
    select p.id, p.platform, p.ref, p.title, p.cat, p.created_at, p.kind, p.thumb, p.wm, c.name, c.avatar
    from creator_posts p join creators c on c.user_id = p.user_id where p.id = p_id and p.status = 'ok') x;
$$;

create or replace function public.creator_my() returns json
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then return null; end if;
  return json_build_object(
    'creator', (select row_to_json(c) from creators c where c.user_id = v_uid),
    'posts', (select coalesce(json_agg(x order by x.created_at desc),'[]') from (
      select p.id, p.platform, p.ref, p.title, p.cat, p.status, p.created_at, p.kind, p.thumb, p.wm,
        (select count(*) from nav_events e where e.vid = 'p:'||p.id and e.kind = 'view') as views,
        (select count(*) from nav_likes l where l.vid = 'p:'||p.id) as likes,
        (select count(*) from nav_events e where e.vid = 'p:'||p.id and e.kind = 'share') as shares,
        (select count(*) from nav_comments m where m.vid = 'p:'||p.id and m.status = 'ok') as comments
      from creator_posts p where p.user_id = v_uid and p.status <> 'removido') x));
end $$;

create or replace function public.admin_nav_fila() returns json
language plpgsql security definer set search_path = public as $$
begin
  if coalesce(auth.jwt()->>'email','') <> 'sandropqd55464@gmail.com' then raise exception 'acesso negado'; end if;
  return json_build_object(
    'comentarios', (select coalesce(json_agg(x),'[]') from (
        select id, vid, ch, name, body, motivo, created_at from nav_comments where status = 'fila' order by created_at desc limit 100) x),
    'videos', (select coalesce(json_agg(x),'[]') from (
        select h.target, h.created_at, (select count(*) from nav_reports r where r.target = h.target) as denuncias
        from nav_hidden h where h.status = 'fila' order by h.created_at desc limit 100) x),
    'posts', (select coalesce(json_agg(x),'[]') from (
        select p.id, p.platform, p.url, p.title, p.motivo, p.created_at, p.kind, c.name from creator_posts p join creators c on c.user_id = p.user_id
        where p.status = 'fila' order by p.created_at desc limit 100) x),
    'totais', json_build_object(
        'curtidas_7d',    (select count(*) from nav_likes where created_at > now() - interval '7 days'),
        'views_7d',       (select count(*) from nav_events where kind = 'view' and created_at > now() - interval '7 days'),
        'shares_7d',      (select count(*) from nav_events where kind = 'share' and created_at > now() - interval '7 days'),
        'comentarios_7d', (select count(*) from nav_comments where created_at > now() - interval '7 days'),
        'criadores',      (select count(*) from creators),
        'posts_7d',       (select count(*) from creator_posts where created_at > now() - interval '7 days'),
        'armazenamento_mb', (select round(coalesce(sum(bytes),0)/1000000.0) from creator_posts where platform = 'upload')));
end $$;

revoke all on function public.creator_upload(text,text,text,text,text,boolean,bigint,boolean) from public, anon;
grant execute on function public.creator_upload(text,text,text,text,text,boolean,bigint,boolean) to authenticated;
