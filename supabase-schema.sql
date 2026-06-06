-- Voyagora — saved itineraries schema
-- Run this in Supabase → SQL Editor → New Query → Run

create table if not exists itineraries (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  destination text not null,
  title text,
  request jsonb not null,
  itinerary jsonb not null,
  created_at timestamptz default now()
);

alter table itineraries enable row level security;

create policy "Users see own trips"
  on itineraries for select
  using (auth.uid() = user_id);

create policy "Users save own trips"
  on itineraries for insert
  with check (auth.uid() = user_id);

create policy "Users delete own trips"
  on itineraries for delete
  using (auth.uid() = user_id);
