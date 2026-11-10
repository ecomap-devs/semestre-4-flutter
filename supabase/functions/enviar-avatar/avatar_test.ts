// A funcao enviar-avatar com `fetch` falso: nao fala com o Supabase. O SQL do
// limite tem teste proprio, num Postgres de verdade
// (supabase/testes/limite_avatar_test.ts).

import { deepStrictEqual, equal, match } from "node:assert/strict";

import {
  type Ambiente,
  atender,
  bytesDoBase64,
  MAXIMO_BYTES,
  tipoPelosBytes,
} from "./avatar.ts";

const SUPABASE = {
  url: "https://projeto.supabase.co",
  chaveSecreta: "sb_secret_teste",
};

const base64 = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes));
const ascii = (texto: string) => new TextEncoder().encode(texto);

const PNG = new Uint8Array([
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0,
  0,
  0,
  13,
  0x49,
  0x48,
]);
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 16, 0x4a, 0x46]);
const WEBP = new Uint8Array([
  ...ascii("RIFF"),
  36,
  0,
  0,
  0,
  ...ascii("WEBPVP8 "),
]);

type Pedido = { metodo: string; url: string; headers: Headers; corpo: unknown };

/**
 * O Supabase falso. `rotas` responde por "METODO caminho" (sem o host); o que
 * nao estiver la responde 404. Guarda cada pedido.
 */
function supabaseFalso(rotas: Record<string, () => Response>) {
  const pedidos: Pedido[] = [];
  const buscar = ((url: string | URL | Request, init?: RequestInit) => {
    const caminho = String(url).replace(SUPABASE.url, "");
    const metodo = init?.method ?? "GET";
    const corpo = typeof init?.body === "string"
      ? JSON.parse(init.body)
      : init?.body;
    pedidos.push({
      metodo,
      url: caminho,
      headers: new Headers(init?.headers),
      corpo,
    });
    const chave = Object.keys(rotas).find((r) => {
      const [m, prefixo] = r.split(" ");
      return m === metodo && caminho.startsWith(prefixo);
    });
    return Promise.resolve(
      chave ? rotas[chave]() : new Response("{}", { status: 404 }),
    );
  }) as typeof fetch;
  return { buscar, pedidos };
}

const json = (valor: unknown, status = 200) => () =>
  new Response(JSON.stringify(valor), { status });

/** Tudo dando certo: limite ok, gravacao ok, uma foto antiga na pasta. */
const ROTAS_OK = {
  "POST /rest/v1/rpc/registrar_avatar": json("ok"),
  "POST /storage/v1/object/list/avatars": json([
    { name: "velha.webp" },
    { name: "fixo.png" },
    { name: ".emptyFolderPlaceholder" },
  ]),
  "POST /storage/v1/object/avatars/": json({ Key: "avatars/x" }),
  "DELETE /storage/v1/object/avatars": json([]),
};

function ambiente(
  buscar: typeof fetch,
  uid: string | null = "uid123",
): Ambiente {
  return {
    uid: () => Promise.resolve(uid),
    supabase: SUPABASE,
    porDia: 5,
    buscar,
    nomeAleatorio: () => "fixo",
  };
}

function pedido(corpo: unknown, headers: Record<string, string> = {}) {
  return new Request("https://funcao/enviar-avatar", {
    method: "POST",
    headers: { Authorization: "Bearer token", ...headers },
    body: typeof corpo === "string" ? corpo : JSON.stringify(corpo),
  });
}

Deno.test("tipo pelos bytes: JPEG, PNG e WebP passam", () => {
  equal(tipoPelosBytes(JPEG)?.extensao, "jpg");
  equal(tipoPelosBytes(PNG)?.extensao, "png");
  equal(tipoPelosBytes(WEBP)?.extensao, "webp");
});

Deno.test("tipo pelos bytes: o resto nao passa, mesmo com nome de imagem", () => {
  for (
    const [nome, bytes] of [
      ["HTML", ascii("<html><script>alert(1)</script></html>")],
      ["SVG", ascii('<svg xmlns="http://www.w3.org/2000/svg"></svg>')],
      ["GIF", ascii("GIF89a....")],
      ["WAV (RIFF que nao e WebP)", ascii("RIFF\x24\0\0\0WAVEfmt ")],
      ["vazio", new Uint8Array()],
      ["JPEG cortado", new Uint8Array([0xff, 0xd8])],
    ] as const
  ) {
    equal(tipoPelosBytes(bytes), null, nome);
  }
});

Deno.test("base64 invalido vira null", () => {
  equal(bytesDoBase64("nao é base64!"), null);
  deepStrictEqual(bytesDoBase64(base64(PNG)), PNG);
});

Deno.test("envio bom: conta, grava com o tipo dos bytes, apaga a anterior", async () => {
  const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
  const resposta = await atender(
    // O cliente diz que e JPEG; os bytes sao PNG. Vale o que os bytes dizem.
    pedido({ imagem: base64(PNG) }, { "Content-Type": "image/jpeg" }),
    ambiente(buscar),
  );
  equal(resposta.status, 200);
  deepStrictEqual(await resposta.json(), { caminho: "uid123/fixo.png" });
  equal(resposta.headers.get("Access-Control-Allow-Origin"), "*");

  const [limite, gravar, listar, apagar] = pedidos;
  equal(pedidos.length, 4);
  equal(limite.url, "/rest/v1/rpc/registrar_avatar");
  deepStrictEqual(limite.corpo, { p_uid: "uid123", p_por_dia: 5 });

  equal(gravar.metodo, "POST");
  equal(gravar.url, "/storage/v1/object/avatars/uid123/fixo.png");
  equal(gravar.headers.get("Content-Type"), "image/png");
  equal(gravar.headers.get("x-upsert"), "false");
  deepStrictEqual(gravar.corpo, PNG);

  deepStrictEqual(listar.corpo, { prefix: "uid123/", limit: 100, offset: 0 });
  // A nova e o marcador de pasta ficam; so a velha sai.
  equal(apagar.metodo, "DELETE");
  deepStrictEqual(apagar.corpo, { prefixes: ["uid123/velha.webp"] });

  // A chave secreta vai so no `apikey`, nunca em `Authorization`.
  for (const p of pedidos) {
    equal(p.headers.get("apikey"), "sb_secret_teste", p.url);
    equal(p.headers.get("Authorization"), null, p.url);
  }
});

