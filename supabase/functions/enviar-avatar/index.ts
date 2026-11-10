// Recebe a foto de perfil e grava no bucket `avatars`, no lugar do envio
// direto que o bucket aceitava de qualquer pessoa (revisao de seguranca de
// 10/11/2026). A logica e os testes estao em avatar.ts e avatar_test.ts.
//
// Secrets (supabase secrets set ...):
//   FIREBASE_PROJECT_ID     o mesmo do env.json do app (ja existe, da
//                           identificar-animal)
//   LIMITE_AVATAR_POR_DIA   opcional; fotos por pessoa por dia (5)
// A plataforma ja entrega SUPABASE_URL e SUPABASE_SECRET_KEYS; a gravacao usa
// a chave secreta `default`.
//
// Ordem para publicar (detalhe em supabase/avatars-so-pela-funcao.sql):
//   1. supabase/limite-avatar.sql
//   2. supabase functions deploy enviar-avatar --no-verify-jwt
//   3. o site e uma versao nova do app usando a funcao
//   4. por ultimo, supabase/avatars-so-pela-funcao.sql

import { uidDoToken } from "../_compartilhado/firebase.ts";
import { atender, inteiroPositivo } from "./avatar.ts";

const PROJETO_FIREBASE = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";

/** A chave secreta `default` de SUPABASE_SECRET_KEYS (um JSON por nome). */
function chaveSecretaPadrao(): string {
  try {
    const chaves = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}");
    return typeof chaves?.default === "string" ? chaves.default : "";
  } catch {
    return "";
  }
}

const AMBIENTE = {
  uid: (req: Request) => uidDoToken(req, PROJETO_FIREBASE),
  supabase: {
    url: Deno.env.get("SUPABASE_URL") ?? "",
    chaveSecreta: chaveSecretaPadrao(),
  },
  porDia: inteiroPositivo(Deno.env.get("LIMITE_AVATAR_POR_DIA"), 5),
};

// Erro inesperado vira 500 COM os cabecalhos de CORS, como na
// identificar-animal: sem eles, o navegador nao le a resposta de erro.
Deno.serve(async (req) => {
  try {
    if (!PROJETO_FIREBASE) {
      console.error("Configuracao incompleta: FIREBASE_PROJECT_ID");
    }
    return await atender(req, AMBIENTE);
  } catch (erro) {
    console.error("Erro inesperado", erro);
    return new Response(JSON.stringify({ erro: "interno" }), {
      status: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json",
      },
    });
  }
});
