// A funcao apagar-conta com `fetch` falso: nao fala com o Supabase.

import { deepStrictEqual, equal } from "node:assert/strict";

import {
  type Ambiente,
  atender,
  EXTENSOES_ANTIGAS,
  LOGIN_RECENTE_S,
} from "./conta.ts";

const SUPABASE = {
  url: "https://projeto.supabase.co",
  chaveSecreta: "sb_secret_teste",
};
const UID = "uid123";
const AGORA = 1_800_000_000;

type Pedido = { metodo: string; url: string; headers: Headers; corpo: unknown };

/**
 * O Supabase falso. `rotas` responde por "METODO caminho" (sem o host); o que
 * nao estiver la responde 404. Guarda cada pedido.
 */
function supabaseFalso(rotas: Record<string, (p: Pedido) => Response>) {
  const pedidos: Pedido[] = [];
  const buscar = ((url: string | URL | Request, init?: RequestInit) => {
    const caminho = String(url).replace(SUPABASE.url, "");
    const metodo = init?.method ?? "GET";
    const corpo = typeof init?.body === "string"
      ? JSON.parse(init.body)
      : init?.body;
    const pedido = {
      metodo,
      url: caminho,
      headers: new Headers(init?.headers),
      corpo,
    };
    pedidos.push(pedido);
    const chave = Object.keys(rotas).find((r) => {
      const [m, prefixo] = r.split(" ");
      return m === metodo && caminho.startsWith(prefixo);
    });
    return Promise.resolve(
      chave ? rotas[chave](pedido) : new Response("{}", { status: 404 }),
    );
  }) as typeof fetch;
  return { buscar, pedidos };
}

const json = (valor: unknown, status = 200) => () =>
  new Response(JSON.stringify(valor), { status });
const vazio = (status = 204) => () => new Response(null, { status });

/** Tudo dando certo: uma foto e o marcador de pasta, e as duas linhas de uso. */
const ROTAS_OK = {
  "POST /storage/v1/object/list/avatars": json([
    { name: "3f2a9c1e-7b4d-4e8a-9f10-2c3d4e5f6a7b.webp" },
    { name: ".emptyFolderPlaceholder" },
  ]),
  "DELETE /storage/v1/object/avatars": json([{ name: "a" }, { name: "b" }]),
  "DELETE /rest/v1/uso_avatar": vazio(),
  "DELETE /rest/v1/uso_identificacao": vazio(),
};

function ambiente(
  buscar: typeof fetch,
  login: { uid: string; autenticadoEm: number } | null = {
    uid: UID,
    autenticadoEm: AGORA - 30,
  },
): Ambiente {
  return {
    login: () => Promise.resolve(login),
    supabase: SUPABASE,
    agora: () => AGORA,
    buscar,
  };
}

const pedido = (metodo = "POST") =>
  new Request("https://funcao/apagar-conta", {
    method: metodo,
    headers: { Authorization: "Bearer token" },
  });

Deno.test("apaga as fotos dos dois formatos e as linhas de uso", async () => {
  const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
  const resposta = await atender(pedido(), ambiente(buscar));

  equal(resposta.status, 200);
  deepStrictEqual(await resposta.json(), { fotos: 2 });

  // Lista so a pasta da conta.
  deepStrictEqual(pedidos[0].corpo, {
    prefix: `${UID}/`,
    limit: 100,
    offset: 0,
  });
  // Apaga a pasta inteira, marcador incluido, e os nomes do formato antigo.
  deepStrictEqual(pedidos[1].corpo, {
    prefixes: [
      `${UID}/3f2a9c1e-7b4d-4e8a-9f10-2c3d4e5f6a7b.webp`,
      `${UID}/.emptyFolderPlaceholder`,
      ...EXTENSOES_ANTIGAS.map((e) => `${UID}.${e}`),
    ],
  });
  equal(pedidos[2].url, `/rest/v1/uso_avatar?uid=eq.${UID}`);
  equal(pedidos[3].url, `/rest/v1/uso_identificacao?uid=eq.${UID}`);
  equal(pedidos.length, 4);

  // A chave secreta vai so no `apikey`.
  for (const p of pedidos) {
    equal(p.headers.get("apikey"), SUPABASE.chaveSecreta);
    equal(p.headers.get("Authorization"), null);
  }
});

Deno.test("conta sem foto e sem linha: 200 com zero", async () => {
  const { buscar } = supabaseFalso({
    ...ROTAS_OK,
    "POST /storage/v1/object/list/avatars": json([]),
    "DELETE /storage/v1/object/avatars": json([]),
  });
  const resposta = await atender(pedido(), ambiente(buscar));
  equal(resposta.status, 200);
  deepStrictEqual(await resposta.json(), { fotos: 0 });
});

