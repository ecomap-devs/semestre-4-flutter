// Identifica o animal de uma foto pelo Gemini (Google AI Studio).
//
// Existe para que a chave do Gemini NUNCA chegue ao app: APK e descompilavel
// (AGENTS.md, "o que segredo quer dizer aqui"), e com a chave na mao qualquer
// um gastaria a cota do projeto. A chave vive como secret do Supabase e so
// este codigo a le.
//
// Antes era o Google Cloud Vision, que exige conta de faturamento — e, no
// Brasil, isso pedia CNPJ. O nivel gratuito do AI Studio nao exige
// faturamento. Em troca, o Google pode usar o que e enviado nele para
// melhorar os produtos dele; a tela de Fotos avisa isso a quem usa.
//
// Quem chama precisa estar logado no Firebase. A publishable key do Supabase e
// publica por design, entao ela sozinha nao pode bastar para gastar a cota: o
// app manda o ID token do Firebase em `Authorization`, e ele e conferido aqui
// contra as chaves publicas do Google. Por isso o `verify_jwt` do gateway fica
// desligado (supabase/config.toml) — ele so entende JWT do proprio Supabase.
//
// Login nao basta: o cadastro e aberto. Desde 28/10/2026 cada pessoa tem um
// limite por minuto e por dia, contado no Postgres do Supabase
// (supabase/limite-identificacao.sql, que precisa estar aplicado ANTES).
//
// Secrets (supabase secrets set ...):
//   GEMINI_API_KEY       chave criada em aistudio.google.com
//   FIREBASE_PROJECT_ID  o mesmo do env.json do app
//   GEMINI_MODEL         opcional; troca o modelo sem republicar a funcao
//   GEMINI_MODEL_RESERVA opcional; o modelo usado quando o principal esta
//                        sobrecarregado
//   LIMITE_POR_MINUTO    opcional; identificacoes por pessoa por minuto (5)
//   LIMITE_POR_DIA       opcional; identificacoes por pessoa por dia (30)
// A plataforma ja entrega SUPABASE_URL e SUPABASE_SECRET_KEYS; o limite usa a
// chave secreta `default`. As chaves legadas (service_role) estao desativadas
// neste projeto desde 08/09/2026.
//
// Os padroes sao apelidos ("-latest"), nao versoes fixas: em 01/10/2026 o
// `gemini-2.5-flash` ja respondia 404, e versao fixa envelhece calada.

import { createRemoteJWKSet, jwtVerify } from "npm:jose@5";

import { chamarGemini, consultar, type Tentativa } from "./gemini.ts";
import { inteiroPositivo, registrarUso } from "./limite.ts";

const CHAVE_GEMINI = Deno.env.get("GEMINI_API_KEY") ?? "";
const PROJETO_FIREBASE = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
// O lite e o principal desde 02/10/2026. Medido no site: o flash-latest
// estourou 25 s (antes do teto, a chamada chegou a 106 s), e o
// flash-lite-latest (gemini-3.5-flash-lite) respondeu certo em 1,8 s, sem
// gastar token pensando. O Flash completo fica de reserva, para quando o lite
// estiver sobrecarregado.
const MODELOS = {
  principal: Deno.env.get("GEMINI_MODEL") || "gemini-flash-lite-latest",
  reserva: Deno.env.get("GEMINI_MODEL_RESERVA") || "gemini-flash-latest",
};

const LIMITES = {
  porMinuto: inteiroPositivo(Deno.env.get("LIMITE_POR_MINUTO"), 5),
  porDia: inteiroPositivo(Deno.env.get("LIMITE_POR_DIA"), 30),
};

const SUPABASE = {
  url: Deno.env.get("SUPABASE_URL") ?? "",
  chaveSecreta: chaveSecretaPadrao(),
};

// Teto de tempo. No primeiro teste do site a chamada levou 106 s: sem limite,
// uma chamada lenta segura a tela pelo tempo que o Google quiser.
const TETO_TOTAL_MS = 50_000;

// Chaves publicas que assinam os ID tokens do Firebase Auth.
const CHAVES_FIREBASE = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

