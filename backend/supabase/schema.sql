-- ============================================================
-- Jalankan file ini di Supabase Dashboard → SQL Editor → New Query
-- ============================================================

create table if not exists warnings (
  id uuid primary key default gen_random_uuid(),
  guild_id text not null,
  user_id text not null,
  reason text not null,
  moderator_id text not null,
  created_at timestamptz not null default now()
);

create table if not exists mod_actions (
  id uuid primary key default gen_random_uuid(),
  guild_id text not null,
  action_type text not null,           -- warn | kick | ban | mute | unmute | clearwarnings | auto-mute-spam
  target_id text not null,
  target_tag text,
  moderator_id text not null,
  moderator_tag text,
  reason text,
  source text default 'bot',           -- 'bot' (slash command) atau 'mobile' (dari app)
  created_at timestamptz not null default now()
);

create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  guild_id text not null,
  discord_event_id text,
  title text not null,
  description text,
  channel_id text,
  location text,
  cover_url text,
  start_time timestamptz not null,
  end_time timestamptz,
  is_recurring boolean default false,
  recurrence_rule text,
  created_by text not null,
  created_at timestamptz not null default now()
);

create table if not exists event_rsvps (
  event_id uuid references events(id) on delete cascade,
  user_id text not null,
  user_tag text,
  status text default 'going',         -- going | maybe | declined
  responded_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

create table if not exists devices (
  fcm_token text primary key,
  guild_id text not null,
  admin_user_id text not null,
  platform text default 'android',
  registered_at timestamptz not null default now()
);

-- ============================================================
-- Row Level Security: aktifkan, hanya service_role (backend/bot)
-- yang boleh tulis. Admin yang login (anon key + Supabase Auth)
-- hanya boleh BACA data guild mereka sendiri.
-- ============================================================

alter table warnings enable row level security;
alter table mod_actions enable row level security;
alter table events enable row level security;
alter table event_rsvps enable row level security;
alter table devices enable row level security;

-- Baca: siapa saja yang sudah login (authenticated) boleh SELECT.
-- Ini cukup untuk 1 server; kalau nanti multi-server, tambahkan
-- pengecekan guild_id terhadap tabel keanggotaan admin.
create policy "Authenticated users can read warnings" on warnings
  for select using (auth.role() = 'authenticated');

create policy "Authenticated users can read mod_actions" on mod_actions
  for select using (auth.role() = 'authenticated');

create policy "Authenticated users can read events" on events
  for select using (auth.role() = 'authenticated');

create policy "Authenticated users can read event_rsvps" on event_rsvps
  for select using (auth.role() = 'authenticated');

-- Tulis: HANYA lewat service_role key (dipakai backend/bot),
-- jadi sengaja TIDAK dibuatkan policy INSERT/UPDATE/DELETE untuk
-- authenticated — service_role otomatis bypass RLS.

-- Index untuk query yang sering dipakai dashboard
create index if not exists idx_warnings_guild_user on warnings(guild_id, user_id);
create index if not exists idx_mod_actions_guild_created on mod_actions(guild_id, created_at desc);
create index if not exists idx_events_guild_start on events(guild_id, start_time);
