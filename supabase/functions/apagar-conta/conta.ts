// O que a conta deixou no Supabase, apagado quando a pessoa apaga a conta.
//
// O botao de apagar conta (11/11/2026) roda no app e no site: eles apagam as
// avaliacoes, o perfil e a conta no Firebase, que as Firestore Rules deixam o
// dono apagar. O que fica no Supabase eles nao alcancam: o bucket `avatars` nao
// tem politica nenhuma desde 10/11/2026 (supabase/avatars-so-pela-funcao.sql), e
// as tabelas de limite so a chave secreta le. Por isso esta funcao, que apaga:
//   - as fotos de perfil: a pasta `<uid>/` (formato desde 01/10/2026) e o
//     arquivo `<uid>.<ext>` na raiz (formato anterior);
//   - a linha da conta em `uso_avatar` e em `uso_identificacao`.
//
// Ela e chamada ANTES de apagar a conta no Firebase, porque depois disso nao ha
// mais ID token. E exige login recente, como o Firebase exige para apagar o
// usuario: um token copiado nao basta para apagar a foto de ninguem.
//
// Tudo o que fala com a rede recebe o `fetch` por parametro, para os testes
// (conta_test.ts) rodarem sem Supabase.

import type { Login } from "../_compartilhado/firebase.ts";

export type Supabase = { url: string; chaveSecreta: string };

export type Ambiente = {
  /** O login de quem chama, ou `null` sem login valido. */
  login: (req: Request) => Promise<Login | null>;
  supabase: Supabase;
  /** Agora, em segundos desde 1970. Os testes fixam. */
  agora?: () => number;
  buscar?: typeof fetch;
};

/**
 * Quanto tempo depois de digitar a senha ainda da para apagar: os mesmos 5
 * minutos que o Firebase exige para apagar o usuario (`requires-recent-login`).
 */
export const LOGIN_RECENTE_S = 5 * 60;

// Relogio do Google um pouco adiantado em relacao ao daqui: o `auth_time` pode
// chegar alguns segundos no futuro.
const FOLGA_DO_RELOGIO_S = 60;

/** As tabelas de limite, com uma linha por conta (supabase/limite-*.sql). */
export const TABELAS_DE_USO = ["uso_avatar", "uso_identificacao"] as const;

/**
 * As extensoes do formato antigo, `<uid>.<ext>` na raiz do bucket. Na raiz ha
 * `.jpg`, `.png` e `.webp` (listagem de 11/11/2026); `jpeg` e `gif` entram por
 * garantia, porque o bucket aceitava qualquer tipo ate 01/10/2026. Apagar um
 * nome que nao existe nao da erro.
 */
export const EXTENSOES_ANTIGAS = ["jpg", "jpeg", "png", "webp", "gif"];

const POR_PAGINA = 100;
// Teto da listagem. Com 5 fotos por dia e a anterior apagada a cada envio, a
// pasta tem uma foto; o teto so impede um laco sem fim se a API mudar.
const MAXIMO_DE_PAGINAS = 20;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// A chave secreta vai SO no `apikey`: em `Authorization: Bearer` a plataforma
// tenta le-la como JWT e recusa (o mesmo de enviar-avatar/avatar.ts).
const cabecalhos = (
  supabase: Supabase,
  extra: Record<string, string> = {},
) => ({
  apikey: supabase.chaveSecreta,
  ...extra,
});

/**
 * Os caminhos das fotos de `uid`: tudo o que estiver na pasta dele e os nomes
 * possiveis do formato antigo. `null` se a listagem falhar.
 */
