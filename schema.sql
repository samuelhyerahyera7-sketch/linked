-- ── LINKED · SUPABASE SCHEMA ─────────────────────────────────
-- Run this entire file in the Supabase SQL Editor once:
-- Dashboard → SQL Editor → New Query → paste → Run

-- ── PROFILES ─────────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid references auth.users on delete cascade primary key,
  name          text not null,
  age           integer not null,
  dob           text,
  dob_label     text,
  gender        text,
  city          text,
  looking       text,
  bio           text default '',
  interests     text[] default '{}',
  answers       jsonb default '{}',
  photos        text[] default '{}',
  tier          text default 'free',
  connects_left integer default 20,
  sparks_left   integer default 1,
  wallet_balance numeric(10,2) default 0,
  rose_inventory jsonb default '{"rose":0,"bouquet":0,"golden":0}',
  is_verified   boolean default false,
  settings      jsonb default '{}',
  stats         jsonb default '{"connects":0,"matches":0,"passes":0}',
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "profiles_own"
  on public.profiles for all
  using (auth.uid() = id);

-- ── SWIPES ───────────────────────────────────────────────────
create table if not exists public.swipes (
  id         uuid default gen_random_uuid() primary key,
  user_id    uuid references auth.users on delete cascade not null,
  target_id  text not null,
  direction  text not null check (direction in ('like', 'pass')),
  created_at timestamptz default now(),
  unique(user_id, target_id)
);

alter table public.swipes enable row level security;

create policy "swipes_own"
  on public.swipes for all
  using (auth.uid() = user_id);

-- ── MATCHES ──────────────────────────────────────────────────
create table if not exists public.matches (
  id         uuid default gen_random_uuid() primary key,
  user_id    uuid references auth.users on delete cascade not null,
  target_id  text not null,
  matched_at timestamptz default now(),
  expires_at timestamptz default (now() + interval '3 days'),
  unique(user_id, target_id)
);

alter table public.matches enable row level security;

create policy "matches_own"
  on public.matches for all
  using (auth.uid() = user_id);

-- ── MESSAGES ─────────────────────────────────────────────────
create table if not exists public.messages (
  id         uuid default gen_random_uuid() primary key,
  match_id   uuid references public.matches on delete cascade not null,
  sender     text not null,
  content    text not null,
  msg_type   text default 'text',
  created_at timestamptz default now()
);

alter table public.messages enable row level security;

create policy "messages_own"
  on public.messages for all
  using (
    exists (
      select 1 from public.matches
      where matches.id = messages.match_id and matches.user_id = auth.uid()
    )
  );

-- ── REALTIME ─────────────────────────────────────────────────
alter publication supabase_realtime add table public.messages;

-- ── STORAGE ──────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
  values ('photos', 'photos', true)
  on conflict (id) do nothing;

create policy "photos_read"
  on storage.objects for select
  using (bucket_id = 'photos');

create policy "photos_upload"
  on storage.objects for insert
  with check (bucket_id = 'photos' and auth.role() = 'authenticated');

create policy "photos_delete"
  on storage.objects for delete
  using (bucket_id = 'photos' and auth.uid()::text = (storage.foldername(name))[1]);
