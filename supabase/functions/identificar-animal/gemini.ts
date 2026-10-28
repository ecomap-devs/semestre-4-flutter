// A consulta ao Gemini: a corrida entre o modelo principal e o reserva, e a
// rodada extra quando os dois estao sobrecarregados.
//
// Mora fora do index.ts para ter teste (gemini_test.ts): a corrida ja quebrou
// uma vez (82e6740), e o defeito so aparecia em producao, com o Google lento.
// Aqui nada le variavel de ambiente nem sobe servidor; quem chama passa a chave,
// os modelos e, nos testes, um `fetch` falso.

// A demora do nivel gratuito e fila, nao modelo: o mesmo flash-lite levou
// 1,8 s num teste e 20 s no seguinte, sem gastar token pensando. Esperar a
// fila andar nao adianta; o que adianta e nao depender de uma fila so. Se o
// principal nao responder em PARALELO_APOS_MS, o reserva e chamado junto, e
// vale a primeira resposta boa — a outra e cancelada. Se o principal falhar
// antes disso (503, por exemplo), o reserva e chamado na hora.
//
// O custo: nos casos lentos, a mesma foto gasta duas consultas da cota; com a
// rodada extra, ate quatro. Por isso o index.ts limita os pedidos por pessoa.
export const PARALELO_APOS_MS = 6_000;

/** Status que valem nova rodada: sobrecarga e erro interno do Google. */
export const PASSAGEIRO = new Set([500, 503]);

/** Quanto cada chamada levou — volta na resposta para diagnosticar demora. */
export type Tentativa = {
  modelo: string;
  status: number | "tempo-esgotado" | "cancelada" | "erro-rede";
  ms: number;
};

/**
 * Uma chamada terminada, com o corpo JA LIDO. Ler aqui dentro, antes da
 * disputa, e de proposito: a primeira versao da corrida devolvia o `Response`
 * e cancelava os perdedores com um sinal compartilhado — que tambem cortava a
 * leitura do corpo do vencedor. A funcao quebrava, a resposta de erro da
 * plataforma vinha sem CORS e o site mostrava "Sem conexao".
 */
export type Resultado = {
  tentativa: Tentativa;
  /** Presente quando o Google respondeu: status HTTP e corpo em texto. */
  http?: { status: number; corpo: string };
};

/** Uma chamada a um modelo, que termina sozinha se `cancelar` disparar. */
export type Chamada = (
  modelo: string,
  cancelar: AbortSignal,
) => Promise<Resultado>;

/**
 * Uma chamada ao Gemini, com o corpo lido ate o fim. Nunca lanca: falha vira
 * status na tentativa.
 */
export async function chamarGemini(
  modelo: string,
  corpo: string,
  chave: string,
  cancelar: AbortSignal,
  prazo: number,
  buscar: typeof fetch = fetch,
): Promise<Resultado> {
  const inicio = Date.now();
  // Um relogio que se desliga no fim, e nao `AbortSignal.timeout`: este fica
  // armado ate disparar, mesmo depois de a chamada terminar.
  const limite = new AbortController();
  const relogio = setTimeout(() => limite.abort(), Math.max(1, prazo - inicio));
  try {
    // A chave vai no cabecalho, nao na URL: URL aparece em log de erro.
    const resposta = await buscar(
      `https://generativelanguage.googleapis.com/v1beta/models/${modelo}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": chave,
        },
        body: corpo,
        signal: AbortSignal.any([cancelar, limite.signal]),
      },
    );
    const texto = await resposta.text();
    return {
      tentativa: { modelo, status: resposta.status, ms: Date.now() - inicio },
      http: { status: resposta.status, corpo: texto },
    };
  } catch {
    const status = cancelar.aborted
      ? "cancelada"
      : limite.signal.aborted
      ? "tempo-esgotado"
      : "erro-rede";
    return { tentativa: { modelo, status, ms: Date.now() - inicio } };
  } finally {
    clearTimeout(relogio);
  }
}

/**
 * Uma rodada: o principal sai na frente, o reserva entra se o principal
 * demorar ou falhar, e vale a primeira resposta boa. Sem resposta boa, devolve
 * a ultima falha (com o corpo, para o log).
 */
export function rodada(
  modelos: { principal: string; reserva: string },
  chamar: Chamada,
  tentativas: Tentativa[],
  paraleloAposMs = PARALELO_APOS_MS,
): Promise<Resultado> {
  const cancelar = new AbortController();
  return new Promise((resolver) => {
    let ativas = 0;
    let reservaChamado = false;
    let terminou = false;

    const encerrar = (r: Resultado) => {
      terminou = true;
      clearTimeout(relogio);
      cancelar.abort();
      resolver(r);
    };

    const disparar = (modelo: string) => {
      ativas++;
      chamar(modelo, cancelar.signal).then((r) => {
        ativas--;
        tentativas.push(r.tentativa);
        if (terminou) return;
        if (r.http && r.http.status >= 200 && r.http.status < 300) {
          return encerrar(r);
        }

        if (!reservaChamado) return chamarReserva();
        if (ativas === 0) encerrar(r);
      });
    };

    const chamarReserva = () => {
      if (reservaChamado || terminou) return;
      reservaChamado = true;
      disparar(modelos.reserva);
    };

    const relogio = setTimeout(chamarReserva, paraleloAposMs);
    disparar(modelos.principal);
  });
}

/**
 * A consulta inteira: uma rodada e, se os dois modelos estiverem
 * sobrecarregados ao mesmo tempo, mais uma, se ainda der tempo. Chave ou modelo
 * errado falharia igual de novo, entao nao repete.
 */
export async function consultar(
  modelos: { principal: string; reserva: string },
  chamar: Chamada,
  prazo: number,
  tentativas: Tentativa[],
  opcoes: {
    paraleloAposMs?: number;
    esperaEntreRodadasMs?: number;
    folgaMinimaMs?: number;
  } = {},
): Promise<Resultado> {
  const {
    paraleloAposMs = PARALELO_APOS_MS,
    esperaEntreRodadasMs = 1_000,
    folgaMinimaMs = 8_000,
  } = opcoes;

  const primeira = await rodada(modelos, chamar, tentativas, paraleloAposMs);
  const http = primeira.http;
  if (
    http && PASSAGEIRO.has(http.status) && prazo - Date.now() > folgaMinimaMs
  ) {
    console.warn("Gemini sobrecarregado nos dois modelos; nova rodada");
    await new Promise((r) => setTimeout(r, esperaEntreRodadasMs));
    return await rodada(modelos, chamar, tentativas, paraleloAposMs);
  }
  return primeira;
}
