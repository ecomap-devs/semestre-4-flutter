-- Limite de identificações por foto por pessoa (Edge Function identificar-animal).
--
-- Revisão de 28/10/2026: a função conferia o login, mas não quanto cada conta
-- chamava. Como o cadastro é aberto e um pedido pode gastar até quatro consultas
-- do Gemini (dois modelos, duas rodadas), um script com uma conta só esgotava a
-- cota do projeto, que é uma só para todo mundo.
--
-- Uma linha por pessoa (o uid do Firebase), com duas janelas fixas: o minuto e o
-- dia de Brasília. Só pedido aceito conta: insistir depois do limite não come o
-- limite do dia. O `for update` enfileira os pedidos simultâneos da mesma pessoa,
-- então dois pedidos juntos não passam os dois no último lugar da fila.
--
-- Ninguém de fora lê nem escreve aqui: RLS ligado e sem política, e a função só
-- pode ser executada pela `service_role` (a chave secreta da Edge Function).
--
-- Aplicar ANTES de publicar a versão da função que chama `registrar_identificacao`:
-- sem a tabela, a função recusa todos os pedidos com 503.

create table if not exists public.uso_identificacao (
  uid text primary key,
  minuto timestamptz not null default date_trunc('minute', now()),
  no_minuto integer not null default 0,
  dia date not null default (now() at time zone 'America/Sao_Paulo')::date,
  no_dia integer not null default 0
);

alter table public.uso_identificacao enable row level security;
revoke all on table public.uso_identificacao from anon, authenticated;

-- Devolve 'ok' (e conta o pedido), 'limite-minuto' ou 'limite-dia'.
create or replace function public.registrar_identificacao(
  p_uid text,
  p_por_minuto integer,
  p_por_dia integer
)
returns text
language plpgsql
set search_path = ''
as $$
declare
  v_minuto timestamptz := date_trunc('minute', now());
  v_dia date := (now() at time zone 'America/Sao_Paulo')::date;
  v_uso public.uso_identificacao;
begin
  insert into public.uso_identificacao (uid) values (p_uid)
  on conflict (uid) do nothing;

  select * into v_uso
  from public.uso_identificacao
  where uid = p_uid
  for update;

  -- Janela que já passou começa do zero.
  if v_uso.minuto <> v_minuto then
    v_uso.no_minuto := 0;
  end if;
  if v_uso.dia <> v_dia then
    v_uso.no_dia := 0;
  end if;

  if v_uso.no_dia >= p_por_dia then
    return 'limite-dia';
  end if;
  if v_uso.no_minuto >= p_por_minuto then
    return 'limite-minuto';
  end if;

  update public.uso_identificacao
  set minuto = v_minuto,
      no_minuto = v_uso.no_minuto + 1,
      dia = v_dia,
      no_dia = v_uso.no_dia + 1
  where uid = p_uid;

  return 'ok';
end;
$$;

revoke execute on function public.registrar_identificacao(text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.registrar_identificacao(text, integer, integer)
  to service_role;