// ~3 MB de imagem. O app ja reduz para 1024 px antes de mandar; isto e so o
// teto para quem chamar a funcao por fora do app.
const TAMANHO_MAXIMO_BASE64 = 4_000_000;
// O corpo e `{"imagem":"..."}`: a imagem e quase tudo.
const TAMANHO_MAXIMO_CORPO = TAMANHO_MAXIMO_BASE64 + 1_000;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// O pedido ao modelo. A descricao e so do que se ve na foto: dado ambiental
// (status de ameaca, populacao) gerado por IA seria numero inventado, e o
// AGENTS.md proibe isso.
const INSTRUCAO =
  `Voce identifica animais em fotos para um app brasileiro sobre fauna.
Responda em portugues do Brasil.
- ehAnimal: false se nao houver animal na foto (pessoa, objeto, paisagem, desenho sem animal).
- nomePopular: o nome popular no Brasil, ex.: "onça-pintada". Vazio se nao for animal.
- nomeCientifico: o nome cientifico da especie, ou do genero se nao der para saber a especie. Vazio se nao souber.
- confianca: "alta", "media" ou "baixa", conforme a certeza da identificacao.
- descricao: ate duas frases sobre o que se ve na foto e as caracteristicas que levaram a identificacao. Nao cite status de conservacao, populacao nem numeros.`;

const ESQUEMA = {
  type: "OBJECT",
  properties: {
    ehAnimal: { type: "BOOLEAN" },
    nomePopular: { type: "STRING" },
    nomeCientifico: { type: "STRING" },
    confianca: { type: "STRING", enum: ["alta", "media", "baixa"] },
    descricao: { type: "STRING" },
  },
  required: [
    "ehAnimal",
    "nomePopular",
    "nomeCientifico",
    "confianca",
    "descricao",
  ],
};

/** A chave secreta `default` de SUPABASE_SECRET_KEYS (um JSON por nome). */
function chaveSecretaPadrao(): string {
  try {
    const chaves = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}");
    return typeof chaves?.default === "string" ? chaves.default : "";
  } catch {
    return "";
  }
}

function responder(status: number, corpo: unknown): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

/** O uid de quem chama, se o ID token do Firebase for valido; senao, `null`. */
async function uidValido(req: Request): Promise<string | null> {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, CHAVES_FIREBASE, {
      issuer: `https://securetoken.google.com/${PROJETO_FIREBASE}`,
      audience: PROJETO_FIREBASE,
    });
    // O limite e contado por uid: token sem `sub` nao tem a quem contar.
    return typeof payload.sub === "string" && payload.sub ? payload.sub : null;
  } catch {
    return null;
  }
}

// O image_picker devolve JPEG quase sempre, mas a galeria pode mandar PNG ou
// WebP. O inicio do base64 denuncia o formato.
function tipoDaImagem(base64: string): string {
  if (base64.startsWith("iVBOR")) return "image/png";
  if (base64.startsWith("UklGR")) return "image/webp";
  return "image/jpeg";
}

