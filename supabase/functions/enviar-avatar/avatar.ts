// Envio da foto de perfil, pela Edge Function e nao direto ao bucket.
//
// Revisao de seguranca de 10/11/2026: o bucket `avatars` aceitava arquivo novo
// de qualquer pessoa, ate sem login, porque o Supabase nao sabe quem esta
// logado no Firebase (supabase/avatars.sql). Nao havia limite de quantidade, e a
// chave publica vai no JavaScript do site: um script enchia o 1 GB do plano
// gratuito com uns mil envios. Aqui a foto so passa com login do Firebase, com
// o tipo conferido nos bytes e no maximo `porDia` envios por pessoa por dia.
//
// Tudo o que fala com a rede recebe o `fetch` por parametro, para os testes
// (avatar_test.ts) rodarem sem Supabase.

export type Supabase = { url: string; chaveSecreta: string };

export type Ambiente = {
  /** O uid do Firebase de quem chama, ou `null` sem login valido. */
  uid: (req: Request) => Promise<string | null>;
  supabase: Supabase;
  porDia: number;
  buscar?: typeof fetch;
  /** O nome do arquivo novo, sem extensao. Os testes fixam. */
  nomeAleatorio?: () => string;
};

/** O mesmo teto do bucket (`file_size_limit` em avatars.sql). */
export const MAXIMO_BYTES = 1024 * 1024;
// Base64 de 1 MB e 4/3 disso; o corpo e `{"imagem":"..."}`.
const MAXIMO_BASE64 = 4 * Math.ceil(MAXIMO_BYTES / 3);
const MAXIMO_CORPO = MAXIMO_BASE64 + 1_000;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export type Imagem = {
  tipo: "image/jpeg" | "image/png" | "image/webp";
  extensao: "jpg" | "png" | "webp";
};

/**
 * O tipo de verdade, pelos primeiros bytes: o `Content-Type` e o nome sao do
 * cliente e podem mentir. So JPEG, PNG e WebP, os tres que o bucket aceita.
 */