Deno.test("pasta com mais de uma pagina: lista ate o fim", async () => {
  const pagina = (n: number, desde: number) =>
    Array.from({ length: n }, (_, i) => ({ name: `f${desde + i}.webp` }));
  const { buscar, pedidos } = supabaseFalso({
    ...ROTAS_OK,
    "POST /storage/v1/object/list/avatars": (p) =>
      new Response(
        JSON.stringify(
          (p.corpo as { offset: number }).offset === 0
            ? pagina(100, 0)
            : pagina(3, 100),
        ),
      ),
  });
  const resposta = await atender(pedido(), ambiente(buscar));
  equal(resposta.status, 200);

  const listagens = pedidos.filter((p) => p.url.includes("/object/list/"));
  deepStrictEqual(
    listagens.map((p) => (p.corpo as { offset: number }).offset),
    [
      0,
      100,
    ],
  );
  const apagar = pedidos.find((p) => p.metodo === "DELETE")!;
  equal(
    (apagar.corpo as { prefixes: string[] }).prefixes.length,
    103 + EXTENSOES_ANTIGAS.length,
  );
});

Deno.test("sem login valido: 401, e nao fala com o Supabase", async () => {
  const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
  const resposta = await atender(pedido(), ambiente(buscar, null));
  equal(resposta.status, 401);
  deepStrictEqual(await resposta.json(), { erro: "nao-autenticado" });
  equal(pedidos.length, 0);
});

Deno.test("uid fora do formato do Firebase: 401", async () => {
  for (const uid of ["../outro", "uid/x", "uid?x=1", "uid.jpg", ""]) {
    const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
    const resposta = await atender(
      pedido(),
      ambiente(buscar, { uid, autenticadoEm: AGORA }),
    );
    equal(resposta.status, 401, uid);
    equal(pedidos.length, 0, uid);
  }
});

Deno.test("login de mais de 5 minutos: 401 login-antigo, nada apagado", async () => {
  const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
  const resposta = await atender(
    pedido(),
    ambiente(buscar, { uid: UID, autenticadoEm: AGORA - LOGIN_RECENTE_S - 1 }),
  );
  equal(resposta.status, 401);
  deepStrictEqual(await resposta.json(), { erro: "login-antigo" });
  equal(pedidos.length, 0);
});

Deno.test("login de exatamente 5 minutos ainda vale", async () => {
  const { buscar } = supabaseFalso(ROTAS_OK);
  const resposta = await atender(
    pedido(),
    ambiente(buscar, { uid: UID, autenticadoEm: AGORA - LOGIN_RECENTE_S }),
  );
  equal(resposta.status, 200);
});

Deno.test("login no futuro: aceita a folga do relogio, recusa alem dela", async () => {
  const comAtraso = async (segundos: number) => {
    const { buscar } = supabaseFalso(ROTAS_OK);
    return (await atender(
      pedido(),
      ambiente(buscar, { uid: UID, autenticadoEm: AGORA + segundos }),
    )).status;
  };
  equal(await comAtraso(30), 200);
  equal(await comAtraso(3600), 401);
});

Deno.test("listagem falhou: 502, e nada e apagado", async () => {
  const { buscar, pedidos } = supabaseFalso({
    ...ROTAS_OK,
    "POST /storage/v1/object/list/avatars": json({ erro: "x" }, 500),
  });
  const resposta = await atender(pedido(), ambiente(buscar));
  equal(resposta.status, 502);
  deepStrictEqual(await resposta.json(), { erro: "armazenamento" });
  equal(pedidos.filter((p) => p.metodo === "DELETE").length, 0);
});

Deno.test("Storage recusou apagar: 502, e as linhas de uso ficam", async () => {
  const { buscar, pedidos } = supabaseFalso({
    ...ROTAS_OK,
    "DELETE /storage/v1/object/avatars": json({ erro: "x" }, 500),
  });
  const resposta = await atender(pedido(), ambiente(buscar));
  equal(resposta.status, 502);
  deepStrictEqual(await resposta.json(), { erro: "armazenamento" });
  equal(pedidos.filter((p) => p.url.startsWith("/rest/")).length, 0);
});

Deno.test("banco recusou: 502 banco", async () => {
  const { buscar } = supabaseFalso({
    ...ROTAS_OK,
    "DELETE /rest/v1/uso_identificacao": json({ erro: "x" }, 500),
  });
  const resposta = await atender(pedido(), ambiente(buscar));
  equal(resposta.status, 502);
  deepStrictEqual(await resposta.json(), { erro: "banco" });
});

Deno.test("rede fora do ar: 502, sem estourar", async () => {
  const buscar =
    (() => Promise.reject(new TypeError("offline"))) as typeof fetch;
  const resposta = await atender(pedido(), ambiente(buscar));
  equal(resposta.status, 502);
});

Deno.test("sem a chave secreta: 500 de configuracao", async () => {
  const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
  const resposta = await atender(pedido(), {
    ...ambiente(buscar),
    supabase: { url: SUPABASE.url, chaveSecreta: "" },
  });
  equal(resposta.status, 500);
  equal(pedidos.length, 0);
});

Deno.test("OPTIONS responde o CORS, e GET e recusado", async () => {
  const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
  const opcoes = await atender(pedido("OPTIONS"), ambiente(buscar));
  equal(opcoes.status, 200);
  equal(opcoes.headers.get("Access-Control-Allow-Origin"), "*");
  const get = await atender(pedido("GET"), ambiente(buscar));
  equal(get.status, 405);
  equal(pedidos.length, 0);
});
