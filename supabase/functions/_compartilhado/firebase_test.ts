// A conferencia do ID token do Firebase, com chaves geradas aqui: o token e
// assinado como o Google assina, mas sem rede.

import { deepStrictEqual, equal } from "node:assert/strict";

import {
  createLocalJWKSet,
  exportJWK,
  generateKeyPair,
  type JWTPayload,
  type KeyLike,
  SignJWT,
} from "npm:jose@5";

import { loginDoToken, uidDoToken } from "./firebase.ts";

const PROJETO = "projeto-teste";
const { publicKey, privateKey } = await generateKeyPair("RS256");
const CHAVES = createLocalJWKSet({
  keys: [{ ...(await exportJWK(publicKey)), kid: "k1", alg: "RS256" }],
});
const agora = () => Math.floor(Date.now() / 1000);

async function token(
  conteudo: JWTPayload = {},
  opcoes: { projeto?: string; expira?: number; chave?: KeyLike } = {},
) {
  const projeto = opcoes.projeto ?? PROJETO;
  return await new SignJWT({ auth_time: agora() - 10, ...conteudo })
    .setProtectedHeader({ alg: "RS256", kid: "k1" })
    .setIssuer(`https://securetoken.google.com/${projeto}`)
    .setAudience(projeto)
    .setSubject("uid123")
    .setIssuedAt()
    .setExpirationTime(opcoes.expira ?? agora() + 3600)
    .sign(opcoes.chave ?? privateKey);
}

const pedido = (valor?: string) =>
  new Request("https://funcao", {
    method: "POST",
    headers: valor ? { Authorization: `Bearer ${valor}` } : {},
  });

Deno.test("token valido: uid e a hora do login", async () => {
  const autenticadoEm = agora() - 42;
  const req = pedido(await token({ auth_time: autenticadoEm }));
  deepStrictEqual(await loginDoToken(req, PROJETO, CHAVES), {
    uid: "uid123",
    autenticadoEm,
  });
  equal(await uidDoToken(req, PROJETO, CHAVES), "uid123");
});

Deno.test("sem auth_time: loginDoToken recusa, uidDoToken segue aceitando", async () => {
  const req = pedido(await token({ auth_time: undefined }));
  equal(await loginDoToken(req, PROJETO, CHAVES), null);
  equal(await uidDoToken(req, PROJETO, CHAVES), "uid123");
});

Deno.test("token de outro projeto, vencido ou assinado por outra chave: null", async () => {
  const outraChave = (await generateKeyPair("RS256")).privateKey;
  for (
    const valor of [
      await token({}, { projeto: "outro-projeto" }),
      await token({}, { expira: agora() - 60 }),
      await token({}, { chave: outraChave }),
      "nao-e-um-jwt",
    ]
  ) {
    equal(await loginDoToken(pedido(valor), PROJETO, CHAVES), null);
    equal(await uidDoToken(pedido(valor), PROJETO, CHAVES), null);
  }
});

Deno.test("sem Authorization ou sem projeto configurado: null", async () => {
  equal(await loginDoToken(pedido(), PROJETO, CHAVES), null);
  equal(await loginDoToken(pedido(await token()), "", CHAVES), null);
});
