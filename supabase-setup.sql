-- Morning Flight: run once in Supabase (SQL Editor > New query > Run).
-- One row per signed-in person holding their mornings, log, reflections and goal.
create table if not exists public.flight_data (
  user_id uuid primary key references auth.users on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.flight_data enable row level security;

-- Each person can only read and write their own row.
create policy "Own row only" on public.flight_data
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