export async function caminhosDasFotos(
  uid: string,
  supabase: Supabase,
  buscar: typeof fetch = fetch,
): Promise<string[] | null> {
  const caminhos: string[] = [];
  try {
    for (let pagina = 0; pagina < MAXIMO_DE_PAGINAS; pagina++) {
      const resposta = await buscar(
        `${supabase.url}/storage/v1/object/list/avatars`,
        {
          method: "POST",
          headers: cabecalhos(supabase, { "Content-Type": "application/json" }),
          body: JSON.stringify({
            prefix: `${uid}/`,
            limit: POR_PAGINA,
            offset: pagina * POR_PAGINA,
          }),
          signal: AbortSignal.timeout(5_000),
        },
      );
      if (!resposta.ok) {
        console.error("Apagar conta: a listagem respondeu", resposta.status);
        return null;
      }
      const itens: unknown = await resposta.json();
      if (!Array.isArray(itens)) return null;
      // A pasta inteira e da conta, inclusive um `.emptyFolderPlaceholder`:
      // deixa-lo para tras deixaria o uid no bucket.
      for (const item of itens) {
        if (typeof item?.name === "string" && item.name) {
          caminhos.push(`${uid}/${item.name}`);
        }
      }
      if (itens.length < POR_PAGINA) break;
    }
  } catch (erro) {
    console.error("Apagar conta: nao deu para listar as fotos", erro);
    return null;
  }
  for (const extensao of EXTENSOES_ANTIGAS) {
    caminhos.push(`${uid}.${extensao}`);
  }
  return caminhos;
}

/** Apaga as fotos de `uid`. Devolve quantas existiam, ou `null` se falhar. */
export async function apagarFotos(
  uid: string,
  supabase: Supabase,
  buscar: typeof fetch = fetch,
): Promise<number | null> {
  const caminhos = await caminhosDasFotos(uid, supabase, buscar);
  if (caminhos === null) return null;
  try {
    const resposta = await buscar(`${supabase.url}/storage/v1/object/avatars`, {
      method: "DELETE",
      headers: cabecalhos(supabase, { "Content-Type": "application/json" }),
      body: JSON.stringify({ prefixes: caminhos }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!resposta.ok) {
      console.error(
        "Apagar conta: o Storage respondeu",
        resposta.status,
        (await resposta.text()).slice(0, 200),
      );
      return null;
    }
    // O Storage devolve os objetos que existiam e foram apagados.
    const apagados: unknown = await resposta.json();
    return Array.isArray(apagados) ? apagados.length : 0;
  } catch (erro) {
    console.error("Apagar conta: nao deu para apagar as fotos", erro);
    return null;
  }
}

/** Apaga a linha de `uid` em `tabela`. Sem linha tambem e sucesso. */
export async function apagarUso(
  uid: string,
  tabela: (typeof TABELAS_DE_USO)[number],
  supabase: Supabase,
  buscar: typeof fetch = fetch,
): Promise<boolean> {
  try {
    const resposta = await buscar(
      `${supabase.url}/rest/v1/${tabela}?uid=eq.${encodeURIComponent(uid)}`,
      {
        method: "DELETE",
        headers: cabecalhos(supabase, { Prefer: "return=minimal" }),
        signal: AbortSignal.timeout(5_000),
      },
    );
    if (!resposta.ok) {
      console.error(
        `Apagar conta: o banco respondeu ${resposta.status} em ${tabela}`,
        (await resposta.text()).slice(0, 200),
      );
    }
    return resposta.ok;
  } catch (erro) {
    console.error(`Apagar conta: nao deu para apagar em ${tabela}`, erro);
    return false;
  }
}

function responder(status: number, corpo: unknown): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

/**
 * Recebe um POST com `Authorization: Bearer <ID token>` de login recente, apaga
 * as fotos e as linhas de limite da conta e devolve `{"fotos": <quantas>}`.
 * Pode ser chamada de novo: o que ja saiu nao da erro.
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

  const login = await amb.login(req);
  // O uid vira nome de arquivo e filtro: so letras e numeros, como os do Firebase.
  if (!login || !/^[A-Za-z0-9]{1,128}$/.test(login.uid)) {
    return responder(401, { erro: "nao-autenticado" });
  }
  const agora = (amb.agora ?? (() => Math.floor(Date.now() / 1000)))();
  const idade = agora - login.autenticadoEm;
  if (idade > LOGIN_RECENTE_S || idade < -FOLGA_DO_RELOGIO_S) {
    return responder(401, { erro: "login-antigo" });
  }

  const buscar = amb.buscar ?? fetch;
  const fotos = await apagarFotos(login.uid, amb.supabase, buscar);
  if (fotos === null) return responder(502, { erro: "armazenamento" });

  for (const tabela of TABELAS_DE_USO) {
    if (!(await apagarUso(login.uid, tabela, amb.supabase, buscar))) {
      return responder(502, { erro: "banco" });
    }
  }
  return responder(200, { fotos });
}
