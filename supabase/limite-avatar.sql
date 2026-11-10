-- Limite de fotos de perfil por pessoa (Edge Function enviar-avatar).
--
-- Revisão de segurança de 10/11/2026: o bucket `avatars` aceitava envio
-- direto de qualquer pessoa, até sem login (o Supabase não sabe quem está
-- logado no Firebase), sem limite de quantidade. Com a chave pública, que vai
-- no JavaScript do site, um script enchia o 1 GB do plano gratuito com uns mil
-- envios. Agora a foto sobe pela função, que confere o login do Firebase e
-- conta aqui quantas fotos cada pessoa enviou no dia.
--
-- Uma linha por pessoa (o uid do Firebase), com a janela do dia de Brasília.
-- Só envio aceito conta. O `for update` enfileira os pedidos simultâneos da
-- mesma pessoa, como em limite-identificacao.sql.
--
-- Ninguém de fora lê nem escreve aqui: RLS ligado e sem política, e a função
-- só pode ser executada pela `service_role` (a chave secreta da Edge Function).
--
-- Aplicar ANTES de publicar a função enviar-avatar: sem a tabela, a função
-- recusa todos os envios com 503.

create table if not exists public.uso_avatar (
  uid text primary key,
  dia date not null default (now() at time zone 'America/Sao_Paulo')::date,
  no_dia integer not null default 0
);

alter table public.uso_avatar enable row level security;
revoke all on table public.uso_avatar from anon, authenticated;

-- Devolve 'ok' (e conta o envio) ou 'limite-dia'.
create or replace function public.registrar_avatar(
  p_uid text,
  p_por_dia integer
)
returns text
language plpgsql
set search_path = ''
as $$
declare
  v_dia date := (now() at time zone 'America/Sao_Paulo')::date;
  v_uso public.uso_avatar;
begin
  insert into public.uso_avatar (uid) values (p_uid)
  on conflict (uid) do nothing;

  select * into v_uso
  from public.uso_avatar
  where uid = p_uid
  for update;

  -- Dia que já passou começa do zero.
  if v_uso.dia <> v_dia then
    v_uso.no_dia := 0;
  end if;

  if v_uso.no_dia >= p_por_dia then
    return 'limite-dia';
  end if;

  update public.uso_avatar
  set dia = v_dia,
      no_dia = v_uso.no_dia + 1
  where uid = p_uid;

  return 'ok';
end;
$$;

revoke execute on function public.registrar_avatar(text, integer)
  from public, anon, authenticated;
grant execute on function public.registrar_avatar(text, integer)
  to service_role;
