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
