// Apaga o que a conta deixou no Supabase (fotos de perfil e linhas de limite),
// chamada pelo app e pelo site antes de apagar a conta no Firebase. A logica e
// os testes estao em conta.ts e conta_test.ts.
//
// Secrets (supabase secrets set ...):
//   FIREBASE_PROJECT_ID   o mesmo do env.json do app (ja existe, da
//                         identificar-animal)
// A plataforma ja entrega SUPABASE_URL e SUPABASE_SECRET_KEYS; a remocao usa a
// chave secreta `default`.
//
// Para publicar: supabase functions deploy apagar-conta --no-verify-jwt
// ANTES do site e da versao do app que tem o botao.

import { loginDoToken } from "../_compartilhado/firebase.ts";
import { atender } from "./conta.ts";

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
  login: (req: Request) => loginDoToken(req, PROJETO_FIREBASE),
  supabase: {
    url: Deno.env.get("SUPABASE_URL") ?? "",
    chaveSecreta: chaveSecretaPadrao(),
  },
};

// Erro inesperado vira 500 COM os cabecalhos de CORS, como nas outras funcoes:
// sem eles, o navegador nao le a resposta de erro.
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