Deno.test("sem login valido: 401, e nao fala com o Supabase", async () => {
  for (const uid of [null, "", "../outra-pessoa", "uid/com/barra"]) {
    const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
    const resposta = await atender(
      pedido({ imagem: base64(PNG) }),
      ambiente(buscar, uid),
    );
    equal(resposta.status, 401, String(uid));
    equal(pedidos.length, 0, String(uid));
  }
});

Deno.test("arquivo que nao e imagem: 415, e nao gasta o limite", async () => {
  const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
  const resposta = await atender(
    pedido({ imagem: base64(ascii("<html><script>alert(1)</script>")) }, {
      "Content-Type": "image/png",
    }),
    ambiente(buscar),
  );
  equal(resposta.status, 415);
  deepStrictEqual(await resposta.json(), { erro: "tipo-invalido" });
  equal(pedidos.length, 0);
});

Deno.test("grande demais: 413 pelo cabecalho e pelos bytes", async () => {
  const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
  const pelo_cabecalho = await atender(
    pedido({ imagem: base64(PNG) }, { "Content-Length": "5000000" }),
    ambiente(buscar),
  );
  equal(pelo_cabecalho.status, 413);

  const grande = new Uint8Array(MAXIMO_BYTES + 1);
  grande.set(PNG);
  let texto = "";
  for (let i = 0; i < grande.length; i += 30_000) {
    texto += String.fromCharCode(...grande.subarray(i, i + 30_000));
  }
  const pelos_bytes = await atender(
    pedido({ imagem: btoa(texto) }),
    ambiente(buscar),
  );
  equal(pelos_bytes.status, 413);
  equal(pedidos.length, 0);
});

Deno.test("corpo errado: 400, e nao gasta o limite", async () => {
  const { buscar, pedidos } = supabaseFalso(ROTAS_OK);
  for (
    const corpo of ["nao e json", { foto: "x" }, { imagem: "" }, {
      imagem: "%%%",
    }]
  ) {
    const resposta = await atender(pedido(corpo), ambiente(buscar));
    equal(resposta.status, 400, JSON.stringify(corpo));
  }
  equal(pedidos.length, 0);
});

Deno.test("limite do dia: 429, e nao grava", async () => {
  const { buscar, pedidos } = supabaseFalso({
    ...ROTAS_OK,
    "POST /rest/v1/rpc/registrar_avatar": json("limite-dia"),
  });
  const resposta = await atender(
    pedido({ imagem: base64(JPEG) }),
    ambiente(buscar),
  );
  equal(resposta.status, 429);
  deepStrictEqual(await resposta.json(), { erro: "limite-dia" });
  equal(pedidos.length, 1);
});

Deno.test("banco fora do ar: 503, e nao grava", async () => {
  const { buscar, pedidos } = supabaseFalso({
    ...ROTAS_OK,
    "POST /rest/v1/rpc/registrar_avatar": json({ message: "erro" }, 500),
  });
  const resposta = await atender(
    pedido({ imagem: base64(WEBP) }),
    ambiente(buscar),
  );
  equal(resposta.status, 503);
  equal(pedidos.length, 1);
});

Deno.test("Storage recusou: 502, e nao apaga nada", async () => {
  const { buscar, pedidos } = supabaseFalso({
    ...ROTAS_OK,
    "POST /storage/v1/object/avatars/": json({ error: "Duplicate" }, 409),
  });
  const resposta = await atender(
    pedido({ imagem: base64(PNG) }),
    ambiente(buscar),
  );
  equal(resposta.status, 502);
  deepStrictEqual(await resposta.json(), { erro: "armazenamento" });
  equal(pedidos.some((p) => p.metodo === "DELETE"), false);
});

Deno.test("falha ao apagar a anterior nao derruba o envio", async () => {
  const { buscar } = supabaseFalso({
    ...ROTAS_OK,
    "DELETE /storage/v1/object/avatars": json({ error: "x" }, 500),
  });
  const resposta = await atender(
    pedido({ imagem: base64(PNG) }),
    ambiente(buscar),
  );
  equal(resposta.status, 200);
});

Deno.test("sem a chave secreta: 500 de configuracao", async () => {
  const { buscar } = supabaseFalso(ROTAS_OK);
  const resposta = await atender(pedido({ imagem: base64(PNG) }), {
    ...ambiente(buscar),
    supabase: { url: SUPABASE.url, chaveSecreta: "" },
  });
  equal(resposta.status, 500);
});

Deno.test("OPTIONS responde o CORS, e GET e recusado", async () => {
  const { buscar } = supabaseFalso(ROTAS_OK);
  const opcoes = await atender(
    new Request("https://funcao/enviar-avatar", { method: "OPTIONS" }),
    ambiente(buscar),
  );
  equal(opcoes.status, 200);
  match(
    opcoes.headers.get("Access-Control-Allow-Headers") ?? "",
    /authorization/,
  );
  const get = await atender(
    new Request("https://funcao/enviar-avatar"),
    ambiente(buscar),
  );
  equal(get.status, 405);
});
