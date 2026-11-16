-- Banco do Cantinho da Roça (projeto Supabase próprio, separado de qualquer outro sistema)
-- Clientes só conseguem ENVIAR pedido. Ler pedidos exige o código do vendedor.

create extension if not exists pgcrypto with schema extensions;

-- Pedidos que chegam pela página do cliente
create table public.pedidos_recebidos (
  id uuid primary key default gen_random_uuid(),
  criado_em timestamptz not null default now(),
  nome    text not null check (char_length(nome) between 1 and 120),
  tel     text check (char_length(tel) <= 40),
  cep     text check (char_length(cep) <= 12),
  rua     text check (char_length(rua) <= 200),
  numero  text check (char_length(numero) <= 20),
  bairro  text check (char_length(bairro) <= 120),
  cidade  text check (char_length(cidade) <= 120),
  ref     text check (char_length(ref) <= 300),
  itens   text not null check (char_length(itens) between 1 and 1000),
  data    date,
  horario text check (char_length(horario) <= 40),
  pag     text check (char_length(pag) <= 40),
  lat     double precision check (lat between -35 and 6),
  lng     double precision check (lng between -75 and -28),
  check (rua is not null or lat is not null)
);
create index on public.pedidos_recebidos (criado_em desc);
alter table public.pedidos_recebidos enable row level security;

-- Cliente (anônimo) só pode inserir; ninguém lê direto pela API
create policy "cliente envia pedido" on public.pedidos_recebidos
  for insert to anon with check (true);
grant insert on public.pedidos_recebidos to anon;
revoke select, update, delete on public.pedidos_recebidos from anon, authenticated;

-- Código do vendedor (guardado só como hash)
create table public.vendedor (
  id int primary key default 1 check (id = 1),
  codigo_hash text not null
);
alter table public.vendedor enable row level security;
revoke all on public.vendedor from anon, authenticated;

-- Tentativas erradas (trava contra adivinhação do código)
create table public.tentativas_codigo (
  em timestamptz not null default now()
);
alter table public.tentativas_codigo enable row level security;
revoke all on public.tentativas_codigo from anon, authenticated;

-- App do vendedor busca os pedidos recentes informando o código.
-- Devolve JSON (sem erro) para que a tentativa errada fique registrada na trava.
create or replace function public.pedidos_recentes(p_codigo text, p_desde timestamptz default now() - interval '30 days')
returns jsonb
language plpgsql security definer set search_path = public, extensions
as $$
begin
  if (select count(*) from tentativas_codigo where em > now() - interval '15 minutes') >= 10 then
    return jsonb_build_object('ok', false, 'erro', 'tentativas');
  end if;
  if not exists (select 1 from vendedor where codigo_hash = crypt(p_codigo, codigo_hash)) then
    insert into tentativas_codigo default values;
    return jsonb_build_object('ok', false, 'erro', 'codigo');
  end if;
  delete from tentativas_codigo where em < now() - interval '1 day';
  return jsonb_build_object('ok', true, 'pedidos', coalesce(
    (select jsonb_agg(to_jsonb(p) order by p.criado_em) from pedidos_recebidos p where p.criado_em >= p_desde), '[]'::jsonb));
end $$;
revoke all on function public.pedidos_recentes(text, timestamptz) from public;
grant execute on function public.pedidos_recentes(text, timestamptz) to anon;

-- O código em si é cadastrado à parte (não fica neste arquivo):
-- insert into public.vendedor (codigo_hash) values (extensions.crypt('<codigo>', extensions.gen_salt('bf')));
