-- Fecha o envio direto ao bucket `avatars`: a foto de perfil passa a subir só
-- pela Edge Function enviar-avatar, que confere o login do Firebase, o tipo
-- real da imagem e o limite por pessoa (supabase/limite-avatar.sql).
--
-- Até aqui valia a política de avatars.sql (01/10/2026), que deixava qualquer
-- pessoa criar arquivo novo, até sem login. A função grava com a chave secreta
-- e não depende de política nenhuma.
--
-- APLICAR POR ÚLTIMO, nesta ordem:
--   1. supabase/limite-avatar.sql
--   2. publicar a função enviar-avatar
--   3. o site e uma versão nova do app usando a função
-- Quem ainda usa um APK de antes da função (1.0.0) passa a ficar sem foto no
-- cadastro; o cadastro em si continua, como já acontecia com foto que falha.
--
-- Os limites do próprio bucket (só JPEG, PNG e WebP, até 1 MB) continuam como
-- estão, e a função confere os mesmos por conta própria, olhando os bytes do
-- arquivo e não o tipo declarado.

drop policy if exists "avatars: criar arquivo novo" on storage.objects;
