-- Notificação no celular quando chega pedido pelo site (via app ntfy, grátis).
-- O nome do canal (<CANAL>) é secreto: fica só no banco, nunca na página.
-- Vai para o ntfy apenas o nome do cliente e o que ele pediu (sem endereço).

create extension if not exists pg_net;

create table if not exists public.aviso_config (
  id int primary key default 1 check (id = 1),
  canal text not null
);
alter table public.aviso_config enable row level security;
revoke all on public.aviso_config from anon, authenticated;

create or replace function public.avisar_pedido_novo()
returns trigger
language plpgsql security definer set search_path = public, extensions
as $$
declare v_canal text;
begin
  select canal into v_canal from aviso_config where id = 1;
  if v_canal is not null then
    perform net.http_post(
      url  := 'https://ntfy.sh',
      body := jsonb_build_object(
        'topic',    v_canal,
        'title',    '🧀 Novo pedido: ' || new.nome,
        'message',  left(new.itens, 200) || coalesce(' · ' || new.horario, ''),
        'tags',     jsonb_build_array('cheese'),
        'priority', 4,
        'click',    'https://entregas-queijo.vercel.app'
      )
    );
  end if;
  return new;
exception when others then
  return new;  -- se o aviso falhar, o pedido é salvo do mesmo jeito
end $$;
revoke all on function public.avisar_pedido_novo() from public, anon, authenticated;

drop trigger if exists aviso_pedido_novo on public.pedidos_recebidos;
create trigger aviso_pedido_novo after insert on public.pedidos_recebidos
  for each row execute function public.avisar_pedido_novo();

-- Depois, cadastrar o canal (à parte):
-- insert into public.aviso_config (canal) values ('<CANAL>')
--   on conflict (id) do update set canal = excluded.canal;
