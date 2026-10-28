// A corrida entre o modelo principal e o reserva, com chamadas falsas.
//
//   cd supabase/functions/identificar-animal && deno test
//
// Os prazos aqui sao de milissegundos, e nao os 6 s de producao: a logica e a
// mesma, so o relogio encolhe.

import { deepStrictEqual, equal, ok } from "node:assert/strict";

import {
  type Chamada,
  chamarGemini,
  consultar,
  rodada,
  type Tentativa,
} from "./gemini.ts";

const MODELOS = { principal: "principal", reserva: "reserva" };

const dormir = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** Um passo do roteiro: responde `status` depois de `ms`; sem status, erro de rede. */
type Passo = { ms: number; status?: number };

/** Chamadas falsas que seguem um roteiro por modelo e respeitam o cancelamento. */
function chamadaFalsa(roteiro: Record<string, Passo[]>) {
  const chamados: string[] = [];
  const chamar: Chamada = (modelo, cancelar) => {
    chamados.push(modelo);
    const passo = roteiro[modelo]?.shift() ?? { ms: 0 };
    const inicio = Date.now();
    return new Promise((resolver) => {
      const aoCancelar = () => {
        clearTimeout(relogio);
        resolver({
          tentativa: { modelo, status: "cancelada", ms: Date.now() - inicio },
        });
      };
      const relogio = setTimeout(() => {
        cancelar.removeEventListener("abort", aoCancelar);
        const ms = Date.now() - inicio;
        resolver(
          passo.status === undefined
            ? { tentativa: { modelo, status: "erro-rede", ms } }
            : {
              tentativa: { modelo, status: passo.status, ms },
              http: {
                status: passo.status,
                corpo: `${modelo}:${passo.status}`,
              },
            },
        );
      }, passo.ms);
      cancelar.addEventListener("abort", aoCancelar, { once: true });
    });
  };
  return { chamar, chamados };
}

Deno.test("principal responde rapido: o reserva nem e chamado", async () => {
  const { chamar, chamados } = chamadaFalsa({
    principal: [{ ms: 5, status: 200 }],
  });
  const r = await rodada(MODELOS, chamar, [], 30);
  equal(r.http?.corpo, "principal:200");
  // Mesmo passado o prazo do paralelo, o reserva nao sai depois do fim.
  await dormir(50);
  deepStrictEqual(chamados, ["principal"]);
});
Deno.test("principal lento: o reserva entra no prazo e o primeiro bom vence", async () => {
  const { chamar, chamados } = chamadaFalsa({
    principal: [{ ms: 500, status: 200 }],
    reserva: [{ ms: 5, status: 200 }],
  });
  const tentativas: Tentativa[] = [];
  const r = await rodada(MODELOS, chamar, tentativas, 30);
  equal(r.http?.corpo, "reserva:200");
  deepStrictEqual(chamados, ["principal", "reserva"]);
  // O perdedor e cancelado, e nao fica rodando ate os 500 ms.
  await dormir(10);
  deepStrictEqual(tentativas.map((t) => [t.modelo, t.status]), [
    ["reserva", 200],
    ["principal", "cancelada"],
  ]);
});

Deno.test("principal falha logo: o reserva e chamado na hora, sem esperar o prazo", async () => {
  const { chamar, chamados } = chamadaFalsa({
    principal: [{ ms: 2, status: 503 }],
    reserva: [{ ms: 2, status: 200 }],
  });
  const inicio = Date.now();
  const r = await rodada(MODELOS, chamar, [], 10_000);
  equal(r.http?.corpo, "reserva:200");
  ok(Date.now() - inicio < 1_000, "esperou o prazo do paralelo sem precisar");
  deepStrictEqual(chamados, ["principal", "reserva"]);
});

Deno.test("os dois falham: devolve a ultima falha, com o corpo", async () => {
  const { chamar } = chamadaFalsa({
    principal: [{ ms: 2, status: 404 }],
    reserva: [{ ms: 10, status: 400 }],
  });
  const r = await rodada(MODELOS, chamar, [], 30);
  equal(r.http?.status, 400);
  equal(r.http?.corpo, "reserva:400");
});

Deno.test("erro de rede no principal tambem chama o reserva", async () => {
  const { chamar } = chamadaFalsa({
    principal: [{ ms: 2 }],
    reserva: [{ ms: 2, status: 200 }],
  });
  const r = await rodada(MODELOS, chamar, [], 10_000);
  equal(r.http?.corpo, "reserva:200");
});

Deno.test("os dois sobrecarregados: uma rodada a mais", async () => {
  const { chamar, chamados } = chamadaFalsa({
    principal: [{ ms: 1, status: 503 }, { ms: 1, status: 200 }],
    reserva: [{ ms: 1, status: 503 }],
  });
  const tentativas: Tentativa[] = [];
  const r = await consultar(MODELOS, chamar, Date.now() + 10_000, tentativas, {
    paraleloAposMs: 30,
    esperaEntreRodadasMs: 1,
    folgaMinimaMs: 0,
  });
  equal(r.http?.corpo, "principal:200");
  deepStrictEqual(chamados, ["principal", "reserva", "principal"]);
  equal(tentativas.length, 3);
});

