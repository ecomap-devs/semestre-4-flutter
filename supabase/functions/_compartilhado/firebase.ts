// Quem esta chamando, pelo ID token do Firebase Auth.
//
// As Edge Functions deste projeto atendem gente logada no Firebase, nao no
// Supabase, entao o `verify_jwt` do gateway fica desligado (supabase/config.toml)
// e a conferencia e feita aqui: assinatura pelas chaves publicas do Google,
// emissor e publico do projeto, e validade (o `jose` recusa token vencido).
//
// Pastas que comecam com `_` nao viram funcao no deploy do Supabase: este
// arquivo vai junto, dentro de cada funcao que o importa.
//
// A identificar-animal tem a mesma conferencia escrita dentro dela, de antes
// deste arquivo existir.

import {
  createRemoteJWKSet,
  type JWTPayload,
  jwtVerify,
  type JWTVerifyGetKey,
} from "npm:jose@5";

/** Chaves publicas que assinam os ID tokens do Firebase Auth. */
export const CHAVES_FIREBASE: JWTVerifyGetKey = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

/** O conteudo do ID token, se ele for valido para o projeto; senao, `null`. */
async function conteudoDoToken(
  req: Request,
  projeto: string,
  chaves: JWTVerifyGetKey,
): Promise<JWTPayload | null> {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token || !projeto) return null;
  try {
    const { payload } = await jwtVerify(token, chaves, {
      issuer: `https://securetoken.google.com/${projeto}`,
      audience: projeto,
    });
    return payload;
  } catch {
    return null;
  }
}

/**
 * O uid de quem chama, se o `Authorization: Bearer <ID token>` for valido para
 * o projeto [projeto]; senao, `null`.
 */
export async function uidDoToken(
  req: Request,
  projeto: string,
  chaves: JWTVerifyGetKey = CHAVES_FIREBASE,
): Promise<string | null> {
  const payload = await conteudoDoToken(req, projeto, chaves);
  return typeof payload?.sub === "string" && payload.sub ? payload.sub : null;
}

/** Quem chama e quando digitou a senha pela ultima vez. */
export type Login = {
  uid: string;
  /** O `auth_time` do token, em segundos desde 1970. */
  autenticadoEm: number;
};

/**
 * Como `uidDoToken`, mas com a hora do login (`auth_time`): a hora em que a
 * pessoa digitou a senha. Ela nao muda quando o cliente renova o token sozinho,
 * a cada hora, entao serve para exigir login recente antes de algo sem volta,
 * como apagar a conta. Token sem `auth_time` vale `null`.
 */
export async function loginDoToken(
  req: Request,
  projeto: string,
  chaves: JWTVerifyGetKey = CHAVES_FIREBASE,
): Promise<Login | null> {
  const payload = await conteudoDoToken(req, projeto, chaves);
  const uid = typeof payload?.sub === "string" ? payload.sub : "";
  const autenticadoEm = payload?.auth_time;
  if (!uid || typeof autenticadoEm !== "number") return null;
  return { uid, autenticadoEm };
}
