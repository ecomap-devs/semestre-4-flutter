// Quantas identificacoes cada pessoa pode pedir, contadas no Postgres do
// Supabase (supabase/limite-identificacao.sql).
//
// Sem isto, o login era a unica barreira: com cadastro aberto, uma conta nova
// e um script esgotavam a cota do Gemini, que e uma so para o projeto inteiro.

export type Veredito = "ok" | "limite-minuto" | "limite-dia";

/**
 * Conta o pedido de `uid`, se couber no limite, e diz se pode seguir.
 *
 * Devolve `null` quando nao deu para consultar o banco: quem chama recusa o
 * pedido. Deixar passar protegeria menos a cota justo quando algo esta errado.
 */
export async function registrarUso(
  uid: string,
  limites: { porMinuto: number; porDia: number },
  supabase: { url: string; chaveSecreta: string },
  buscar: typeof fetch = fetch,
): Promise<Veredito | null> {
  const limite = new AbortController();
  const relogio = setTimeout(() => limite.abort(), 5_000);
  try {
    const resposta = await buscar(
      `${supabase.url}/rest/v1/rpc/registrar_identificacao`,
      {
        method: "POST",
        // A chave secreta vai SO no `apikey`: em `Authorization: Bearer` a
        // plataforma tenta le-la como JWT e recusa ("Invalid JWT").
        headers: {
          "Content-Type": "application/json",
          apikey: supabase.chaveSecreta,
        },
        body: JSON.stringify({
          p_uid: uid,
          p_por_minuto: limites.porMinuto,
          p_por_dia: limites.porDia,
        }),
        signal: limite.signal,
      },
    );
    const corpo = await resposta.text();
    if (!resposta.ok) {
      console.error(
        "Limite: o banco respondeu",
        resposta.status,
        corpo.slice(0, 200),
      );
      return null;
    }
    const veredito: unknown = JSON.parse(corpo);
    if (
      veredito === "ok" || veredito === "limite-minuto" ||
      veredito === "limite-dia"
    ) {
      return veredito;
    }
    console.error("Limite: resposta inesperada", corpo.slice(0, 200));
    return null;
  } catch (erro) {
    console.error("Limite: nao deu para consultar o banco", erro);
    return null;
  } finally {
    clearTimeout(relogio);
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
