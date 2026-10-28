// O cliente do limite por pessoa, com `fetch` falso. A logica da contagem mora
// no SQL (supabase/limite-identificacao.sql); aqui se testa a conversa com ele.

import { deepStrictEqual, equal } from "node:assert/strict";

import { inteiroPositivo, registrarUso } from "./limite.ts";

const SUPABASE = {
  url: "https://projeto.supabase.co",
  chaveSecreta: "sb_secret_teste",
};
const LIMITES = { porMinuto: 5, porDia: 30 };

/** `fetch` falso que guarda o pedido e responde o que o teste mandar. */
function bancoFalso(responder: () => Promise<Response>) {
  const pedidos: { url: string; headers: Headers; corpo: unknown }[] = [];
  const buscar = ((url: string | URL | Request, init?: RequestInit) => {
    pedidos.push({
      url: String(url),
      headers: new Headers(init?.headers),
      corpo: JSON.parse(String(init?.body)),
    });
    return responder();
  }) as typeof fetch;
  return { buscar, pedidos };
}

const json = (valor: unknown, status = 200) =>
  Promise.resolve(new Response(JSON.stringify(valor), { status }));

Deno.test("pedido aceito: chama a funcao do banco com a chave so no apikey", async () => {
  const { buscar, pedidos } = bancoFalso(() => json("ok"));
  equal(await registrarUso("uid-1", LIMITES, SUPABASE, buscar), "ok");

  equal(pedidos.length, 1);
  equal(
    pedidos[0].url,
    "https://projeto.supabase.co/rest/v1/rpc/registrar_identificacao",
  );
  equal(pedidos[0].headers.get("apikey"), "sb_secret_teste");
  // Chave secreta em `Authorization: Bearer` e recusada como JWT invalido.
  equal(pedidos[0].headers.get("authorization"), null);
  deepStrictEqual(pedidos[0].corpo, {
    p_uid: "uid-1",
    p_por_minuto: 5,
    p_por_dia: 30,
  });
});

Deno.test("os dois limites voltam como veredito", async () => {
  for (const veredito of ["limite-minuto", "limite-dia"]) {
    const { buscar } = bancoFalso(() => json(veredito));
    equal(await registrarUso("uid-1", LIMITES, SUPABASE, buscar), veredito);
  }
});

Deno.test("banco fora do ar, sem a funcao ou com resposta estranha: null", async () => {
  const casos: (() => Promise<Response>)[] = [
    () => json({ message: "Could not find the function" }, 404),
    () => json("talvez"),
    () => Promise.resolve(new Response("nao e json", { status: 200 })),
    () => Promise.reject(new TypeError("rede")),
  ];
  for (const responder of casos) {
    const { buscar } = bancoFalso(responder);
    equal(await registrarUso("uid-1", LIMITES, SUPABASE, buscar), null);
  }
});

Deno.test("limite configurado errado cai no padrao", () => {
  equal(inteiroPositivo("12", 5), 12);
  equal(inteiroPositivo(undefined, 5), 5);
  equal(inteiroPositivo("", 5), 5);
  equal(inteiroPositivo("0", 5), 5);
  equal(inteiroPositivo("-3", 5), 5);
  equal(inteiroPositivo("2.5", 5), 5);
  equal(inteiroPositivo("abc", 5), 5);
});
