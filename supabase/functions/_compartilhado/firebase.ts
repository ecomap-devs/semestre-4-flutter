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
  jwtVerify,
  type JWTVerifyGetKey,
} from "npm:jose@5";

/** Chaves publicas que assinam os ID tokens do Firebase Auth. */
export const CHAVES_FIREBASE: JWTVerifyGetKey = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

/**
 * O uid de quem chama, se o `Authorization: Bearer <ID token>` for valido para
 * o projeto [projeto]; senao, `null`.
 */
export async function uidDoToken(
  req: Request,
  projeto: string,
  chaves: JWTVerifyGetKey = CHAVES_FIREBASE,
): Promise<string | null> {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token || !projeto) return null;
  try {
    const { payload } = await jwtVerify(token, chaves, {
      issuer: `https://securetoken.google.com/${projeto}`,
      audience: projeto,
    });
    return typeof payload.sub === "string" && payload.sub ? payload.sub : null;
  } catch {
    return null;
  }
}