export function tipoPelosBytes(bytes: Uint8Array): Imagem | null {
  const comeca = (assinatura: number[], desde = 0) =>
    bytes.length >= desde + assinatura.length &&
    assinatura.every((b, i) => bytes[desde + i] === b);

  if (comeca([0xff, 0xd8, 0xff])) {
    return { tipo: "image/jpeg", extensao: "jpg" };
  }
  if (comeca([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return { tipo: "image/png", extensao: "png" };
  }
  // "RIFF", 4 bytes de tamanho, "WEBP".
  if (comeca([0x52, 0x49, 0x46, 0x46]) && comeca([0x57, 0x45, 0x42, 0x50], 8)) {
    return { tipo: "image/webp", extensao: "webp" };
  }
  return null;
}

/**
 * Os bytes de um base64 puro (sem `data:...;base64,`), ou `null`. O tipo diz
 * `ArrayBuffer` (e nao um buffer compartilhado) para o `fetch` aceitar como corpo.
 */
export function bytesDoBase64(texto: string): Uint8Array<ArrayBuffer> | null {
  try {
    const binario = atob(texto);
    const bytes = new Uint8Array(binario.length);
    for (let i = 0; i < binario.length; i++) bytes[i] = binario.charCodeAt(i);
    return bytes;
  } catch {
    return null;
  }
}

/** Numero inteiro positivo de uma variavel de ambiente, ou o padrao. */
export function inteiroPositivo(
  valor: string | undefined,
  padrao: number,
): number {
  const n = Number(valor);
  return Number.isInteger(n) && n > 0 ? n : padrao;
}

// A chave secreta vai SO no `apikey`: em `Authorization: Bearer` a plataforma
// tenta le-la como JWT e recusa (o mesmo de identificar-animal/limite.ts).
const cabecalhos = (
  supabase: Supabase,
  extra: Record<string, string> = {},
) => ({
  apikey: supabase.chaveSecreta,
  ...extra,
});

/**
 * Conta o envio de `uid`, se couber no dia (supabase/limite-avatar.sql).
 * `null` quando nao deu para consultar o banco: quem chama recusa o envio.
 */
export async function registrarAvatar(
  uid: string,
  porDia: number,
  supabase: Supabase,
  buscar: typeof fetch = fetch,
): Promise<"ok" | "limite-dia" | null> {
  try {
    const resposta = await buscar(
      `${supabase.url}/rest/v1/rpc/registrar_avatar`,
      {
        method: "POST",
        headers: cabecalhos(supabase, { "Content-Type": "application/json" }),
        body: JSON.stringify({ p_uid: uid, p_por_dia: porDia }),
        signal: AbortSignal.timeout(5_000),
      },
    );
    const corpo = await resposta.text();
    if (!resposta.ok) {
      console.error(
        "Limite do avatar: o banco respondeu",
        resposta.status,
        corpo.slice(0, 200),
      );
      return null;
    }
    const veredito: unknown = JSON.parse(corpo);
    return veredito === "ok" || veredito === "limite-dia" ? veredito : null;
  } catch (erro) {
    console.error("Limite do avatar: nao deu para consultar o banco", erro);
    return null;
  }
}

/** Grava o arquivo novo. Nunca sobrescreve: `x-upsert: false`. */
export async function guardar(
  caminho: string,
  bytes: Uint8Array<ArrayBuffer>,
  imagem: Imagem,
  supabase: Supabase,
  buscar: typeof fetch = fetch,
): Promise<boolean> {
  try {
    const resposta = await buscar(
      `${supabase.url}/storage/v1/object/avatars/${caminho}`,
      {
        method: "POST",
        headers: cabecalhos(supabase, {
          "Content-Type": imagem.tipo,
          "x-upsert": "false",
        }),
        body: bytes,
        signal: AbortSignal.timeout(15_000),
      },
    );
    if (!resposta.ok) {
      console.error(
        "Avatar: o Storage respondeu",
        resposta.status,
        (await resposta.text()).slice(0, 200),
      );
    }
    return resposta.ok;
  } catch (erro) {
    console.error("Avatar: nao deu para gravar", erro);
    return false;
  }
}

/**
 * Apaga as outras fotos da pasta de `uid`, mantendo `manter`. A foto so sobe de
 * novo quando o cadastro falhou no meio e a pessoa tenta outra vez: a anterior
 * nao ficou em perfil nenhum. Sem isto, cada tentativa deixava um arquivo
 * para sempre no bucket.
 *
 * Tentativa so: falhar aqui nao desfaz o envio, que ja deu certo.
 */
export async function apagarAnteriores(
  uid: string,
  manter: string,
  supabase: Supabase,
  buscar: typeof fetch = fetch,
): Promise<number> {
  try {
    const lista = await buscar(
      `${supabase.url}/storage/v1/object/list/avatars`,
      {
        method: "POST",
        headers: cabecalhos(supabase, { "Content-Type": "application/json" }),
        body: JSON.stringify({ prefix: `${uid}/`, limit: 100, offset: 0 }),
        signal: AbortSignal.timeout(5_000),
      },
    );
    if (!lista.ok) return 0;
    const itens: unknown = await lista.json();
    if (!Array.isArray(itens)) return 0;
    const velhos = itens
      .map((i) => (typeof i?.name === "string" ? i.name : ""))
      .filter((nome) =>
        nome && `${uid}/${nome}` !== manter && !nome.startsWith(".")
      )
      .map((nome) => `${uid}/${nome}`);
    if (velhos.length === 0) return 0;

    const apagar = await buscar(`${supabase.url}/storage/v1/object/avatars`, {
      method: "DELETE",
      headers: cabecalhos(supabase, { "Content-Type": "application/json" }),
      body: JSON.stringify({ prefixes: velhos }),
      signal: AbortSignal.timeout(5_000),
    });
    return apagar.ok ? velhos.length : 0;
  } catch (erro) {
    console.warn("Avatar: nao deu para apagar as fotos anteriores", erro);
    return 0;
  }
}

function responder(status: number, corpo: unknown): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

/**
 * Recebe `{"imagem": "<base64>"}` com `Authorization: Bearer <ID token>`, grava
 * em `avatars/<uid>/<aleatorio>.<ext>` e devolve `{"caminho": ...}`. A URL
 * publica cada cliente monta com o proprio Supabase (`getPublicUrl`).
 */
export async function atender(req: Request, amb: Ambiente): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return responder(405, { erro: "metodo-invalido" });

  if (!amb.supabase.url || !amb.supabase.chaveSecreta) {
    console.error(
      "Configuracao incompleta: SUPABASE_URL ou a chave secreta `default`",
    );
    return responder(500, { erro: "configuracao" });
  }

  const uid = await amb.uid(req);
  // O uid vira nome de pasta: so letras e numeros, como os do Firebase.
  if (!uid || !/^[A-Za-z0-9]{1,128}$/.test(uid)) {
    return responder(401, { erro: "nao-autenticado" });
  }

  const declarado = Number(req.headers.get("Content-Length"));
  if (Number.isFinite(declarado) && declarado > MAXIMO_CORPO) {
    return responder(413, { erro: "imagem-grande" });
  }

  let imagem: unknown;
  try {
    ({ imagem } = await req.json());
  } catch {
    return responder(400, { erro: "corpo-invalido" });
  }
  if (typeof imagem !== "string" || imagem.length === 0) {
    return responder(400, { erro: "sem-imagem" });
  }
  if (imagem.length > MAXIMO_BASE64) {
    return responder(413, { erro: "imagem-grande" });
  }

  const bytes = bytesDoBase64(imagem);
  if (!bytes) return responder(400, { erro: "corpo-invalido" });
  if (bytes.length > MAXIMO_BYTES) {
    return responder(413, { erro: "imagem-grande" });
  }
  const tipo = tipoPelosBytes(bytes);
  if (!tipo) return responder(415, { erro: "tipo-invalido" });

  // Conta so envio valido: um arquivo errado nao gasta o limite de ninguem.
  const buscar = amb.buscar ?? fetch;
  const veredito = await registrarAvatar(uid, amb.porDia, amb.supabase, buscar);
  if (veredito === null) return responder(503, { erro: "limite-indisponivel" });
  if (veredito !== "ok") return responder(429, { erro: veredito });

  const nome = (amb.nomeAleatorio ?? (() => crypto.randomUUID()))();
  const caminho = `${uid}/${nome}.${tipo.extensao}`;
  if (!(await guardar(caminho, bytes, tipo, amb.supabase, buscar))) {
    return responder(502, { erro: "armazenamento" });
  }
  await apagarAnteriores(uid, caminho, amb.supabase, buscar);
  return responder(200, { caminho });
}
