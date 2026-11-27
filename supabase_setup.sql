-- GPX Tracker 서버 DB (Supabase > SQL Editor 에 통째로 붙여넣고 Run)
-- 각 사용자는 자기 데이터만 읽고 쓸 수 있습니다 (Row Level Security).

-- 경로: 목록용 가벼운 정보 + 점 데이터(gzip+base64) 분리 저장
create table if not exists public.gpx_tracks (
  user_id       uuid   not null default auth.uid() references auth.users(id) on delete cascade,
  id            bigint not null,
  name          text   not null,
  year          text,
  total_dist    double precision not null default 0,
  total_ascent  double precision not null default 0,
  total_descent double precision not null default 0,
  overview      jsonb,          -- 전체 경로 보기용 요약선 [[lat,lon], ...]
  user_log      jsonb,          -- 나의 기록(물/식사/특이사항/배낭/지형)
  points        text,           -- 경로 점 데이터(gzip + base64)
  places        jsonb,          -- 경로 주변 주요 지명(봉우리·대피소·고개) 캐시 (OpenStreetMap)
  updated_at    bigint not null,
  primary key (user_id, id)
);

-- 이미 테이블이 있는 경우: 주요 지명 캐시 칸 추가
alter table public.gpx_tracks add column if not exists places jsonb;

create table if not exists public.gpx_waypoints2 (
  user_id    uuid   not null default auth.uid() references auth.users(id) on delete cascade,
  id         bigint not null,
  name       text   not null,
  lat        double precision not null,
  lon        double precision not null,
  updated_at bigint not null,
  primary key (user_id, id)
);

alter table public.gpx_tracks     enable row level security;
alter table public.gpx_waypoints2 enable row level security;

drop policy if exists "own rows" on public.gpx_tracks;
create policy "own rows" on public.gpx_tracks
  for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own rows" on public.gpx_waypoints2;
create policy "own rows" on public.gpx_waypoints2
  for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select, insert, update, delete on public.gpx_tracks     to authenticated;
grant select, insert, update, delete on public.gpx_waypoints2 to authenticated;

-- 주요 지명 공용 저장소: 여러 경로가 함께 쓴다 (OpenStreetMap Overpass에서 받은 봉우리·고개·대피소·쉼터)
create table if not exists public.gpx_places (
  user_id    uuid   not null default auth.uid() references auth.users(id) on delete cascade,
  osm_key    text   not null,   -- 예: node123456
  name       text   not null,
  kind       text   not null,   -- peak / pass / hut / shelter
  ele        integer,
  lat        double precision not null,
  lon        double precision not null,
  updated_at bigint not null,
  primary key (user_id, osm_key)
);
create index if not exists gpx_places_user_lat_lon on public.gpx_places (user_id, lat, lon);

-- 지명을 이미 받아 둔 격자 칸 (위도 0.01° x 경도 0.0125°, 약 1.1km). 받은 칸은 다시 묻지 않는다.
create table if not exists public.gpx_place_cells (
  user_id    uuid   not null default auth.uid() references auth.users(id) on delete cascade,
  cell       text   not null,
  fetched_at bigint not null,
  primary key (user_id, cell)
);

alter table public.gpx_places      enable row level security;
alter table public.gpx_place_cells enable row level security;

drop policy if exists "own rows" on public.gpx_places;
create policy "own rows" on public.gpx_places
  for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "own rows" on public.gpx_place_cells;
create policy "own rows" on public.gpx_place_cells
  for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
