create type order_status as enum ('draft','pending','paid','failed','refunded','disputed');
create type order_provider as enum ('stripe','paypal','other');

create table if not exists public.orders (
  id bigserial primary key,
  buyer_profile_id uuid references public.profiles(id) on delete set null,
  listing_id bigint,
  status order_status not null default 'draft',
  amount_usd numeric(12,2) not null default 0,
  currency text not null default 'USD',
  provider order_provider not null,
  provider_session_id text,
  provider_payment_intent_id text,
  created_at timestamptz default now()
);

create table if not exists public.order_events (
  id bigserial primary key,
  order_id bigint references public.orders(id) on delete cascade,
  event text not null,
  payload_json jsonb,
  created_at timestamptz default now()
);

create unique index if not exists orders_provider_session_idx on public.orders(provider, provider_session_id);