async function atender(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") {
    return responder(405, { erro: "metodo-invalido" });
  }

  if (
    !CHAVE_GEMINI || !PROJETO_FIREBASE || !SUPABASE.url ||
    !SUPABASE.chaveSecreta
  ) {
    console.error(
      "Configuracao incompleta: GEMINI_API_KEY, FIREBASE_PROJECT_ID, SUPABASE_URL ou a chave secreta `default`",
    );
    return responder(500, { erro: "configuracao" });
  }

  const uid = await uidValido(req);
  if (!uid) {
    console.warn("Chamada sem ID token valido do Firebase");
    return responder(401, { erro: "nao-autenticado" });
  }

  // Antes de ler o corpo: o teto da imagem so era conferido depois de o JSON
  // inteiro estar na memoria.
  const declarado = Number(req.headers.get("Content-Length"));
  if (Number.isFinite(declarado) && declarado > TAMANHO_MAXIMO_CORPO) {
    return responder(413, { erro: "imagem-grande" });
  }

  let imagem: unknown;
  try {
    ({ imagem } = await req.json());
  } catch {
    console.warn("Corpo nao e JSON");
    return responder(400, { erro: "corpo-invalido" });
  }
  if (typeof imagem !== "string" || imagem.length === 0) {
    console.warn("Corpo sem imagem");
    return responder(400, { erro: "sem-imagem" });
  }
  // Continua aqui para o corpo sem `Content-Length` (envio em partes).
  if (imagem.length > TAMANHO_MAXIMO_BASE64) {
    return responder(413, { erro: "imagem-grande" });
  }

  // Conta so pedido valido: um corpo errado nao gasta o limite de ninguem.
  const veredito = await registrarUso(uid, LIMITES, SUPABASE);
  if (veredito === null) {
    return responder(503, { erro: "limite-indisponivel" });
  }
  if (veredito !== "ok") {
    console.warn("Limite atingido", veredito);
    return responder(429, { erro: veredito });
  }

  const corpo = JSON.stringify({
    contents: [
      {
        parts: [
          { inline_data: { mime_type: tipoDaImagem(imagem), data: imagem } },
          { text: INSTRUCAO },
        ],
      },
    ],
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: ESQUEMA,
      temperature: 0.2,
    },
  });

  const prazo = Date.now() + TETO_TOTAL_MS;
  const tentativas: Tentativa[] = [];
  const { http } = await consultar(
    MODELOS,
    (modelo, cancelar) =>
      chamarGemini(modelo, corpo, CHAVE_GEMINI, cancelar, prazo),
    prazo,
    tentativas,
  );

  if (!http) {
    console.error("Gemini nao respondeu a tempo", JSON.stringify(tentativas));
    return responder(504, { erro: "ia-lenta", tentativas });
  }

  if (http.status < 200 || http.status >= 300) {
    console.error("Gemini respondeu", http.status, http.corpo);
    // Cota do nivel gratuito estourada: o app mostra "aguarde um momento".
    if (http.status === 429) {
      return responder(429, { erro: "cota", tentativas });
    }
    // O status do Google volta junto (sem a chave) para o motivo aparecer ate
    // no painel de Invocations, mesmo quando o log atrasa.
    return responder(502, {
      erro: "ia-indisponivel",
      status: http.status,
      tentativas,
    });
  }

  let dados;
  try {
    dados = JSON.parse(http.corpo);
  } catch {
    console.error(
      "Gemini devolveu corpo que nao e JSON",
      http.corpo.slice(0, 200),
    );
    return responder(502, { erro: "resposta-invalida", tentativas });
  }
  const texto = dados?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof texto !== "string") {
    // Acontece quando o filtro de seguranca do Gemini bloqueia a imagem.
    console.error(
      "Gemini sem texto",
      JSON.stringify(
        dados?.promptFeedback ?? dados?.candidates?.[0]?.finishReason,
      ),
    );
    return responder(422, { erro: "imagem-recusada" });
  }

  let identificacao: unknown;
  try {
    identificacao = JSON.parse(texto);
  } catch {
    console.error("Gemini devolveu JSON invalido", texto.slice(0, 200));
    return responder(502, { erro: "resposta-invalida" });
  }

  // Quanto tempo foi, em que modelo, e quanto o modelo "pensou" antes de
  // responder: e o que separa demora do Google de demora do raciocinio.
  const diagnostico = {
    tentativas,
    modelo: dados?.modelVersion ?? null,
    tokensPensamento: dados?.usageMetadata?.thoughtsTokenCount ?? 0,
  };
  console.log("Gemini ok", JSON.stringify(diagnostico));

  // Repassa o objeto como veio; o parser fica no Dart, onde tem teste. O
  // `_diagnostico` vai junto e os parsers do app e do site o ignoram.
  return responder(
    200,
    typeof identificacao === "object" && identificacao !== null &&
      !Array.isArray(identificacao)
      ? { ...identificacao, _diagnostico: diagnostico }
      : identificacao,
  );
}

// Erro inesperado vira 500 COM os cabecalhos de CORS. Sem isto, a resposta de
// erro da plataforma vinha sem CORS, o navegador nao conseguia le-la, e o site
// mostrava "Sem conexao" para um defeito que era daqui.
Deno.serve(async (req) => {
  try {
    return await atender(req);
  } catch (erro) {
    console.error("Erro inesperado", erro);
    return responder(500, { erro: "interno" });
  }
});