Deno.test("falha que nao e passageira nao ganha rodada extra", async () => {
  const { chamar, chamados } = chamadaFalsa({
    principal: [{ ms: 1, status: 404 }],
    reserva: [{ ms: 1, status: 404 }],
  });
  const r = await consultar(MODELOS, chamar, Date.now() + 10_000, [], {
    paraleloAposMs: 30,
    esperaEntreRodadasMs: 1,
    folgaMinimaMs: 0,
  });
  equal(r.http?.status, 404);
  deepStrictEqual(chamados, ["principal", "reserva"]);
});

Deno.test("sem folga no prazo, a rodada extra nao acontece", async () => {
  const { chamar, chamados } = chamadaFalsa({
    principal: [{ ms: 1, status: 503 }],
    reserva: [{ ms: 1, status: 503 }],
  });
  const r = await consultar(MODELOS, chamar, Date.now() + 1_000, [], {
    paraleloAposMs: 30,
    esperaEntreRodadasMs: 1,
    folgaMinimaMs: 8_000,
  });
  equal(r.http?.status, 503);
  deepStrictEqual(chamados, ["principal", "reserva"]);
});

// ── chamarGemini, com `fetch` falso ──────────────────────────────────────────

/** `fetch` falso que despacha pelo modelo da URL. */
function fetchFalso(
  porModelo: Record<string, (sinal: AbortSignal) => Promise<Response>>,
): typeof fetch {
  return ((url: string | URL | Request, init?: RequestInit) => {
    const modelo = /models\/([^:]+):/.exec(String(url))?.[1] ?? "";
    return porModelo[modelo](init?.signal ?? new AbortController().signal);
  }) as typeof fetch;
}

/** Como o `fetch` de verdade: so termina quando o sinal cancela. */
function pendurado(sinal: AbortSignal): Promise<Response> {
  return new Promise((_, falhar) =>
    sinal.addEventListener(
      "abort",
      () => falhar(new DOMException("cancelado", "AbortError")),
      { once: true },
    )
  );
}

Deno.test("o vencedor chega com o corpo inteiro mesmo com o perdedor cancelado", async () => {
  // A regressao de 82e6740: o sinal que cancela o perdedor e o mesmo que vai
  // para o `fetch` do vencedor. Se o corpo fosse lido depois da disputa, o
  // cancelamento cortaria a leitura no meio.
  const reservaEmPartes = (sinal: AbortSignal) => {
    const corpo = new ReadableStream<Uint8Array>({
      async start(controle) {
        const erro = () =>
          controle.error(new DOMException("cancelado", "AbortError"));
        sinal.addEventListener("abort", erro, { once: true });
        controle.enqueue(new TextEncoder().encode('{"parte":'));
        await dormir(20);
        controle.enqueue(new TextEncoder().encode("1}"));
        sinal.removeEventListener("abort", erro);
        controle.close();
      },
    });
    return Promise.resolve(new Response(corpo, { status: 200 }));
  };
  const buscar = fetchFalso({ principal: pendurado, reserva: reservaEmPartes });
  const prazo = Date.now() + 5_000;
  const tentativas: Tentativa[] = [];

  const r = await consultar(
    MODELOS,
    (modelo, cancelar) =>
      chamarGemini(modelo, "{}", "chave", cancelar, prazo, buscar),
    prazo,
    tentativas,
    { paraleloAposMs: 1 },
  );

  equal(r.http?.status, 200);
  equal(r.http?.corpo, '{"parte":1}');
  await dormir(5);
  deepStrictEqual(tentativas.map((t) => [t.modelo, t.status]), [
    ["reserva", 200],
    ["principal", "cancelada"],
  ]);
});

Deno.test("prazo esgotado: as duas chamadas terminam como tempo-esgotado", async () => {
  const buscar = fetchFalso({ principal: pendurado, reserva: pendurado });
  const prazo = Date.now() + 40;
  const tentativas: Tentativa[] = [];

  const r = await consultar(
    MODELOS,
    (modelo, cancelar) =>
      chamarGemini(modelo, "{}", "chave", cancelar, prazo, buscar),
    prazo,
    tentativas,
    { paraleloAposMs: 10, folgaMinimaMs: 0 },
  );

  equal(r.http, undefined);
  deepStrictEqual(tentativas.map((t) => t.status), [
    "tempo-esgotado",
    "tempo-esgotado",
  ]);
});

Deno.test("a chave vai no cabecalho, nunca na URL", async () => {
  let pedido: { url: string; chave: string | null } | undefined;
  const buscar = ((url: string | URL | Request, init?: RequestInit) => {
    pedido = {
      url: String(url),
      chave: new Headers(init?.headers).get("x-goog-api-key"),
    };
    return Promise.resolve(new Response("{}", { status: 200 }));
  }) as typeof fetch;

  await chamarGemini(
    "modelo",
    "{}",
    "segredo",
    new AbortController().signal,
    Date.now() + 1_000,
    buscar,
  );

  equal(pedido?.chave, "segredo");
  ok(!pedido?.url.includes("segredo"));
});
