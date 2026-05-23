-- La Casa da Pizza - patch para o schema que ja existe no seu Supabase.
-- Execute no SQL Editor depois do seu SQL principal.

-- O cardapio publico precisa ler produtos e bairros.
alter table public.products enable row level security;
alter table public.bairros enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create table if not exists public.store_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_devices (
  id uuid primary key default gen_random_uuid(),
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  admin_email text,
  user_agent text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.store_settings enable row level security;
alter table public.admin_devices enable row level security;

alter table public.products
add column if not exists description text;

drop policy if exists "products_public_select" on public.products;
drop policy if exists "bairros_public_select" on public.bairros;
drop policy if exists "store_settings_public_select" on public.store_settings;
drop policy if exists "orders_public_insert" on public.orders;
drop policy if exists "orders_public_select_status" on public.orders;
drop policy if exists "order_items_public_insert" on public.order_items;

create policy "products_public_select"
on public.products for select
to anon, authenticated
using (active = true);

create policy "bairros_public_select"
on public.bairros for select
to anon, authenticated
using (active = true);

create policy "store_settings_public_select"
on public.store_settings for select
to anon, authenticated
using (true);

-- O cliente pode criar pedidos pelo cardapio publico.
create policy "orders_public_insert"
on public.orders for insert
to anon, authenticated
with check (true);

-- Permite que o cardapio publico acompanhe quando o admin aceita/prepara o pedido.
-- Para um SaaS, troque por uma view/RPC com token do pedido para reduzir exposicao.
create policy "orders_public_select_status"
on public.orders for select
to anon, authenticated
using (true);

create policy "order_items_public_insert"
on public.order_items for insert
to anon, authenticated
with check (true);

-- O admin logado pelo Supabase Auth pode gerenciar produtos e bairros.
drop policy if exists "products_authenticated_all" on public.products;
drop policy if exists "bairros_authenticated_all" on public.bairros;
drop policy if exists "store_settings_authenticated_all" on public.store_settings;
drop policy if exists "orders_authenticated_all" on public.orders;
drop policy if exists "order_items_authenticated_all" on public.order_items;
drop policy if exists "admin_devices_authenticated_all" on public.admin_devices;

create policy "products_authenticated_all"
on public.products for all
to authenticated
using (true)
with check (true);

create policy "bairros_authenticated_all"
on public.bairros for all
to authenticated
using (true)
with check (true);

create policy "store_settings_authenticated_all"
on public.store_settings for all
to authenticated
using (true)
with check (true);

create policy "orders_authenticated_all"
on public.orders for all
to authenticated
using (true)
with check (true);

create policy "order_items_authenticated_all"
on public.order_items for all
to authenticated
using (true)
with check (true);

create policy "admin_devices_authenticated_all"
on public.admin_devices for all
to authenticated
using (true)
with check (true);

insert into public.store_settings (key, value) values
  ('status','{"manual_closed":false,"closed_days":[]}'::jsonb)
on conflict (key) do nothing;

-- Produtos usados pelo admin para guardar os precos por categoria/tamanho.
-- O nome segue o padrao preco_{categoria}_{tamanho}.
insert into public.products (name, price, category, active) values
  ('preco_trad_media',38,'Pizza Preco',true),
  ('preco_trad_grande',48,'Pizza Preco',true),
  ('preco_trad_gigante',58,'Pizza Preco',true),
  ('preco_trad_familia',68,'Pizza Preco',true),
  ('preco_esp_media',45,'Pizza Preco',true),
  ('preco_esp_grande',58,'Pizza Preco',true),
  ('preco_esp_gigante',65,'Pizza Preco',true),
  ('preco_esp_familia',78,'Pizza Preco',true),
  ('preco_doce_media',38,'Pizza Preco',true),
  ('preco_doce_grande',48,'Pizza Preco',true),
  ('preco_doce_gigante',58,'Pizza Preco',true),
  ('preco_doce_familia',68,'Pizza Preco',true)
on conflict (name) do update set
  price = excluded.price,
  category = excluded.category,
  active = excluded.active,
  updated_at = now();

-- Bebidas devem ser cadastradas pelo admin em products com category = 'Bebida'.
-- Sabores de pizza podem ser cadastrados pelo admin em products:
-- category = 'Pizza Tradicional', 'Pizza Especial' ou 'Pizza Doce'.
-- Use description para os ingredientes exibidos no cardapio.
