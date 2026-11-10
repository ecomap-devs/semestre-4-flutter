-- Permissão da função `public.rls_auto_enable()` (aplicado em 10/11/2026).
--
-- A função não é nossa: é a que o Supabase cria para o event trigger
-- `ensure_rls`, que liga o RLS sozinho em toda tabela nova do schema `public`.
-- Ela é SECURITY DEFINER e nasceu com EXECUTE para `public`, `anon` e
-- `authenticated`, e o Advisor de segurança acusava (lints 0028 e 0029).
-- Chamar por `/rest/v1/rpc/rls_auto_enable` já falhava ("cannot display a
-- value of type event_trigger"), mas não há motivo para ninguém de fora poder.
--
-- Tirar o EXECUTE não desliga o trigger: o Postgres não confere essa permissão
-- quando um event trigger dispara. Provado num Postgres local, com um papel sem
-- EXECUTE criando tabela, e em produção, criando e apagando uma tabela de teste:
-- o RLS continuou ligando sozinho.

revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
